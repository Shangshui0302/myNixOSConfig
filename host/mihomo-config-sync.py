#!/usr/bin/env python3
"""Keep a validated shared snapshot and a locally composed Mihomo config."""

import argparse
import errno
import fcntl
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request

import yaml


SHARED_KEYS = ("proxies", "proxy-groups", "rule-providers", "rules")
BUILTIN_POLICIES = {"DIRECT", "REJECT", "REJECT-DROP", "PASS", "COMPATIBLE", "GLOBAL"}
MAX_BYTES = 10 * 1024 * 1024


def read_yaml(raw):
    value = yaml.safe_load(raw)
    if not isinstance(value, dict):
        raise ValueError("YAML root must be a mapping")
    return value


def valid_name(value):
    return isinstance(value, str) and bool(value.strip()) and value == value.strip()


def filter_names(names, pattern, label):
    if pattern is None:
        return list(names)
    if not isinstance(pattern, str) or not pattern:
        raise ValueError(label + " must be a non-empty regular expression")
    try:
        matcher = re.compile(pattern)
    except re.error as exc:
        raise ValueError("invalid policy group " + label) from exc
    return [name for name in names if matcher.search(name)]


def group_members(proxies, groups):
    """Resolve candidate members without guessing categories from node labels."""
    proxy_names = [item["name"] for item in proxies]
    group_names = {item["name"] for item in groups}
    known = set(proxy_names) | group_names | BUILTIN_POLICIES
    resolved = {}
    edges = {}
    for group in groups:
        name = group["name"]
        explicit = group.get("proxies", [])
        if not isinstance(explicit, list) or any(not valid_name(item) for item in explicit):
            raise ValueError("policy group members are invalid")
        if len(explicit) != len(set(explicit)):
            raise ValueError("policy group members are repeated")
        if any(item not in known for item in explicit):
            raise ValueError("policy group has an unknown member")
        if "use" in group or "include-all" in group or "include-all-providers" in group:
            raise ValueError("unsupported policy group membership source")

        include_all = group.get("include-all-proxies", False)
        if not isinstance(include_all, bool):
            raise ValueError("include-all-proxies must be boolean")
        if ("filter" in group or "exclude-filter" in group) and not include_all:
            raise ValueError("policy group filter requires include-all-proxies")

        derived = []
        if include_all:
            derived = filter_names(proxy_names, group.get("filter"), "filter")
            excluded = set(filter_names(proxy_names, group.get("exclude-filter"), "exclude-filter")) if "exclude-filter" in group else set()
            derived = [item for item in derived if item not in excluded]
        members = list(dict.fromkeys(explicit + derived))
        if not members:
            raise ValueError("policy group has no candidate members")
        resolved[name] = members
        edges[name] = {item for item in explicit if item in group_names}

    visiting = set()
    visited = set()

    def visit(name):
        if name in visiting:
            raise ValueError("policy group reference cycle detected")
        if name in visited:
            return
        visiting.add(name)
        for child in edges[name]:
            visit(child)
        visiting.remove(name)
        visited.add(name)

    for name in edges:
        visit(name)
    return resolved


def split_rule(rule):
    fields = []
    start = 0
    depth = 0
    for index, char in enumerate(rule):
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth < 0:
                raise ValueError("rule parentheses are unbalanced")
        elif char == "," and depth == 0:
            fields.append(rule[start:index].strip())
            start = index + 1
    if depth:
        raise ValueError("rule parentheses are unbalanced")
    fields.append(rule[start:].strip())
    if any(not field for field in fields):
        raise ValueError("rule fields are empty")
    return fields


def validate_rules(rules, providers, policies):
    for rule in rules:
        if not isinstance(rule, str) or not rule.strip():
            raise ValueError("rules are invalid")
        fields = split_rule(rule)
        if len(fields) < 2:
            raise ValueError("rule has no policy target")
        target_index = -2 if fields[-1].lower() == "no-resolve" else -1
        if fields[target_index] not in policies:
            raise ValueError("rule has an unknown policy target")
        if fields[0] == "RULE-SET" and (len(fields) < 3 or fields[1] not in providers):
            raise ValueError("rule references an unknown rule provider")


def shared_fields(raw):
    source = read_yaml(raw)
    if any(key not in source for key in SHARED_KEYS):
        raise ValueError("shared YAML is incomplete")
    proxies, groups, providers, rules = (source[key] for key in SHARED_KEYS)
    if not isinstance(proxies, list) or not proxies or not isinstance(groups, list) or not groups or not isinstance(providers, dict) or not providers or not isinstance(rules, list) or not rules:
        raise ValueError("shared YAML fields must have valid types and be non-empty")

    if any(not isinstance(item, dict) or not valid_name(item.get("type")) for item in proxies):
        raise ValueError("proxies are invalid")
    proxy_names = [item.get("name") for item in proxies]
    if any(not valid_name(name) for name in proxy_names) or len(proxy_names) != len(set(proxy_names)):
        raise ValueError("proxy names are invalid or repeated")
    if set(proxy_names) & BUILTIN_POLICIES:
        raise ValueError("proxy name conflicts with a built-in policy")

    if any(not isinstance(item, dict) or not valid_name(item.get("type")) for item in groups):
        raise ValueError("policy groups are invalid")
    group_names = [item.get("name") for item in groups]
    if any(not valid_name(name) for name in group_names) or len(group_names) != len(set(group_names)):
        raise ValueError("policy group names are invalid or repeated")
    if set(group_names) & (set(proxy_names) | BUILTIN_POLICIES):
        raise ValueError("policy group name conflicts with another policy")

    if any(not valid_name(name) or not isinstance(value, dict) or not valid_name(value.get("type")) for name, value in providers.items()):
        raise ValueError("rule providers are invalid")
    group_members(proxies, groups)
    validate_rules(rules, providers, set(proxy_names) | set(group_names) | BUILTIN_POLICIES)
    return {key: source[key] for key in SHARED_KEYS}


def yaml_bytes(value):
    return yaml.safe_dump(value, allow_unicode=True, sort_keys=False).encode("utf-8")


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def fetch_sub_store(url):
    """Read fresh generated YAML only from the local Sub-Store file endpoint."""
    try:
        parsed = urllib.parse.urlsplit(url)
        name = urllib.parse.unquote(parsed.path.removeprefix("/backend/api/file/"))
        if (
            url != url.strip()
            or any(ord(char) < 33 or ord(char) == 127 for char in url)
            or parsed.scheme != "http"
            or parsed.hostname != "127.0.0.1"
            or parsed.username is not None
            or parsed.password is not None
            or parsed.netloc != "127.0.0.1" + (":" + str(parsed.port) if parsed.port is not None else "")
            or "#" in url
            or not parsed.path.startswith("/backend/api/file/")
            or not name.strip()
            or name in (".", "..")
            or any(char in name for char in "/\\")
            or parsed.query != "noCache=true"
        ):
            raise ValueError
    except (ValueError, TypeError):
        raise ValueError("Sub-Store source must be a local fresh file endpoint") from None

    # An empty ProxyHandler bypasses ALL_PROXY, http_proxy and friends. Refuse
    # every redirect so neither credentials nor requests can leave this endpoint.
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), NoRedirect())
    ready_deadline = time.monotonic() + 10
    while True:
        try:
            with opener.open(url, timeout=90) as response:
                body = response.read(MAX_BYTES + 1)
            break
        except urllib.error.HTTPError as exc:
            exc.close()
            raise RuntimeError("Sub-Store generation request failed") from None
        except urllib.error.URLError as exc:
            # Type=simple can become active before the local HTTP listener is
            # ready. Retry only connection refusal, never a generation failure.
            remaining = ready_deadline - time.monotonic()
            if isinstance(exc.reason, OSError) and exc.reason.errno == errno.ECONNREFUSED and remaining > 0:
                time.sleep(min(0.25, remaining))
                continue
            raise RuntimeError("Sub-Store generation request failed") from None
        except (OSError, TimeoutError):
            raise RuntimeError("Sub-Store generation request failed") from None
    if len(body) > MAX_BYTES:
        raise ValueError("Sub-Store YAML exceeds 10 MiB")
    return body


def compose(template, shared, secret):
    if not secret:
        raise ValueError("MIHOMO_SECRET is empty")
    local = read_yaml(template.read_bytes())
    local["secret"] = secret
    local.pop("proxy-providers", None)
    local.update(shared)
    return yaml_bytes(local)


def atomic_write(path, data):
    with tempfile.NamedTemporaryFile(dir=path.parent, prefix=".candidate-", delete=False) as stream:
        candidate = Path(stream.name)
        os.fchmod(stream.fileno(), 0o600)
        stream.write(data)
        stream.flush()
        os.fsync(stream.fileno())
    try:
        os.replace(candidate, path)
    finally:
        candidate.unlink(missing_ok=True)


def validate(core, state, candidate):
    home = state / "validation-home"
    home.mkdir(mode=0o700, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=state, prefix=".check-", suffix=".yaml", delete=False) as stream:
        path = Path(stream.name)
        os.fchmod(stream.fileno(), 0o600)
        stream.write(candidate)
    try:
        result = subprocess.run([core, "-t", "-d", str(home), "-f", str(path)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=120)
        if result.returncode:
            raise RuntimeError("Mihomo rejected candidate")
    finally:
        path.unlink(missing_ok=True)


def api(controller, method, endpoint, secret, payload=None):
    body = None if payload is None else json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(controller + endpoint, data=body, method=method, headers={
        "Authorization": "Bearer " + secret,
        "Content-Type": "application/json",
    })
    with urllib.request.build_opener(urllib.request.ProxyHandler({})).open(request, timeout=60) as response:
        data = response.read(MAX_BYTES + 1)
        if len(data) > MAX_BYTES:
            raise RuntimeError("controller response too large")
        return response.status, data


def reload_config(controller, candidate, auth_secret):
    status, _ = api(controller, "PUT", "/configs?force=true", auth_secret, {"payload": candidate.decode("utf-8")})
    if status != 204:
        raise RuntimeError("controller did not confirm reload")


def verify_running(controller, shared, auth_secret):
    status, body = api(controller, "GET", "/proxies", auth_secret)
    if status != 200:
        raise RuntimeError("controller proxy inspection failed")
    try:
        proxies = json.loads(body)["proxies"]
    except (KeyError, TypeError, json.JSONDecodeError) as exc:
        raise RuntimeError("controller proxy inspection was invalid") from exc
    if not isinstance(proxies, dict):
        raise RuntimeError("controller proxy inspection was invalid")
    expected = {item["name"] for item in shared["proxies"]}
    if not expected.issubset(proxies):
        raise RuntimeError("running nodes do not match candidate")
    expected_groups = group_members(shared["proxies"], shared["proxy-groups"])
    for group_name, expected_members in expected_groups.items():
        running_group = proxies.get(group_name)
        if not isinstance(running_group, dict) or not isinstance(running_group.get("all"), list):
            raise RuntimeError("running policy group is absent or invalid")
        running_members = running_group["all"]
        if any(not isinstance(item, str) for item in running_members) or len(running_members) != len(set(running_members)) or set(running_members) != set(expected_members):
            raise RuntimeError("running policy group members do not match candidate")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("mode", choices=("seed", "update"))
    p.add_argument("--template", type=Path, required=True)
    p.add_argument("--bootstrap", type=Path, help="optional local shared-config snapshot used only by seed")
    p.add_argument("--state-dir", type=Path, required=True)
    p.add_argument("--mihomo", required=True)
    p.add_argument("--controller", default="http://127.0.0.1:9090")
    p.add_argument("--sub-store-url", help="update source: local Sub-Store file endpoint with ?noCache=true")
    args = p.parse_args()
    if args.mode == "update" and args.sub_store_url is None:
        p.error("update requires --sub-store-url for the local Sub-Store source")

    state = args.state_dir
    state.mkdir(mode=0o700, parents=True, exist_ok=True)
    shared_path = state / "shared-lastgood.yaml"
    active_path = state / "active.yaml"
    with (state / ".sync.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        previous = active_path.read_bytes() if active_path.exists() else None
        previous_shared = shared_path.read_bytes() if shared_path.exists() else None
        try:
            if args.mode == "seed":
                if previous_shared is not None:
                    shared = shared_fields(previous_shared)
                elif args.bootstrap is not None and args.bootstrap.is_file():
                    shared = shared_fields(args.bootstrap.read_bytes())
                else:
                    raise RuntimeError("no shared snapshot available for seed; provide --bootstrap")
            else:
                shared = shared_fields(fetch_sub_store(args.sub_store_url))
            shared_data = yaml_bytes(shared)
            candidate = compose(args.template, shared, os.environ["MIHOMO_SECRET"])
        except Exception:
            if args.mode == "seed" and previous is not None:
                print("Mihomo seed retained existing active config after source failure", file=sys.stderr)
                return
            raise
        if previous == candidate:
            if previous_shared != shared_data:
                atomic_write(shared_path, shared_data)
            print("Mihomo configuration unchanged; reload skipped")
            return
        try:
            validate(args.mihomo, state, candidate)
        except Exception:
            if args.mode == "seed" and previous is not None:
                print("Mihomo seed retained existing active config after validation failure", file=sys.stderr)
                return
            raise
        if args.mode == "seed":
            atomic_write(shared_path, shared_data)
            atomic_write(active_path, candidate)
            print("Mihomo startup config composed from current local template")
            return

        if previous is None:
            raise RuntimeError("running config is absent; seed first")
        old_secret = read_yaml(previous)["secret"]
        new_secret = read_yaml(candidate)["secret"]
        rejected_without_apply = False
        try:
            try:
                reload_config(args.controller, candidate, old_secret)
            except urllib.error.HTTPError as exc:
                if exc.code in (400, 401, 403):
                    rejected_without_apply = True
                raise
            verify_running(args.controller, shared, new_secret)
            atomic_write(shared_path, shared_data)
            atomic_write(active_path, candidate)
        except Exception:
            if not rejected_without_apply:
                try:
                    reload_config(args.controller, previous, new_secret)
                    verify_running(args.controller, shared_fields(previous), old_secret)
                except Exception:
                    try:
                        reload_config(args.controller, previous, old_secret)
                        verify_running(args.controller, shared_fields(previous), old_secret)
                    except Exception as rollback_error:
                        raise RuntimeError("controller rollback could not be verified; active file was retained") from rollback_error
            if previous_shared is not None and shared_path.read_bytes() != previous_shared:
                atomic_write(shared_path, previous_shared)
            if active_path.read_bytes() != previous:
                atomic_write(active_path, previous)
            raise
        print("Mihomo controller reload verified and snapshot published")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        # Parser and HTTP errors can contain URL or proxy credentials.
        print("Mihomo config sync failed (" + type(exc).__name__ + "); previous snapshot retained", file=sys.stderr)
        sys.exit(1)

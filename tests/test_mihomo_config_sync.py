"""Isolated full-source and lifecycle checks; no real subscriptions, controller or secrets."""

from contextlib import contextmanager, redirect_stdout
import importlib.util
import io
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import os
from pathlib import Path
import tempfile
import threading
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location(
    "mihomo_config_sync", Path(__file__).resolve().parents[1] / "host/mihomo-config-sync.py"
)
sync = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(sync)


def shared_fixture(name="synthetic-node"):
    return {
        "tun": {"enable": True, "device": "Meta", "stack": "gvisor", "mtu": 1500},
        "dns": {"enable": True, "enhanced-mode": "fake-ip", "nameserver": ["1.1.1.1"]},
        "mixed-port": 7890,
        "proxies": [{"name": name, "type": "ss", "server": "example.invalid", "port": 443,
                     "cipher": "aes-128-gcm", "password": "synthetic-only"}],
        "proxy-groups": [{"name": "Select", "type": "select", "proxies": [name, "DIRECT"]}],
        "rule-providers": {"example": {"type": "http", "behavior": "domain",
                                      "url": "https://example.invalid/rules"}},
        "rules": ["MATCH,Select"],
    }


@contextmanager
def server(body=b"", status=200, location=None):
    requests = []

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            requests.append(self.path)
            self.send_response(status)
            if location:
                self.send_header("Location", location)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            try:
                self.wfile.write(body)
            except (BrokenPipeError, ConnectionResetError):
                pass

        def log_message(self, *args):
            pass

    httpd = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    thread = threading.Thread(target=httpd.serve_forever, daemon=True)
    thread.start()
    try:
        yield f"http://127.0.0.1:{httpd.server_port}/backend/api/file/test?noCache=true", requests
    finally:
        httpd.shutdown()
        httpd.server_close()
        thread.join()


class LocalSourceTests(unittest.TestCase):
    def test_listener_startup_after_first_connection_refusal(self):
        body = sync.yaml_bytes(shared_fixture())
        requests = []

        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                requests.append(self.path)
                self.send_response(200)
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)

            def log_message(self, *args):
                pass

        # Keep the random port bound but not listening: the first real GET
        # must receive ECONNREFUSED. Activate only when the retry waits.
        httpd = ThreadingHTTPServer(("127.0.0.1", 0), Handler, bind_and_activate=False)
        self.addCleanup(httpd.server_close)
        httpd.server_bind()
        thread = threading.Thread(target=httpd.serve_forever, daemon=True)

        def start_listener(_seconds):
            httpd.server_activate()
            thread.start()

        url = f"http://127.0.0.1:{httpd.server_port}/backend/api/file/test?noCache=true"
        try:
            with patch.object(sync.time, "sleep", side_effect=start_listener) as sleep:
                self.assertEqual(sync.fetch_sub_store(url), body)
                sleep.assert_called_once_with(0.25)
            self.assertEqual(requests, ["/backend/api/file/test?noCache=true"])
        finally:
            if thread.is_alive():
                httpd.shutdown()
                thread.join()

    def test_connection_refusal_wait_is_bounded(self):
        httpd = ThreadingHTTPServer(("127.0.0.1", 0), BaseHTTPRequestHandler, bind_and_activate=False)
        self.addCleanup(httpd.server_close)
        httpd.server_bind()
        url = f"http://127.0.0.1:{httpd.server_port}/backend/api/file/test?noCache=true"
        with patch.object(sync.time, "monotonic", side_effect=[0, 0, 10]), patch.object(sync.time, "sleep") as sleep:
            with self.assertRaises(RuntimeError):
                sync.fetch_sub_store(url)
            sleep.assert_called_once_with(0.25)

    def test_real_http_and_environment_proxy_bypass(self):
        body = sync.yaml_bytes(shared_fixture())
        with server(body) as (url, requests), server(b"proxy must not be used") as (proxy_url, proxy_requests):
            proxy = proxy_url.split("/backend/")[0]
            with patch.dict(os.environ, {
                "http_proxy": proxy, "HTTP_PROXY": proxy,
                "https_proxy": proxy, "HTTPS_PROXY": proxy,
                "all_proxy": proxy, "ALL_PROXY": proxy, "no_proxy": "", "NO_PROXY": "",
            }):
                self.assertEqual(sync.fetch_sub_store(url), body)
            self.assertEqual(requests, ["/backend/api/file/test?noCache=true"])
            self.assertEqual(proxy_requests, [])

    def test_http_error_is_sanitized(self):
        with server(b"sensitive synthetic response", status=500) as (url, requests), patch.object(sync.time, "sleep") as sleep:
            with self.assertRaisesRegex(RuntimeError, "^Sub-Store generation request failed$") as error:
                sync.fetch_sub_store(url)
            self.assertNotIn(url, str(error.exception))
            self.assertEqual(len(requests), 1)
            sleep.assert_not_called()

    def test_redirect_is_never_followed(self):
        # Even another local endpoint must not be followed; external endpoints
        # are excluded by the same HTTPRedirectHandler before any second GET.
        with server(b"redirect destination") as (target, target_requests):
            with server(status=302, location=target) as (url, requests):
                with self.assertRaises(RuntimeError):
                    sync.fetch_sub_store(url)
                self.assertEqual(len(requests), 1)
            self.assertEqual(target_requests, [])

    def test_response_size_limit(self):
        with server(b"x" * (sync.MAX_BYTES + 1)) as (url, _):
            with self.assertRaisesRegex(ValueError, "exceeds 10 MiB"):
                sync.fetch_sub_store(url)

    def test_only_fresh_local_named_file_urls_are_allowed(self):
        invalid = [
            "https://127.0.0.1/backend/api/file/test?noCache=true",
            "http://localhost/backend/api/file/test?noCache=true",
            "http://127.0.0.2/backend/api/file/test?noCache=true",
            "http://example.invalid/backend/api/file/test?noCache=true",
            "http://user:pass@127.0.0.1/backend/api/file/test?noCache=true",
            "http://127.0.0.1:99999/backend/api/file/test?noCache=true",
            "http://127.0.0.1/backend/api/file/?noCache=true",
            "http://127.0.0.1/backend/api/file/%20?noCache=true",
            "http://127.0.0.1/backend/api/file/../test?noCache=true",
            "http://127.0.0.1/backend/api/file/%2e%2e?noCache=true",
            "http://127.0.0.1/backend/api/file/name%2Ftest?noCache=true",
            "http://127.0.0.1/api/file/test?noCache=true",
            "http://127.0.0.1/backend/api/file/test",
            "http://127.0.0.1/backend/api/file/test?noCache=false",
            "http://127.0.0.1/backend/api/file/test?noCache=true&noCache=false",
            "http://127.0.0.1/backend/api/file/test?noCache=true#fragment",
            " http://127.0.0.1/backend/api/file/test?noCache=true",
            "http://127.0.0.1/backend/api/file/te\nst?noCache=true",
        ]
        with patch.object(sync.urllib.request, "build_opener") as opener:
            for url in invalid:
                with self.subTest(url=url), self.assertRaises(ValueError):
                    sync.fetch_sub_store(url)
            opener.assert_not_called()


class StateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.state = self.root / "state"
        self.state.mkdir()
        self.controller = "http://127.0.0.1:9090"
        self.shared = sync.yaml_bytes(shared_fixture())
        self.active = sync.compose(shared_fixture(), "old-synthetic-secret", self.controller)
        (self.state / "shared-lastgood.yaml").write_bytes(self.shared)
        (self.state / "active.yaml").write_bytes(self.active)

    def invoke(self, mode, extra=()):
        argv = ["mihomo-config-sync", mode,
                "--state-dir", str(self.state), "--mihomo", "unused-core", *extra]
        with patch("sys.argv", argv), patch.dict(os.environ, {"MIHOMO_SECRET": "new-synthetic-secret"}), redirect_stdout(io.StringIO()):
            sync.main()

    def test_failed_update_preserves_both_snapshots(self):
        for body, status in [(b"upstream failed", 500), (b"dns: {}\n", 200)]:
            with self.subTest(status=status), server(body, status) as (url, _):
                with patch.object(sync, "validate") as validate, patch.object(sync, "reload_config") as reload:
                    with self.assertRaises((RuntimeError, ValueError)):
                        self.invoke("update", ["--sub-store-url", url])
                    validate.assert_not_called()
                    reload.assert_not_called()
            self.assertEqual((self.state / "active.yaml").read_bytes(), self.active)
            self.assertEqual((self.state / "shared-lastgood.yaml").read_bytes(), self.shared)

    def test_seed_uses_lastgood_without_requesting_sub_store(self):
        with patch.object(sync, "fetch_sub_store") as source, patch.object(sync, "validate") as validate:
            self.invoke("seed")
            source.assert_not_called()
            validate.assert_called_once()
        active = sync.read_yaml((self.state / "active.yaml").read_bytes())
        self.assertEqual(active["proxies"], shared_fixture()["proxies"])
        self.assertEqual(active["secret"], "new-synthetic-secret")

    def test_seed_uses_bootstrap_without_requesting_sub_store(self):
        (self.state / "shared-lastgood.yaml").unlink()
        bootstrap = self.root / "absent-bootstrap"
        bootstrap.write_bytes(self.shared)
        with patch.object(sync, "fetch_sub_store") as source, patch.object(sync, "validate"):
            self.invoke("seed", ["--bootstrap", str(bootstrap)])
            source.assert_not_called()
        (self.state / "shared-lastgood.yaml").unlink()
        (self.state / "active.yaml").unlink()
        bootstrap.unlink()
        with patch.object(sync, "fetch_sub_store") as source:
            with self.assertRaisesRegex(RuntimeError, "no shared snapshot available"):
                self.invoke("seed")
            source.assert_not_called()

    def test_update_consumes_full_source_with_local_management_only(self):
        remote = shared_fixture("fresh-synthetic-node")
        remote["tun"]["mtu"] = 1400
        remote["dns"]["fake-ip-filter"] = ["+.tailscale.com", "+.tailscale.io"]
        remote.update({"secret": "remote-secret", "mixed-port": 7891,
                       "external-controller": "0.0.0.0:9090",
                       "external-controller-tls": "0.0.0.0:9443",
                       "external-controller-unix": "/tmp/remote.sock",
                       "external-controller-pipe": "remote-pipe",
                       "sniffer": {"enable": True}})
        with server(sync.yaml_bytes(remote)) as (url, _), patch.object(sync, "validate") as validate, patch.object(sync, "reload_config") as reload, patch.object(sync, "verify_running") as verify:
            self.invoke("update", ["--sub-store-url", url])
            validate.assert_called_once()
            reload.assert_called_once()
            verify.assert_called_once()
        expected = dict(remote, secret="new-synthetic-secret", **{"external-controller": "127.0.0.1:9090"})
        for key in ("external-controller-tls", "external-controller-unix", "external-controller-pipe"):
            del expected[key]
        self.assertEqual(sync.read_yaml((self.state / "active.yaml").read_bytes()), expected)
        self.assertEqual(sync.read_yaml((self.state / "shared-lastgood.yaml").read_bytes()), remote)
        # A restart must retain the complete source, not just its routing keys.
        with patch.object(sync, "fetch_sub_store") as source, patch.object(sync, "validate"), patch.object(sync, "reload_config") as reload:
            self.invoke("seed")
            source.assert_not_called()
            reload.assert_not_called()
        self.assertEqual(sync.read_yaml((self.state / "active.yaml").read_bytes()), expected)

    def test_incomplete_or_disabled_network_source_is_rejected(self):
        for key in ("tun", "dns"):
            for value in (None, {}, {"enable": False}):
                remote = shared_fixture()
                remote[key] = value
                with self.subTest(key=key, value=value), patch.object(sync, "fetch_sub_store", return_value=sync.yaml_bytes(remote)), patch.object(sync, "reload_config") as reload:
                    with self.assertRaisesRegex(ValueError, "source must include enabled"):
                        self.invoke("update", ["--sub-store-url", "unused"])
                    reload.assert_not_called()
                self.assertEqual((self.state / "active.yaml").read_bytes(), self.active)
                self.assertEqual((self.state / "shared-lastgood.yaml").read_bytes(), self.shared)

    def test_old_routing_only_snapshot_keeps_active_until_update(self):
        old = sync.yaml_bytes({key: shared_fixture()[key] for key in sync.ROUTING_KEYS})
        (self.state / "shared-lastgood.yaml").write_bytes(old)
        with patch.object(sync, "fetch_sub_store") as source, patch.object(sync, "validate") as validate, patch("sys.stderr", new_callable=io.StringIO) as stderr:
            self.invoke("seed")
            source.assert_not_called()
            validate.assert_not_called()
            self.assertIn("retained existing active config", stderr.getvalue())
        self.assertEqual((self.state / "active.yaml").read_bytes(), self.active)
        self.assertEqual((self.state / "shared-lastgood.yaml").read_bytes(), old)
        with patch.object(sync, "fetch_sub_store", return_value=self.shared), patch.object(sync, "validate"), patch.object(sync, "reload_config"), patch.object(sync, "verify_running"):
            self.invoke("update", ["--sub-store-url", "unused"])
        self.assertEqual((self.state / "shared-lastgood.yaml").read_bytes(), self.shared)
        self.assertEqual(sync.read_yaml((self.state / "active.yaml").read_bytes())["dns"], shared_fixture()["dns"])

    def test_failed_verification_rolls_back_full_config_and_snapshot(self):
        remote = shared_fixture("fresh-synthetic-node")
        remote["dns"]["nameserver"] = ["8.8.8.8"]
        with patch.object(sync, "fetch_sub_store", return_value=sync.yaml_bytes(remote)), patch.object(sync, "validate"), patch.object(sync, "reload_config") as reload, patch.object(sync, "verify_running", side_effect=[RuntimeError("verification failed"), None]):
            with self.assertRaisesRegex(RuntimeError, "verification failed"):
                self.invoke("update", ["--sub-store-url", "unused"])
            self.assertEqual(reload.call_count, 2)
            self.assertEqual(reload.call_args.args, (self.controller, self.active, "new-synthetic-secret"))
        self.assertEqual((self.state / "active.yaml").read_bytes(), self.active)
        self.assertEqual((self.state / "shared-lastgood.yaml").read_bytes(), self.shared)

    def test_update_without_local_source_fails_before_snapshot_changes(self):
        with patch("sys.stderr", new_callable=io.StringIO) as stderr, patch.object(sync, "fetch_sub_store") as source:
            with self.assertRaises(SystemExit) as error:
                self.invoke("update")
            self.assertEqual(error.exception.code, 2)
            self.assertIn("update requires --sub-store-url", stderr.getvalue())
            source.assert_not_called()
        self.assertEqual((self.state / "active.yaml").read_bytes(), self.active)
        self.assertEqual((self.state / "shared-lastgood.yaml").read_bytes(), self.shared)


if __name__ == "__main__":
    unittest.main()

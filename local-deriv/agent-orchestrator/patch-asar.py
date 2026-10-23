"""Fix AO 0.14.5's configured daemon cwd without changing other bundle files."""

import hashlib
import json
from pathlib import Path
import struct
import sys


archive = Path(sys.argv[1])
raw = archive.read_bytes()
header_size = struct.unpack_from("<I", raw, 4)[0]
json_size = struct.unpack_from("<I", raw, 12)[0]
header = json.loads(raw[16 : 16 + json_size])


def collect(tree, prefix=""):
    for name, entry in tree["files"].items():
        path = prefix + name
        if "files" in entry:
            yield from collect(entry, path + "/")
        elif "offset" in entry:
            start = 8 + header_size + int(entry["offset"])
            yield path, entry, raw[start : start + entry["size"]]


entries = sorted(collect(header), key=lambda item: int(item[1]["offset"]))
contents = {path: data for path, _, data in entries}
assert json.loads(contents["package.json"])["version"] == "0.14.5", "Recheck AO version before patching"

# v0.14.5 resolveDaemonLaunch(env, isPackaged, resourcesPath, appPath, homeDir,
# platform). appPath is app.asar in packaged builds, which is not a directory.
# Use homeDir only for a packaged configured command; retain dev's appPath.
before = (
    "function ru(e,t,n,r,i,a){let o=e.AO_DAEMON_COMMAND?.trim();return o?"
    "{command:o,args:[],cwd:r,shell:!0,source:`configured`}:t?"
)
after = before.replace("cwd:r", "cwd:t?i:r")
main_path = ".vite/build/main.js"
main = contents[main_path].decode("utf-8")
assert main.count(before) == 1, "Configured daemon launch anchor changed or is ambiguous"
contents[main_path] = main.replace(before, after).encode("utf-8")


def integrity(data, block_size):
    return {
        "algorithm": "SHA256",
        "hash": hashlib.sha256(data).hexdigest(),
        "blockSize": block_size,
        "blocks": [
            hashlib.sha256(data[i : i + block_size]).hexdigest()
            for i in range(0, max(1, len(data)), block_size)
        ],
    }


payload = bytearray()
for path, entry, _ in entries:
    data = contents[path]
    entry["offset"] = str(len(payload))
    entry["size"] = len(data)
    if path == main_path:
        entry["integrity"] = integrity(data, entry["integrity"]["blockSize"])
    payload.extend(data)

encoded = json.dumps(header, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
padding = b"\0" * (-(4 + len(encoded)) % 4)
header_pickle = struct.pack("<II", 4 + len(encoded) + len(padding), len(encoded)) + encoded + padding
archive.write_bytes(struct.pack("<II", 4, len(header_pickle)) + header_pickle + payload)

# Read the final archive independently: verify every packed payload, plus every
# existing file's integrity record. Unpacked files and links retain metadata.
check = archive.read_bytes()
check_header_size = struct.unpack_from("<I", check, 4)[0]
check_json_size = struct.unpack_from("<I", check, 12)[0]
check_header = json.loads(check[16 : 16 + check_json_size])


def lookup(path):
    result = check_header
    for part in path.split("/"):
        result = result["files"][part]
    return result


for path, _, _ in entries:
    entry = lookup(path)
    start = 8 + check_header_size + int(entry["offset"])
    data = check[start : start + entry["size"]]
    assert data == contents[path], ("Payload changed", path)
    if "integrity" in entry:
        assert entry["integrity"] == integrity(data, entry["integrity"]["blockSize"]), path

assert contents[main_path].count(after.encode()) == 1
print("Patched AO 0.14.5 packaged configured-daemon cwd; verified ASAR payloads and integrity")

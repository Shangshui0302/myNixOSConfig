"""Apply version-specific Nix startup policy, updating ASAR integrity metadata."""
import hashlib
import json
from pathlib import Path
import struct
import sys

root = Path(sys.argv[1])
archive = root / 'app.asar'
raw = archive.read_bytes()
header_size = struct.unpack_from('<I', raw, 4)[0]
json_size = struct.unpack_from('<I', raw, 12)[0]
header = json.loads(raw[16:16 + json_size])

def node(path):
    result = header
    for part in path.split('/'):
        result = result['files'][part]
    return result

def integrity(data):
    block_size = 4194304
    return {'algorithm': 'SHA256', 'hash': hashlib.sha256(data).hexdigest(),
            'blockSize': block_size,
            'blocks': [hashlib.sha256(data[i:i + block_size]).hexdigest()
                       for i in range(0, len(data), block_size)]}

def patch(path, replacements):
    entry = node(path)
    unpacked = root / 'app.asar.unpacked' / path
    data = unpacked.read_bytes() if entry.get('unpacked') else raw[
        8 + header_size + int(entry['offset']):
        8 + header_size + int(entry['offset']) + entry['size']]
    text = data.decode()
    for before, after in replacements:
        assert text.count(before) == 1, (path, before, text.count(before))
        text = text.replace(before, after)
    result = text.encode()
    entry['size'] = len(result)
    entry['integrity'] = integrity(result)
    if entry.get('unpacked'):
        unpacked.write_bytes(result)
    return result

main_path = 'out/main/index.js'
main = patch(main_path, [
    ('isEligible:()=>$.codexRuntimeHome?.isHostSystemDefaultSessionMigrationEligible()===!0',
     'isEligible:()=>!1'),
    ('XD(Ze.r()),$.codexSessionMigration.scheduleInitialRun()',
     '$.codexSessionMigration.scheduleInitialRun()'),
    ('setupAutoUpdater(e,t){this.mainWindowRef=',
     'setupAutoUpdater(e,t){return;this.mainWindowRef=')
])
patch('out/main/chunks/constants-C27K8uiD.js', [
    ('sourceControlAi:Y(),voice:e.voice}}',
     'sourceControlAi:Y(),voice:e.voice,...require("../../../../nix-default-settings.json")}}')
])

entries = []
def collect(tree):
    for value in tree.get('files', {}).values():
        if 'files' in value:
            collect(value)
        elif 'offset' in value:
            entries.append(value)
collect(header)
# Preserve original payload order; only the main bundle changes length.
entries.sort(key=lambda entry: int(entry['offset']))
main_entry = node(main_path)
payload = bytearray()
for entry in entries:
    offset = 8 + header_size + int(entry['offset'])
    data = main if entry is main_entry else raw[offset:offset + entry['size']]
    entry['offset'] = str(len(payload))
    payload.extend(data)
encoded = json.dumps(header, separators=(',', ':'), ensure_ascii=False).encode()
padding = b'\0' * (-(4 + len(encoded)) % 4)
header_pickle = struct.pack('<II', 4 + len(encoded) + len(padding), len(encoded)) + encoded + padding
archive.write_bytes(struct.pack('<II', 4, len(header_pickle)) + header_pickle + payload)
# Re-read and check changed bytes and metadata without starting Electron.
check = archive.read_bytes()
new_header_size = struct.unpack_from('<I', check, 4)[0]
entry = node(main_path)
offset = 8 + new_header_size + int(entry['offset'])
assert check[offset:offset + entry['size']] == main
assert entry['integrity'] == integrity(main)
print('Applied default settings, migration scheduler/recovery guard, and Nix updater policy')

"""Select the main desktop's ClassicUI theme; leave input preferences to the user."""
import os
from pathlib import Path
import re
import stat
import sys
import tempfile


def select(path, theme):
    values = {b'Theme': theme.encode('ascii'), b'DarkTheme': b'mellow-matugen-dark',
              b'UseDarkTheme': b'True'}
    try:
        mode = path.lstat().st_mode
    except FileNotFoundError:
        source, mode = b'', 0o600
        values[b'Vertical Candidate List'] = b'True'
    else:
        if not stat.S_ISREG(mode):
            print('theme-apply: skipping non-regular classicui.conf', file=sys.stderr)
            return False
        source = path.read_bytes()

    # Only keys before the first section belong to the global ClassicUI config.
    # Keep unrelated lines as bytes, including comments, CRLF and the final newline.
    section = re.search(rb'(?m)^[ \t]*\[', source)
    end = section.start() if section else len(source)
    newline = b'\r\n' if b'\r\n' in source else b'\n'
    root = []
    found = set()
    for line in source[:end].splitlines(keepends=True):
        name, eq, value = line.partition(b'=')
        key = name.strip()
        if eq and key in values:
            found.add(key)
            if value.strip() != values[key]:
                line = name + eq + values[key] + value[len(value.rstrip(b'\r\n')):]
        root.append(line)
    missing = [k + b'=' + v + newline for k, v in values.items() if k not in found]
    if missing and root and not root[-1].endswith(b'\n'):
        root.append(newline)
    candidate = b''.join(root + missing) + source[end:]
    if candidate == source:
        return False

    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = tempfile.NamedTemporaryFile(dir=path.parent, prefix='.classicui.conf.', delete=False)
    try:
        with tmp:
            tmp.write(candidate)
            os.fchmod(tmp.fileno(), stat.S_IMODE(mode))
        os.replace(tmp.name, path)
    finally:
        Path(tmp.name).unlink(missing_ok=True)
    return True


if __name__ == '__main__':
    # The caller uses this flag to decide whether to request a reload.
    print(int(select(Path(sys.argv[1]), sys.argv[2])))

"""Select the Matugen theme without rewriting unrelated Strata preferences."""
import os
from pathlib import Path
import stat
import sys
import tempfile
import tomllib

import tomlkit


SELECTION = {"theme": "matugen", "mode": "theme"}


def values(text):
    # Compare float tokens exactly (including nan, which isn't equal to itself).
    return tomllib.loads(text, parse_float=lambda token: ("float", token))


def select(path):
    try:
        mode = path.lstat().st_mode
    except FileNotFoundError:
        mode, source = 0o600, ""
    else:
        if not stat.S_ISREG(mode):
            raise ValueError("not a regular settings file")
        source = path.read_bytes().decode("utf-8")

    original = values(source)
    expected = original | SELECTION
    if original == expected:
        return False
    document = tomlkit.parse(source)
    for key, value in SELECTION.items():
        if key in original and not isinstance(original[key], str):
            raise ValueError(f"refusing to replace non-string {key}")
        if original.get(key) != value:
            document[key] = value
    candidate = document.as_string()
    if values(candidate) != expected:
        raise ValueError("candidate changes unrelated settings")

    temporary = tempfile.NamedTemporaryFile(dir=path.parent, prefix=".settings.toml.", delete=False)
    try:
        with temporary:
            temporary.write(candidate.encode("utf-8"))
            os.fchmod(temporary.fileno(), stat.S_IMODE(mode))
        os.replace(temporary.name, path)
    finally:
        Path(temporary.name).unlink(missing_ok=True)
    return True


if __name__ == "__main__":
    try:
        if select(Path(sys.argv[1])):
            print("theme-apply: stage=strata status=theme-selected", file=sys.stderr)
    except (OSError, ValueError, tomlkit.exceptions.TOMLKitError) as exc:
        sys.exit(f"Strata settings: {exc}")

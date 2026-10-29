"""Seed NextKDE spatial wallpaper resources once, before its shell starts."""

import argparse
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile


MODEL_NAMES = (
    "depth-anything-v2-small-vits.onnx",
    "isnet-general-use.onnx",
)


def reject_json_constant(value):
    raise ValueError(f"invalid JSON constant: {value}")


def atomic_write(path, content):
    """Publish a complete file in the destination filesystem."""
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def bootstrap(models):
    home = Path(os.environ["HOME"])
    cache = Path(os.environ.get("XDG_CACHE_HOME") or home / ".cache")
    state = Path(os.environ.get("XDG_STATE_HOME") or home / ".local/state")
    appearance = state / "quickshell/kos/appearance"
    marker = appearance / ".spatial-bootstrap-v1"
    if marker.exists():
        return

    config = appearance / "config.json"
    original = config.read_bytes() if config.exists() else None
    try:
        settings = (
            json.loads(original, parse_constant=reject_json_constant)
            if original is not None else {}
        )
    except (ValueError, UnicodeError) as error:
        raise ValueError(f"cannot parse {config}: {error}") from error
    if not isinstance(settings, dict):
        raise ValueError(f"{config} must contain a JSON object")
    for name in MODEL_NAMES:
        if not (models / name).is_file():
            raise ValueError(f"missing spatial model: {models / name}")

    appearance.mkdir(parents=True, exist_ok=True)
    if original is not None:
        backup = appearance / "config.json.before-spatial-bootstrap"
        try:
            with backup.open("xb") as stream:
                stream.write(original)
        except FileExistsError:
            pass

    destination = cache / "liquid-shell/models"
    destination.mkdir(parents=True, exist_ok=True)
    for name in MODEL_NAMES:
        # Copy instead of linking so KOS can clear its cache normally. A
        # temporary file also avoids exposing partial bytes to the worker.
        temporary = None
        try:
            with tempfile.NamedTemporaryFile(dir=destination, delete=False) as stream:
                temporary = Path(stream.name)
                with (models / name).open("rb") as source:
                    shutil.copyfileobj(source, stream)
                stream.flush()
                os.fsync(stream.fileno())
            temporary.chmod(0o644)
            os.replace(temporary, destination / name)
        finally:
            if temporary is not None:
                temporary.unlink(missing_ok=True)

    # Preserve every existing appearance field, including user-selected style.
    settings["spatialServiceEnabled"] = True
    settings["spatialWallpaperEnabled"] = True
    atomic_write(
        config,
        (json.dumps(settings, ensure_ascii=False, indent=2, allow_nan=False) + "\n").encode(),
    )
    # Later logins leave user changes and deliberately cleared caches alone.
    atomic_write(marker, b"1\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("models", type=Path, help="directory of pinned spatial models")
    args = parser.parse_args()
    try:
        bootstrap(args.models)
    except (OSError, ValueError, KeyError) as error:
        print(f"NextKDE spatial bootstrap failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

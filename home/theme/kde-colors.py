#!/usr/bin/env python3
"""Synchronize application palettes once from KDE's effective configuration."""

import argparse
import configparser
import contextlib
import fcntl
import hashlib
import json
import logging
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import tempfile
import time

LOG = logging.getLogger("kde-colors")
MODES = ("light", "dark")


def color_rgb(value):
    if not isinstance(value, str):
        return None
    value = value.strip()
    if re.fullmatch(r"#[0-9a-fA-F]{6}", value):
        return tuple(int(value[index:index + 2], 16) for index in (1, 3, 5))
    if re.fullmatch(r"\d+\s*,\s*\d+\s*,\s*\d+", value):
        channels = tuple(int(channel) for channel in value.split(","))
        if all(0 <= channel <= 255 for channel in channels):
            return channels
    return None


def read_appearance(path):
    config = configparser.ConfigParser(interpolation=None, strict=False)
    config.optionxform = str
    with Path(path).open(encoding="utf-8") as stream:
        config.read_file(stream)
    # The portal exposes Selection.BackgroundNormal, which KDE may tint or
    # lighten. Use the wallpaper's original AccentColor before that adjustment.
    accent = config.get("General", "AccentColor", fallback="").strip()
    if not accent:
        # "Accent from color scheme" has no custom/wallpaper AccentColor.
        accent = config.get("Colors:Selection", "BackgroundNormal", fallback="")
    seed = color_rgb(accent)
    background = color_rgb(config.get("Colors:Window", "BackgroundNormal", fallback=""))
    if background is None:
        background = color_rgb(config.get("Colors:View", "BackgroundNormal", fallback=""))
    if seed is None or background is None:
        raise ValueError("KDE accent or window background is not available yet")
    # Follow the effective palette, including user-created color-scheme names.
    mode = "dark" if sum(channel * weight for channel, weight in
                         zip(background, (299, 587, 114))) < 128000 else "light"
    return "#" + "".join(f"{channel:02x}" for channel in seed), mode


def update_fcitx_text(text, mode):
    """Change only root keys, retaining user keys, comments and all sections."""
    values = {"Theme": "mellow-kde" + ("-dark" if mode == "dark" else ""),
              "DarkTheme": "mellow-kde-dark", "UseDarkTheme": "True"}
    lines = text.splitlines(keepends=True)
    boundary = next((index for index, line in enumerate(lines)
                     if line.lstrip().startswith("[")), len(lines))
    found = set()
    for index in range(boundary):
        match = re.match(r"\s*(Theme|DarkTheme|UseDarkTheme)\s*=", lines[index])
        if match:
            key = match.group(1)
            lines[index] = f"{key}={values[key]}\n"
            found.add(key)
    additions = [f"{key}={value}\n" for key, value in values.items() if key not in found]
    if additions and boundary and not lines[boundary - 1].endswith("\n"):
        lines[boundary - 1] += "\n"
    return "".join(lines[:boundary] + additions + lines[boundary:])


def atomic_text(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        if path.exists():
            os.fchmod(descriptor, stat.S_IMODE(path.stat().st_mode) | stat.S_IWUSR)
        with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
            stream.write(content)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def atomic_link(path, target):
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    os.close(descriptor)
    os.unlink(temporary)
    try:
        os.symlink(target, temporary)
        os.replace(temporary, path)
    finally:
        if os.path.lexists(temporary):
            os.unlink(temporary)


class Renderer:
    def __init__(self, manifest):
        self.manifest = manifest
        self.root = Path(manifest["cacheRoot"])
        if not self.root.is_absolute():
            raise ValueError("cacheRoot must be absolute")
        self.templates = manifest["templates"]
        outputs = set()
        for template in self.templates:
            output = Path(template["output"])
            if (output.is_absolute() or ".." in output.parts or len(output.parts) < 2
                    or output.parts[0] not in MODES or output.as_posix() in outputs):
                raise ValueError(f"unsafe or duplicate template output: {output}")
            if not Path(template["input"]).is_absolute():
                raise ValueError("template input must be absolute")
            outputs.add(output.as_posix())
        for field in ("matugen", "fcitxConfig", "fcitxReload", "btopReload"):
            if manifest.get(field) and not Path(manifest[field]).is_absolute():
                raise ValueError(f"{field} must be absolute")
        for mode in MODES:
            if not Path(manifest["fcitxAssets"][mode]).is_absolute():
                raise ValueError("fcitxAssets paths must be absolute")

    def previous(self):
        try:
            metadata = json.loads((self.root / "current" / ".metadata.json").read_text())
        except (OSError, ValueError):
            metadata = {}
        mode = None
        with contextlib.suppress(OSError):
            selected = os.readlink(self.root / "selected")
            if selected in ("current/light", "current/dark"):
                mode = selected.split("/")[-1]
        return metadata, mode

    def signature(self, seed):
        # Nix store paths are immutable. Contents also cover temporary test inputs.
        digest = hashlib.sha256()
        digest.update(json.dumps({"seed": seed, "templates": self.templates,
                                  "assets": self.manifest["fcitxAssets"],
                                  "matugen": self.manifest["matugen"], "format": 1},
                                 sort_keys=True).encode())
        for template in self.templates:
            digest.update(Path(template["input"]).read_bytes())
        return digest.hexdigest()

    def render(self, seed, signature):
        stage = Path(tempfile.mkdtemp(prefix="generation-", dir=self.root))
        try:
            for mode in MODES:
                assets = stage / mode / "fcitx5"
                shutil.copytree(self.manifest["fcitxAssets"][mode], assets)
                # Store assets are read-only; copy files rather than preserve symlinks.
                for item in [assets, *assets.rglob("*")]:
                    item.chmod(item.stat().st_mode | stat.S_IWUSR)
                entries = ["[config]\n"]
                for index, template in enumerate(self.templates):
                    if Path(template["output"]).parts[0] != mode:
                        continue
                    destination = stage / template["output"]
                    destination.parent.mkdir(parents=True, exist_ok=True)
                    entries.append(f"[templates.t{index}]\ninput_path = "
                                   f"{json.dumps(template['input'])}\noutput_path = "
                                   f"{json.dumps(str(destination))}\n")
                configuration = stage / f".{mode}.toml"
                configuration.write_text("\n".join(entries))
                subprocess.run([self.manifest["matugen"], "color", "hex", seed,
                                "-m", mode, "-t", "scheme-content", "-c", str(configuration)],
                               check=True, timeout=120, stdout=subprocess.DEVNULL)
                configuration.unlink()
                theme = assets / "theme.conf"
                theme_text = theme.read_text()
                name = "Mellow KDE" + (" Dark" if mode == "dark" else "")
                theme.write_text(re.sub(r"(?m)^Name=.*$", f"Name={name}", theme_text))
            for template in self.templates:
                destination = stage / template["output"]
                if not destination.is_file() or not destination.stat().st_size:
                    raise ValueError(f"missing or empty rendered output: {destination}")
            (stage / ".metadata.json").write_text(json.dumps({"seed": seed, "signature": signature}))
            return stage
        except BaseException:
            shutil.rmtree(stage)
            raise

    def notify(self, field, arguments):
        command = self.manifest.get(field)
        if command:
            try:
                subprocess.run([command, *arguments], check=True, timeout=10,
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except (OSError, subprocess.SubprocessError) as error:
                LOG.debug("%s notification skipped: %s", field, error)

    def apply(self, seed, mode):
        if not re.fullmatch(r"#[0-9a-f]{6}", seed) or mode not in MODES:
            raise ValueError("invalid normalized appearance")
        self.root.mkdir(parents=True, exist_ok=True)
        with (self.root / ".lock").open("a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            previous, old_mode = self.previous()
            signature = self.signature(seed)
            changed = previous.get("signature") != signature
            if changed:
                generation = self.render(seed, signature)
                atomic_link(self.root / "current", generation.name)
            if changed or mode != old_mode:
                atomic_link(self.root / "selected", f"current/{mode}")
            config_changed = False
            config = self.manifest.get("fcitxConfig")
            if config:
                path = Path(config)
                old_text = path.read_text() if path.exists() else ""
                new_text = update_fcitx_text(old_text, mode)
                if new_text != old_text:
                    atomic_text(path, new_text)
                    config_changed = True
            if changed or config_changed or mode != old_mode:
                self.notify("fcitxReload", ["-r"])
            if previous.get("seed") != seed:
                self.notify("btopReload", ["-USR2", "-x", "btop"])
            if changed:
                current = (self.root / "current").resolve()
                for obsolete in self.root.glob("generation-*"):
                    if obsolete != current and obsolete.is_dir() and not obsolete.is_symlink():
                        shutil.rmtree(obsolete)
            return changed or mode != old_mode or config_changed


def synchronize(manifest):
    seed, mode = read_appearance(manifest["kdeGlobals"])
    return Renderer(manifest).apply(seed, mode)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True, type=Path)
    arguments = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(name)s: %(levelname)s: %(message)s")
    try:
        # Let consecutive KConfig saves settle; no process remains after syncing.
        time.sleep(0.25)
        synchronize(json.loads(arguments.manifest.read_text()))
    except Exception:
        LOG.exception("synchronization failed; retaining published palette")
        raise SystemExit(1)


if __name__ == "__main__":
    main()

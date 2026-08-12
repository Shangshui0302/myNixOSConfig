#!/usr/bin/env python3
"""Recolor gnome-shell.css hardcoded hex values to Matugen-generated palette.

GNOME Shell 主题的配色是硬编码 hex（与 gtk-3.0/colors.css 的 @define-color 一致）。
用 old_colors -> new_colors 的 token 映射，把 shell CSS 里的旧 hex 批量替换为新 hex。
用法: recolor-shell.py <old_colors.css> <new_colors.css> <gnome-shell.css>
"""
import re
import sys

HEX = re.compile(r"@define-color\s+(\w+)\s+(#[0-9a-fA-F]{6})")


def parse_colors(path):
    m = {}
    with open(path) as f:
        for line in f:
            r = HEX.match(line)
            if r:
                m[r.group(1)] = r.group(2).lower()
    return m


def main():
    old_path, new_path, shell_path = sys.argv[1:4]
    old = parse_colors(old_path)
    new = parse_colors(new_path)
    # old_hex -> new_hex；同一旧 hex 对应多个 token 时（如 surface/surface_dim 同色），
    # 冲突值相近、取第一个即可，效果近似。
    mapping = {}
    for tok, oh in old.items():
        if oh not in mapping and tok in new:
            mapping[oh] = new[tok].lower()
    css = open(shell_path).read()
    for oh, nh in mapping.items():
        css = css.replace(oh, nh)
    open(shell_path, "w").write(css)
    print(f"recolored shell: {len(mapping)} hex mappings applied")


if __name__ == "__main__":
    main()

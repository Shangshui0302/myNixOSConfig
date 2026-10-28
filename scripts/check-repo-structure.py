#!/usr/bin/env python3
"""Check the wiki source map against the repository structure (read-only)."""

import argparse
import sys
from pathlib import Path

import yaml


class UniqueKeyLoader(yaml.SafeLoader):
    """Safe YAML loader that rejects duplicate mapping keys."""


def construct_mapping(loader, node, deep=False):
    loader.flatten_mapping(node)
    mapping = {}
    for key_node, value_node in node.value:
        key = loader.construct_object(key_node, deep=deep)
        try:
            duplicate = key in mapping
        except TypeError as exc:
            raise yaml.constructor.ConstructorError(
                "while constructing a mapping", node.start_mark,
                "unhashable key", key_node.start_mark,
            ) from exc
        if duplicate:
            raise yaml.constructor.ConstructorError(
                "while constructing a mapping", node.start_mark,
                f"duplicate key {key!r}", key_node.start_mark,
            )
        mapping[key] = loader.construct_object(value_node, deep=deep)
    return mapping


UniqueKeyLoader.add_constructor(
    yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, construct_mapping
)


def relative_path(value):
    """Accept a nonempty relative path confined to its root."""
    if not isinstance(value, str) or not value:
        return False
    path = Path(value)
    return not path.is_absolute() and ".." not in path.parts and value != "."


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--memory-root", type=Path, help="local memory directory containing cards/")
    args = parser.parse_args()
    root = args.root.resolve()
    map_path = root / "wiki" / "_sources.yaml"
    try:
        with map_path.open(encoding="utf-8") as stream:
            data = yaml.load(stream, Loader=UniqueKeyLoader)
    except (OSError, UnicodeError, yaml.YAMLError) as exc:
        print(f"error: {map_path}: {exc}", file=sys.stderr)
        return 1
    if not isinstance(data, dict) or not isinstance(data.get("docs"), dict):
        print(f"error: {map_path}: docs must be a mapping", file=sys.stderr)
        return 1

    errors = []
    docs = data["docs"]
    sources = []
    memory_root = args.memory_root if args.memory_root is not None else root / "memory"
    cards = memory_root / "cards"
    check_memory = args.memory_root is not None or cards.is_dir()
    if check_memory and not cards.is_dir():
        errors.append(f"memory cards directory does not exist: {cards}")
    elif not check_memory:
        print(f"memory check skipped: {cards} is not available")

    for doc, entry in docs.items():
        if not relative_path(doc) or not doc.endswith(".md"):
            errors.append(f"invalid wiki document path: {doc!r}")
            continue
        if not (root / "wiki" / doc).is_file():
            errors.append(f"{doc}: wiki document does not exist")
        if not isinstance(entry, dict):
            errors.append(f"{doc}: entry must be a mapping")
            continue
        for field in ("sources", "memory"):
            values = entry.get(field)
            if not isinstance(values, list) or not all(isinstance(v, str) for v in values):
                errors.append(f"{doc}: {field} must be a list of strings")
                continue
            for value in values:
                if field == "sources":
                    if not relative_path(value):
                        errors.append(f"{doc}: invalid source path {value!r}")
                    elif not (root / value).exists():
                        errors.append(f"{doc}: source does not exist: {value}")
                    else:
                        sources.append(root / value)
                else:
                    if not value or value in (".", "..") or Path(value).name != value:
                        errors.append(f"{doc}: invalid memory slug {value!r}")
                    elif check_memory and not (cards / f"{value}.md").is_file():
                        errors.append(f"{doc}: memory card does not exist: {cards / (value + '.md')}")

    wiki_docs = sorted((root / "wiki").rglob("*.md"))
    for doc in wiki_docs:
        relative = doc.relative_to(root / "wiki").as_posix()
        if relative not in docs:
            errors.append(f"wiki/{relative}: missing docs mapping")

    modules = sorted(path for tree in ("home", "host") for path in (root / tree).rglob("*.nix"))
    for module in modules:
        if not any(module == source or (source.is_dir() and source in module.parents) for source in sources):
            errors.append(f"{module.relative_to(root)}: not covered by any sources entry")

    if errors:
        for error in errors:
            print(f"error: {error}", file=sys.stderr)
        return 1
    print(f"structure OK: {len(wiki_docs)} wiki documents, {len(modules)} Nix modules")
    return 0


if __name__ == "__main__":
    sys.exit(main())

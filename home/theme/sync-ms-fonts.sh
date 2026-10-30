#!/usr/bin/env bash
# Synchronize flattened font files without touching existing fonts on missing input.
set -euo pipefail

source_dir=$1
target_dir=$2
fc_cache=$3

if [[ ! -d "$source_dir" ]]; then
  echo "MS font source is unavailable: $source_dir; keeping existing fonts" >&2
  exit 0
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir "$work/fonts"
# Collect first so a find error cannot be mistaken for an empty source.
find "$source_dir" -type f \( -iname '*.ttf' -o -iname '*.ttc' \) -print0 > "$work/files"
sort -z "$work/files" -o "$work/files"
if [[ ! -s "$work/files" ]]; then
  echo "MS font source contains no fonts: $source_dir; keeping existing fonts" >&2
  exit 0
fi

while IFS= read -r -d '' font; do
  name=${font##*/}
  if [[ -e "$work/fonts/$name" || -L "$work/fonts/$name" ]]; then
    echo "Duplicate MS font filename: $name; keeping existing fonts" >&2
    exit 1
  fi
  ln -s "$(realpath -- "$font")" "$work/fonts/$name"
done < "$work/files"

mkdir -p "$target_dir"
# Follow staging symlinks, compare bytes even when size and mtime match, and remove
# stale files only after a complete, nonempty source list has been validated.
rsync -rLc --delete --chmod=F644 --itemize-changes --out-format='%i %n' \
  "$work/fonts/" "$target_dir/" > "$work/changes"
# Keep a retry marker outside the synchronized directory if cache generation fails.
pending="${target_dir%/}.cache-pending"
if [[ -s "$work/changes" ]]; then
  touch "$pending"
fi
if [[ -e "$pending" ]]; then
  "$fc_cache" -f "$target_dir"
  rm -f "$pending"
fi

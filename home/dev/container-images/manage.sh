set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/distrobox"
manifest="$config_dir/distrobox.ini"

build_one() {
  local name="$1"
  local containerfile="$config_dir/images/$name.Containerfile"
  local image="localhost/distrobox-$name:managed"

  if [[ ! -r "$containerfile" ]]; then
    printf 'Missing managed Containerfile: %s\n' "$containerfile" >&2
    return 1
  fi

  podman build \
    --pull=always \
    --label "io.nixos.distrobox.source=$containerfile" \
    --tag "$image" \
    --file "$containerfile" \
    "$config_dir/images"
}

for_each_image() {
  local action="$1"
  local name
  for name in arch fedora ubuntu; do
    "$action" "$name"
  done
}

usage() {
  cat <<'EOF'
Usage:
  distrobox-images build <arch|fedora|ubuntu|all>
  distrobox-images plan [arch|fedora|ubuntu]
  distrobox-images status

build   Build a managed image without replacing a container.
plan    Show the Distrobox assemble command without changing containers.
status  Show managed images and current Distrobox containers.
EOF
}

command="${1:-}"
target="${2:-all}"

case "$command" in
  build)
    case "$target" in
      arch|fedora|ubuntu) build_one "$target" ;;
      all) for_each_image build_one ;;
      *) usage >&2; exit 2 ;;
    esac
    ;;
  plan)
    if [[ ! -r "$manifest" ]]; then
      printf 'Missing managed manifest: %s\n' "$manifest" >&2
      exit 1
    fi
    case "$target" in
      arch|fedora|ubuntu)
        distrobox assemble create --dry-run --file "$manifest" --name "$target"
        ;;
      all)
        distrobox assemble create --dry-run --file "$manifest"
        ;;
      *) usage >&2; exit 2 ;;
    esac
    ;;
  status)
    podman images --filter reference='localhost/distrobox-*' \
      --format 'table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Created}}\t{{.Size}}'
    printf '\n'
    distrobox list
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

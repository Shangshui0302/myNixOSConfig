{ pkgs }:

# Hyprland 0.57 render contexts and logging API compatibility.
# Keep the nixpkgs plugin builder so the plugin uses the same Hyprland headers.
pkgs.hyprlandPlugins.hypr-dynamic-cursors.overrideAttrs (_: {
  version = "0-unstable-2026-10-05";
  src = pkgs.fetchFromGitHub {
    owner = "VirtCode";
    repo = "hypr-dynamic-cursors";
    rev = "2a8d0b735328d874a78ca93b2f201649f712a74a";
    hash = "sha256-PSt/SRtemvsoGYNFJ7YLiXGxT8EJe3AhmGwt5Vt79aA=";
  };
})

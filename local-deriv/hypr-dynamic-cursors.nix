{ pkgs, src }:

# flake.lock pins upstream source; retain nixpkgs' host-matched plugin builder.
pkgs.hyprlandPlugins.hypr-dynamic-cursors.overrideAttrs (_: {
  version = "0-unstable-${src.shortRev}";
  inherit src;
  # Source updates are owned by flake.lock, not nix-update's package-file editor.
  passthru.updateScript = null;
})

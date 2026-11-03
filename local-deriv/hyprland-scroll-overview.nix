{ pkgs, src }:

let
  version = "0-unstable-${src.shortRev}";
in
pkgs.hyprlandPlugins.mkHyprlandPlugin {
  pluginName = "scrolloverview";
  inherit version;

  # flake.lock pins the source; the builder uses the host Hyprland and compiler.
  inherit src;

  buildInputs = [ pkgs.lua5_4 ];
  enableParallelBuilding = true;

  makeFlags = [ "LUA_PKG=lua5.4" ];
  preBuild = ''
    export SCROLLOVERVIEW_BUILD_VERSION="${version}"
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 scrolloverview.so "$out/lib/libscrolloverview.so"
    runHook postInstall
  '';

  meta = {
    description = "Scrollable workspace overview plugin for Hyprland";
    homepage = "https://github.com/yayuuu/hyprland-scroll-overview";
    license = pkgs.lib.licenses.bsd3;
    platforms = pkgs.lib.platforms.linux;
    sourceProvenance = with pkgs.lib.sourceTypes; [ fromSource ];
  };
}

{ pkgs }:

let
  version = "0-unstable-2026-08-08";
in
pkgs.hyprlandPlugins.mkHyprlandPlugin {
  pluginName = "scrolloverview";
  inherit version;

  # The main branch matches the stable Hyprland 0.56 API in nixpkgs.
  src = pkgs.fetchFromGitHub {
    owner = "yayuuu";
    repo = "hyprland-scroll-overview";
    rev = "f9248ab6bee770e9d68813b48cc6ca12b3271254";
    hash = "sha256-SEa8XQtrNg90AUeZFE9+lGvYEWd0T2ht/+sKx+kWUak=";
  };

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

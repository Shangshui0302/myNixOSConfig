{ pkgs }:

pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "material-adw-kvantum";
  version = "0-unstable-2026-08-27";

  src = pkgs.fetchFromGitHub {
    owner = "end-4";
    repo = "dots-hyprland";
    rev = "97c5bc651f68092351b24aaa935af708b1e04514";
    hash = "sha256-G752F8ymZ2STu98RPh+M87hxFKDYpaofnjVcxj32eJo=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontCheck = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 dots/.config/Kvantum/MaterialAdw/MaterialAdw.kvconfig \
      "$out/share/Kvantum/MaterialAdw/MaterialAdw.kvconfig"
    install -Dm644 dots/.config/Kvantum/MaterialAdw/MaterialAdw.svg \
      "$out/share/Kvantum/MaterialAdw/MaterialAdw.svg"
    install -Dm644 LICENSE "$out/share/licenses/${finalAttrs.pname}/LICENSE"
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "MaterialAdw Kvantum theme assets from end-4's dots-hyprland";
    homepage = "https://github.com/end-4/dots-hyprland";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    sourceProvenance = with sourceTypes; [ fromSource ];
  };
})

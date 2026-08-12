{ pkgs, ... }:

# Material GNOME — Material You/Material 3 风格 GNOME 桌面主题。
# 纯主题文件无需编译：把仓库内容整体作为 share/themes/Material-Gnome/。
# 配合 gnomeExtensions.user-themes 加载（org.gnome.shell.extensions.user-theme name='Material-Gnome'）。
let inherit (pkgs) lib stdenv fetchFromGitHub; in
stdenv.mkDerivation {
  pname = "material-gnome-theme";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "SakibShahariar";
    repo = "material-gnome-theme";
    rev = "v.1.3.0";
    hash = "sha256-/oHVl8erXsLfvsFVk9qx5eI8M234IZYdzOjNQjE9UvU=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/themes/Material-Gnome
    cp -r gnome-shell gtk-3.0 gtk-4.0 themes index.theme LICENSE $out/share/themes/Material-Gnome/
    runHook postInstall
  '';

  meta = {
    description = "Material You / Material 3 GNOME desktop theme (Shell + GTK3/4)";
    homepage = "https://github.com/SakibShahariar/material-gnome-theme";
    license = lib.licenses.gpl3;
  };
}

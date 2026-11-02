{
  pkgs,
  wallpaper ? null,
  schemeType ? "scheme-tonal-spot",
  contrast ? 0.0,
  mode ? "dark",
  ...
}:

# 保留上游 Material-Gnome GTK3/4 资源及 Matugen 配色，不安装 GNOME Shell。
# 主题名称保持不变，供已有 GTK 运行时目录继续使用。
let
  inherit (pkgs) lib stdenvNoCC fetchFromGitHub;
  hasWallpaper = wallpaper != null;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "material-gnome-theme";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "SakibShahariar";
    repo = "material-gnome-theme";
    rev = "v.${finalAttrs.version}";
    hash = "sha256-/oHVl8erXsLfvsFVk9qx5eI8M234IZYdzOjNQjE9UvU=";
  };

  nativeBuildInputs = lib.optionals hasWallpaper [
    pkgs.matugen
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/themes/Material-Gnome
    cp -r gtk-3.0 gtk-4.0 index.theme LICENSE $out/share/themes/Material-Gnome/
    sed -i '/^MetacityTheme=/d; /^ButtonLayout=/d' $out/share/themes/Material-Gnome/index.theme

    ${lib.optionalString hasWallpaper ''
      # Matugen 为 GTK3/4 提供初始壁纸配色。
      cat > matugen.toml <<EOF
      [config]

      [templates.gtk3]
      input_path = '${./material-gnome/gtk3.tpl}'
      output_path = '$out/share/themes/Material-Gnome/gtk-3.0/colors.css'

      [templates.gtk4]
      input_path = '${./material-gnome/gtk4.tpl}'
      output_path = '$out/share/themes/Material-Gnome/gtk-4.0/colors.css'
      EOF
      # matugen 取色：先尝试自动选色；非交互构建遇到多个候选色时，
      # fallback 到显式 --prefer saturation，兼容当前及旧版。
      if ${pkgs.matugen}/bin/matugen image ${wallpaper} -m ${mode} -t ${schemeType} --contrast ${toString contrast} -c matugen.toml; then
        echo "matugen: 自动选色成功"
      else
        ${pkgs.matugen}/bin/matugen image ${wallpaper} -m ${mode} -t ${schemeType} --contrast ${toString contrast} --prefer saturation -c matugen.toml
        echo "matugen: fallback --prefer saturation"
      fi
    ''}
    runHook postInstall
  '';

  meta = {
    description = "Material You GTK3/4 theme, recolorable via Matugen wallpaper";
    homepage = "https://github.com/SakibShahariar/material-gnome-theme";
    license = lib.licenses.gpl3;
    platforms = lib.platforms.linux;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
  };
})

{ pkgs, wallpaper ? null, shellLayout ? "floating-capsule", schemeType ? "scheme-tonal-spot", prefer ? "saturation", contrast ? 0.0, mode ? "dark", ... }:

# Material GNOME — Material You/Material 3 风格 GNOME 桌面主题。
# 纯主题文件无需编译：把仓库内容整体作为 share/themes/Material-Gnome/。
# 配合 gnomeExtensions.user-themes 加载（org.gnome.shell.extensions.user-theme name='Material-Gnome'）。
#
# wallpaper 非空时，构建期用 matugen 从壁纸取色，重着色 gtk-3.0/gtk-4.0 的 colors.css，
# 并按 token 映射批量替换 gnome-shell.css 的硬编码 hex —— 整套主题（Shell + GTK）跟随壁纸配色。
let
  inherit (pkgs) lib stdenv fetchFromGitHub;
  hasWallpaper = wallpaper != null;
in
stdenv.mkDerivation {
  pname = "material-gnome-theme";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "SakibShahariar";
    repo = "material-gnome-theme";
    rev = "v.1.3.0";
    hash = "sha256-/oHVl8erXsLfvsFVk9qx5eI8M234IZYdzOjNQjE9UvU=";
  };

  nativeBuildInputs = lib.optionals hasWallpaper [ pkgs.matugen pkgs.python3 ];

  installPhase = ''
    runHook preInstall
    # 顶栏布局替换：gnome-shell.css 的布局块（从布局注释行到文件尾）换成 shellLayout 选中的布局。
    # 锚点：定位首个 #panel { 本体，向上找最近的 /* */ 注释行作为布局块起点。
    N=$(grep -n "^#panel {" gnome-shell/gnome-shell.css | head -1 | cut -d: -f1)
    M=$(awk -v n="$N" 'NR<n && /^\/\*/{last=NR} END{print last}' gnome-shell/gnome-shell.css)
    head -n "$((M-1))" gnome-shell/gnome-shell.css > gnome-shell.css.new
    cat "gnome-shell/layouts/${shellLayout}.css" >> gnome-shell.css.new
    mv gnome-shell.css.new gnome-shell/gnome-shell.css
    mkdir -p $out/share/themes/Material-Gnome
    cp -r gnome-shell gtk-3.0 gtk-4.0 themes index.theme LICENSE $out/share/themes/Material-Gnome/

    ${lib.optionalString hasWallpaper ''
      # —— Matugen 从壁纸取色，重着色整套主题 ——
      # 保留原始配色，供 shell hex 映射用
      cp gtk-3.0/colors.css old-colors.css
      cat > matugen.toml <<EOF
      [config]

      [templates.gtk3]
      input_path = '${./material-gnome/gtk3.tpl}'
      output_path = '$out/share/themes/Material-Gnome/gtk-3.0/colors.css'

      [templates.gtk4]
      input_path = '${./material-gnome/gtk4.tpl}'
      output_path = '$out/share/themes/Material-Gnome/gtk-4.0/colors.css'
      EOF
      ${pkgs.matugen}/bin/matugen image ${wallpaper} -m ${mode} --prefer ${prefer} -t ${schemeType} --contrast ${toString contrast} -c matugen.toml
      # GNOME Shell 配色硬编码 hex：按 token 映射批量替换
      ${pkgs.python3}/bin/python3 ${./material-gnome/recolor-shell.py} \
        old-colors.css \
        $out/share/themes/Material-Gnome/gtk-3.0/colors.css \
        $out/share/themes/Material-Gnome/gnome-shell/gnome-shell.css
    ''}
    runHook postInstall
  '';

  meta = {
    description = "Material You / Material 3 GNOME desktop theme (Shell + GTK3/4), recolorable via Matugen wallpaper";
    homepage = "https://github.com/SakibShahariar/material-gnome-theme";
    license = lib.licenses.gpl3;
  };
}

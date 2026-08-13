{ pkgs, ... }:

# Persona-Quickshell — Hyprland 桌面 shell 主题（纯 QML，仓库即配置）。
# 无 Nix 打包，这里 fetch 源码拷到 $out/share/persona-quickshell，由 quickshell -c 加载。
# 可选 Cava 插件依赖跳过：删除 Widgets/CavaVisualizer.qml（无 QML 引用它，README 官方做法）。
let
  inherit (pkgs) lib stdenv fetchFromGitHub;
in
stdenv.mkDerivation {
  pname = "persona-quickshell";
  version = "unstable-2026-08-13";

  nativeBuildInputs = [ pkgs.python3 ];

  src = fetchFromGitHub {
    owner = "Yujonpradhananga";
    repo = "Persona-Quickshell";
    rev = "6bb02aa50f609be8047f67b8a9984274c91e2060";
    hash = "sha256-Imjg5a1FM/YKuGpbBy1kuwcDofkpAIGOsM/9PJenM4w=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/persona-quickshell
    cp -r . $out/share/persona-quickshell/
    # 跳过 Cava 插件（Qt6-Cava-plugin 需手编）：删 CavaVisualizer.qml +
    # WallpaperEngine.qml 里的 CavaVisualizer 块（README 官方做法，两者都要删）。
    rm -f $out/share/persona-quickshell/Widgets/CavaVisualizer.qml
    python3 - <<PYEOF
p = "$out/share/persona-quickshell/Widgets/WallpaperEngine.qml"
lines = open(p).read().split("\n")
out = []
i = 0
while i < len(lines):
    if "CavaVisualizer" in lines[i] and "{" in lines[i]:
        depth = 0
        while i < len(lines):
            depth += lines[i].count("{") - lines[i].count("}")
            i += 1
            if depth <= 0 and lines[i - 1].strip().endswith("}"):
                break
        continue
    out.append(lines[i]); i += 1
open(p, "w").write("\n".join(out))
PYEOF
    runHook postInstall
  '';

  meta = {
    description = "Persona-Quickshell Hyprland shell theme (pure QML)";
    homepage = "https://github.com/Yujonpradhananga/Persona-Quickshell";
    license = lib.licenses.mit;
  };
}

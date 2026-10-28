{ pkgs }:
let
  python = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);
  # path:. 包含新文件；排除本地记忆、工具状态和构建产物，保持检查可移植。
  repositorySource = pkgs.lib.cleanSourceWith {
    src = pkgs.lib.cleanSource ../.;
    filter =
      path: _type:
      !(builtins.elem (builtins.baseNameOf path) [
        "memory"
        ".codex"
        ".vscode"
        "__pycache__"
      ]);
  };
in
{
  mihomo-config-sync =
    pkgs.runCommand "mihomo-config-sync-tests"
      {
        nativeBuildInputs = [ python ];
      }
      ''
        mkdir -p host tests
        cp ${../host/mihomo-config-sync.py} host/mihomo-config-sync.py
        cp ${../tests/test_mihomo_config_sync.py} tests/test_mihomo_config_sync.py
        export PYTHONDONTWRITEBYTECODE=1
        python3 -W error::ResourceWarning -m unittest discover -s tests -v
        touch "$out"
      '';

  # 只运行已有的事件 mock，不启动或连接 Hyprland。
  hyprland-policies =
    pkgs.runCommand "hyprland-policy-tests"
      {
        nativeBuildInputs = [ pkgs.lua ];
      }
      ''
        mkdir -p home/de tests
        cp -r ${../home/de/hyprland} home/de/hyprland
        cp ${../tests}/*.lua tests/
        for test in tests/*.lua; do
          lua "$test"
        done
        touch "$out"
      '';

  repository-structure =
    pkgs.runCommand "repository-structure-check"
      {
        nativeBuildInputs = [ python ];
      }
      ''
        python3 ${../scripts/check-repo-structure.py} --root ${repositorySource}
        touch "$out"
      '';
}

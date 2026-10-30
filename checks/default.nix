{ pkgs, nextkdeSync }:
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
  theme-apply =
    pkgs.runCommand "theme-apply-tests"
      { nativeBuildInputs = [ pkgs.python3 pkgs.bash pkgs.coreutils pkgs.util-linux pkgs.gnugrep pkgs.gnused pkgs.diffutils pkgs.gawk pkgs.kdePackages.kconfig ]; }
      ''
        mkdir -p home/theme/scripts tests
        cp ${../home/theme/scripts/theme-apply.sh} home/theme/scripts/theme-apply.sh
        cp ${../tests/test_theme_apply.py} tests/test_theme_apply.py
        export PYTHONDONTWRITEBYTECODE=1
        python3 -m unittest discover -s tests -p test_theme_apply.py -v
        touch "$out"
      '';

  font-sync =
    pkgs.runCommand "font-sync-tests"
      {
        nativeBuildInputs = [
          pkgs.python3
          pkgs.bash
          pkgs.coreutils
          pkgs.findutils
          pkgs.rsync
        ];
      }
      ''
        mkdir -p home/theme tests
        cp ${../home/theme/sync-ms-fonts.sh} home/theme/sync-ms-fonts.sh
        cp ${../tests/test_sync_ms_fonts.py} tests/test_sync_ms_fonts.py
        export PYTHONDONTWRITEBYTECODE=1
        python3 -m unittest discover -s tests -p test_sync_ms_fonts.py -v
        touch "$out"
      '';

  nextkde-shell-sync =
    pkgs.runCommand "nextkde-shell-sync-tests"
      {
        nativeBuildInputs = [ pkgs.python3 ];
        KOS_SYNC_SCRIPT = nextkdeSync;
      }
      ''
        export PYTHONDONTWRITEBYTECODE=1
        python3 ${../tests/test_nextkde_sync.py} -v
        touch "$out"
      '';

  kde-colors =
    pkgs.runCommand "kde-color-distribution-tests" { nativeBuildInputs = [ pkgs.python3 ]; }
      ''
        mkdir -p home/theme tests
        cp ${../home/theme/kde-colors.py} home/theme/kde-colors.py
        cp ${../tests/test_kde_colors.py} tests/test_kde_colors.py
        export PYTHONDONTWRITEBYTECODE=1
        python3 -W error::ResourceWarning -m unittest discover -s tests -p test_kde_colors.py -v
        touch "$out"
      '';

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

  power-actions =
    pkgs.runCommand "power-actions-behavior-tests"
      {
        nativeBuildInputs = [
          pkgs.python3
          pkgs.bash
          pkgs.coreutils
          pkgs.util-linux
        ];
      }
      ''
        mkdir -p home/env/scripts tests
        cp ${../home/env/scripts/power-actions.sh} home/env/scripts/power-actions.sh
        cp ${../tests/test_power_actions.py} tests/test_power_actions.py
        export PYTHONDONTWRITEBYTECODE=1
        python3 -m unittest discover -s tests -p test_power_actions.py -v
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

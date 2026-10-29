{
  inputs,
  materialGnomeTheme,
  pkgs,
  ...
}:
{
  # 三个桌面共用集成策略；上游模块保持原来的导入层级，避免改变列表合并顺序。
  # 用户入口与桌面专属参数由各自的 host 入口选择。
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # Desktop variants share writable files. Preserve every previous backup
    # instead of blocking the whole activation on a second variant switch.
    backupCommand = pkgs.writeShellScript "home-manager-backup" ''
      set -eu
      exec ${pkgs.coreutils}/bin/mv --backup=numbered -T -- "$1" "$1.hm-backup"
    '';
    extraSpecialArgs = { inherit inputs materialGnomeTheme; };
  };
}

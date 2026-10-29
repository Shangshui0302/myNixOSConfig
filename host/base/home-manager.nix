{
  inputs,
  materialGnomeTheme,
  ...
}:
{
  # 三个桌面共用集成策略；上游模块保持原来的导入层级，避免改变列表合并顺序。
  # 用户入口与桌面专属参数由各自的 host 入口选择。
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs materialGnomeTheme; };
  };
}

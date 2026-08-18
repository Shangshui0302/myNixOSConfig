{ pkgs, ... }:

let
  anthropic-fonts = import ../../local-deriv/anthropic-fonts.nix { inherit pkgs; };
in
{
  # Stylix 只提供统一颜色源；具体组件仍由各自的 HM 模块配置。
  # GTK 保持 Material-Gnome、Qt 保持 qt5ct/breeze、Noctalia 面板保持 yamadaryou。
  stylix = {
    enable = true;
    autoEnable = false;
    polarity = "dark";           # 终端/合成器暗色
    image = ../../assets/yamadaryou.png;
    fonts.monospace = {
      name = "Anthropic Mono Variable";
      package = anthropic-fonts;
    };
  };
}

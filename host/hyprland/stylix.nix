{ config, lib, pkgs, ... }:

let
  anthropic-fonts = import ../../local-deriv/anthropic-fonts.nix { inherit pkgs; };
in
{
  # stylix — 配色中枢（暴露 config.lib.stylix.colors，手工注入到 foot/hyprland/niri）。
  # 本版本 stylix master 无 foot/hyprland target（target 体系重构）；autoEnable=false 不自动接管任何组件，
  # 配色由 config.lib.stylix.colors 在 desktop.nix（foot）与 hyprland/niri 配置里手工引用。
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

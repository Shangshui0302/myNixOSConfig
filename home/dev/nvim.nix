{ pkgs, ... }:

{
  home.packages = with pkgs; [
    neovim
  ];

  xdg.configFile."nvim/init.lua".source = ./nvim/init.lua;

  xdg.desktopEntries.nvim = {
    name = "Neovim";
    genericName = "Text Editor";
    exec = "foot -e nvim %F";
    terminal = false;
    icon = "nvim";
    categories = [ "Utility" "TextEditor" ];
    mimeType = [
      "text/plain" "text/markdown" "text/x-nix"
      "text/x-python" "text/x-shellscript"
      "application/json" "application/toml" "application/x-yaml"
    ];
  };

  xdg.mimeApps.defaultApplications = {
    "text/plain" = "nvim.desktop";
    "text/markdown" = "nvim.desktop";
    "text/x-nix" = "nvim.desktop";
    "application/json" = "nvim.desktop";
    "application/toml" = "nvim.desktop";
  };
}

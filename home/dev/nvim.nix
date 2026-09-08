{ pkgs, ... }:

let
  vimPlugins = with pkgs.vimPlugins; [
    snacks-nvim
    lualine-nvim
    catppuccin-nvim
    rose-pine
    tokyonight-nvim
    kanagawa-nvim
    smear-cursor-nvim
    plenary-nvim
    nvim-web-devicons
    (nvim-treesitter.withPlugins (p: with p; [
      bash
      css
      html
      lua
      markdown
      nix
      vim
      vimdoc
    ]))
    mason-nvim
    nvim-cmp
    cmp-nvim-lsp
    cmp-buffer
    cmp-nvim-lua
    cmp-async-path
    luasnip
    friendly-snippets
    telescope-nvim
    nvim-tree-lua
    which-key-nvim
    conform-nvim
    gitsigns-nvim
    nvim-autopairs
    indent-blankline-nvim
    markview-nvim
    ts-comments-nvim
  ];
in
{
  programs.neovim = {
    enable = true;
    withNodeJs = false;
    withPython3 = false;
    withRuby = false;
    plugins = vimPlugins;
    initLua = builtins.readFile ./nvim/init.lua;
    extraPackages = with pkgs; [
      stylua
      chafa
    ];
  };

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

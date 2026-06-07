vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- ===== Colorschemes =====
  { "folke/tokyonight.nvim", priority = 1000, opts = { style = "night" } },
  { "catppuccin/nvim", name = "catppuccin", opts = { flavour = "mocha" } },
  { "rose-pine/neovim", name = "rose-pine", opts = { variant = "moon" } },
  { "rebelot/kanagawa.nvim", opts = {} },

  -- ===== Core utils =====
  "nvim-lua/plenary.nvim",
  "nvim-tree/nvim-web-devicons",

  -- ===== Syntax highlight =====
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "lua", "vim", "vimdoc", "html", "css", "markdown", "bash", "nix" },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
  },

  -- ===== LSP =====
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    opts = {},
  },

  -- ===== Completion =====
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-nvim-lua",
      "FelipeLema/cmp-async-path",
      "L3MON4D3/LuaSnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "nvim_lua" },
          { name = "async_path" },
        }),
      })
    end,
  },

  -- ===== Telescope =====
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = { "plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
    },
    opts = {},
  },

  -- ===== File tree =====
  {
    "nvim-tree/nvim-tree.lua",
    keys = {
      { "<C-n>", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file tree" },
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file tree" },
    },
    opts = {},
  },

  -- ===== Which-key =====
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- ===== Formatting =====
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
      },
      format_on_save = function(bufnr)
        return { timeout_ms = 500, lsp_fallback = true }
      end,
    },
  },

  -- ===== Git =====
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local map = function(k, v, d)
          vim.keymap.set("n", k, v, { buffer = bufnr, desc = d })
        end
        map("]c", gs.next_hunk, "Next hunk")
        map("[c", gs.prev_hunk, "Prev hunk")
        map("<leader>hs", gs.stage_hunk, "Stage hunk")
        map("<leader>hr", gs.reset_hunk, "Reset hunk")
        map("<leader>hp", gs.preview_hunk, "Preview hunk")
      end,
    },
  },

  -- ===== Autopairs =====
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  -- ===== Indent guides =====
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {},
  },

  -- ===== Markdown preview =====
  {
    "OXY2DEV/markview.nvim",
    ft = "markdown",
    opts = {},
  },

  -- ===== Comment =====
  {
    "folke/ts-comments.nvim",
    event = "VeryLazy",
    opts = {},
  },

})

-- ===== LSP (built-in, Neovim 0.11+) =====
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local map = function(keys, func, desc)
      vim.keymap.set("n", keys, func, { buffer = args.buf, desc = desc })
    end
    map("gd", vim.lsp.buf.definition, "[G]o to [D]efinition")
    map("gr", vim.lsp.buf.references, "[G]o to [R]eferences")
    map("K", vim.lsp.buf.hover, "Hover")
    map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
    map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
  end,
})

vim.lsp.config("html", {})
vim.lsp.config("cssls", {})
vim.lsp.enable("html")
vim.lsp.enable("cssls")

-- ===== Options =====
vim.opt.clipboard = "unnamedplus"
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.mouse = "a"
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.undofile = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400

-- ===== Keymaps =====
vim.keymap.set("n", ";", ":", { desc = "Enter command mode" })
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- ===== Theme picker =====
vim.keymap.set("n", "<leader>tC", "<cmd>Telescope colorscheme<cr>", { desc = "Theme browser" })

-- ===== Colorscheme =====
vim.cmd.colorscheme("tokyonight-night")

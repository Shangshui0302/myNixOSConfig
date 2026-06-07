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
      { "<leader>fw", "<cmd>Telescope grep_string<cr>", desc = "Grep word" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
      { "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
      { "<leader>fc", "<cmd>Telescope commands<cr>", desc = "Commands" },
      { "<leader>s/", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Find in buffer" },
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

-- Buffer
vim.keymap.set("n", "<leader>bd", "<cmd>bd<cr>", { desc = "Delete buffer" })
vim.keymap.set("n", "<leader>bn", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", "<cmd>bprev<cr>", { desc = "Prev buffer" })
vim.keymap.set("n", "<leader><leader>", "<cmd>e #<cr>", { desc = "Last buffer" })

-- Window
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })
vim.keymap.set("n", "<leader>wv", "<cmd>vsplit<cr>", { desc = "Split vertical" })
vim.keymap.set("n", "<leader>ws", "<cmd>split<cr>", { desc = "Split horizontal" })
vim.keymap.set("n", "<leader>wq", "<cmd>close<cr>", { desc = "Close window" })

-- File
vim.keymap.set("n", "<leader>fs", "<cmd>w<cr>", { desc = "Save file" })

-- Toggle
vim.keymap.set("n", "<leader>tn", "<cmd>set nu!<cr>", { desc = "Line numbers" })
vim.keymap.set("n", "<leader>tr", "<cmd>set rnu!<cr>", { desc = "Relative numbers" })
vim.keymap.set("n", "<leader>tw", "<cmd>set wrap!<cr>", { desc = "Line wrap" })

-- Quit
vim.keymap.set("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit nvim" })

-- ===== Theme picker (live preview) =====
vim.keymap.set("n", "<leader>tC", function()
  local apply = function(buf)
    local entry = require("telescope.actions.state").get_selected_entry()
    if entry then vim.cmd.colorscheme(entry.value) end
  end
  require("telescope.builtin").colorscheme({
    attach_mappings = function(_, map)
      map("i", "<Down>", function(buf) require("telescope.actions").move_selection_next(buf); apply(buf) end)
      map("i", "<Up>",   function(buf) require("telescope.actions").move_selection_previous(buf); apply(buf) end)
      map("n", "j",      function(buf) require("telescope.actions").move_selection_next(buf); apply(buf) end)
      map("n", "k",      function(buf) require("telescope.actions").move_selection_previous(buf); apply(buf) end)
      return true
    end,
  })
end, { desc = "Theme browser (live)" })

-- ===== Colorscheme =====
vim.cmd.colorscheme("tokyonight-night")

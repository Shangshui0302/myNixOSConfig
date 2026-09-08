vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Plugins are installed by Home Manager, so startup does not clone or update
-- anything from the network.

-- ===== Themes =====
require("tokyonight").setup({ style = "night", transparent = true })
require("catppuccin").setup({ flavour = "mocha", transparent_background = true })
require("rose-pine").setup({ variant = "moon", styles = { transparency = true } })
require("kanagawa").setup({})

-- ===== UI =====
require("smear_cursor").setup({
  smear_between_buffers = true,
  smear_between_neighbor_lines = true,
  scroll_buffer_space = true,
  smear_insert_mode = true,
})

require("nvim-treesitter").setup({})
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "bash", "css", "html", "lua", "markdown", "nix", "vim", "vimdoc" },
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

require("mason").setup({})
require("nvim-tree").setup({})
require("which-key").setup({})
require("conform").setup({
  formatters_by_ft = { lua = { "stylua" } },
  format_on_save = function()
    return { timeout_ms = 500, lsp_fallback = true }
  end,
})
require("nvim-autopairs").setup({})
require("ibl").setup({})
require("markview").setup({})
require("ts-comments").setup({})

require("gitsigns").setup({
  on_attach = function(bufnr)
    local gs = require("gitsigns")
    local map = function(k, v, d)
      vim.keymap.set("n", k, v, { buffer = bufnr, desc = d })
    end
    map("]c", gs.next_hunk, "Next hunk")
    map("[c", gs.prev_hunk, "Prev hunk")
    map("<leader>hs", gs.stage_hunk, "Stage hunk")
    map("<leader>hr", gs.reset_hunk, "Reset hunk")
    map("<leader>hp", gs.preview_hunk, "Preview hunk")
  end,
})

-- ===== Completion =====
do
  local cmp = require("cmp")
  local luasnip = require("luasnip")
  require("luasnip.loaders.from_vscode").lazy_load()

  cmp.setup({
    snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
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
end

-- ===== Telescope =====
require("telescope").setup({})

-- ===== Dashboard =====
local dashboard_actions = {
  { icon = "", key = "f", desc = "Find File", action = ":Telescope find_files" },
  { icon = "", key = "e", desc = "Browse Files", action = ":NvimTreeToggle" },
  { icon = "", key = "n", desc = "New File", action = ":ene | startinsert" },
  { icon = "", key = "g", desc = "Find Text", action = ":Telescope live_grep" },
  { icon = "", key = "r", desc = "Recent Files", action = ":Telescope oldfiles" },
  { icon = "", key = "q", desc = "Quit", action = ":qa" },
}

local dashboard_menu_width = math.floor(64 / ((1 + math.sqrt(5)) / 2))
local function dashboard_menu()
  local items = {}
  for _, item in ipairs(dashboard_actions) do
    local key = "[" .. item.key .. "]"
    local label_width = vim.api.nvim_strwidth(item.icon) + 1 + vim.api.nvim_strwidth(item.desc)
    local key_width = vim.api.nvim_strwidth(key)
    local gap = math.max(2, dashboard_menu_width - label_width - key_width)
    local right_padding = math.max(0, dashboard_menu_width - label_width - gap - key_width)
    items[#items + 1] = {
      text = {
        { item.icon, hl = "icon" },
        { " " .. item.desc, hl = "desc" },
        { (" "):rep(gap), width = gap },
        { key, hl = "key" },
        { (" "):rep(right_padding), width = right_padding },
      },
      key = item.key,
      action = item.action,
      align = "center",
      padding = 1,
    }
  end
  return items
end

require("snacks").setup({
  dashboard = {
    enabled = true,
    width = 64,
    sections = {
      {
        section = "terminal",
        -- Keep the display job alive so Snacks does not append a process-exit line.
        cmd = "chafa --format symbols --symbols vhalf --size 64x28 /home/lishangshui/Pictures/Wallpapers/yamadaryou_glasses_headsphone.png; exec tail -f /dev/null",
        -- chafa preserves the source ratio and emits 22 rows within the 64x28 limit.
        height = 22,
        width = 64,
        padding = 2,
      },
      dashboard_menu,
    },
  },
})

vim.api.nvim_create_autocmd("User", {
  pattern = "SnacksDashboardOpened",
  callback = function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "snacks_dashboard" then
        local winhighlight = vim.api.nvim_get_option_value("winhighlight", { win = win })
        for _, group in ipairs({ "Cursor", "TermCursor", "CursorLine" }) do
          if not winhighlight:find(group .. ":", 1, true) then
            winhighlight = winhighlight .. "," .. group .. ":SnacksDashboardNormal"
          end
        end
        vim.api.nvim_set_option_value("winhighlight", winhighlight, { win = win })
      end
    end
  end,
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

-- nvim-lspconfig supplies the html/cssls definitions; Mason prepends its bin
-- directory to PATH, so the installed language servers remain user-managed.
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

-- Telescope
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find Files" })
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live Grep" })
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Help Tags" })
vim.keymap.set("n", "<leader>fw", "<cmd>Telescope grep_string<cr>", { desc = "Grep word" })
vim.keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Recent files" })
vim.keymap.set("n", "<leader>fk", "<cmd>Telescope keymaps<cr>", { desc = "Keymaps" })
vim.keymap.set("n", "<leader>fc", "<cmd>Telescope commands<cr>", { desc = "Commands" })
vim.keymap.set("n", "<leader>s/", "<cmd>Telescope current_buffer_fuzzy_find<cr>", { desc = "Find in buffer" })

-- File tree
vim.keymap.set("n", "<C-n>", "<cmd>NvimTreeToggle<cr>", { desc = "Toggle file tree" })
vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Toggle file tree" })

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
vim.opt.termguicolors = true

-- Neovim is rendered inside Foot. Transparent highlight groups let Foot's
-- existing terminal alpha/blur show through instead of painting a second opaque pane.
local matugen_palette_path = vim.fn.expand("~/.cache/matugen/nvim-colors.lua")
local matugen_colors = {}

local function load_matugen_colors()
  local ok, palette = pcall(dofile, matugen_palette_path)
  matugen_colors = ok and type(palette) == "table" and palette or {}
end

local function palette_color(name, fallback)
  return matugen_colors[name] or fallback
end

load_matugen_colors()

local transparent_groups = {
  "Normal", "NormalNC", "NormalFloat", "FloatBorder", "FloatTitle",
  "SignColumn", "FoldColumn", "LineNr", "CursorLineNr", "CursorLine",
  "EndOfBuffer", "MsgArea", "StatusLine", "StatusLineNC", "WinSeparator",
  "NvimTreeNormal", "NvimTreeNormalNC", "NvimTreeEndOfBuffer",
  "TelescopeNormal", "TelescopeBorder", "TelescopePromptNormal",
  "TelescopePromptBorder", "TelescopeResultsNormal", "TelescopeResultsBorder",
  "TelescopePromptTitle", "TelescopeResultsTitle", "TelescopePreviewNormal",
  "TelescopePreviewBorder", "TelescopePreviewTitle",
  "SnacksDashboardNormal", "SnacksDashboardNormalNC",
  "SnacksDashboardHeader", "SnacksDashboardIcon", "SnacksDashboardKey",
  "SnacksDashboardDesc", "SnacksDashboardFooter",
}

local function apply_transparency()
  for _, group in ipairs(transparent_groups) do
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    hl.bg = "none"
    vim.api.nvim_set_hl(0, group, hl)
  end
  local dashboard_colors = {
    SnacksDashboardIcon = "primary",
    SnacksDashboardDesc = "on_surface",
    SnacksDashboardKey = "secondary",
    SnacksDashboardFooter = "tertiary",
  }
  for group, color in pairs(dashboard_colors) do
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    hl.fg = palette_color(color, hl.fg)
    hl.bold = true
    vim.api.nvim_set_hl(0, group, hl)
  end
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_transparency })
vim.cmd.colorscheme("tokyonight-night")
apply_transparency()

-- ===== Starship-inspired statusline =====
-- Keep the editing-relevant parts of Starship; shell-only modules such as
-- cmd_duration, battery, Docker context, and language runtimes stay in the shell.
local function starship_colors()
  return {
    dark = palette_color("on_primary", "#101418"),
    green = palette_color("primary", "#abe15b"),
    blue = palette_color("secondary", "#33adff"),
    purple = palette_color("tertiary", "#bb88ee"),
    yellow = palette_color("secondary_container", "#ffd242"),
    red = palette_color("error", "#ff2740"),
    cyan = palette_color("primary_container", "#5fafd7"),
    white = palette_color("on_surface", "#e0e2e8"),
  }
end

local function nvim_mode()
  return ({
    n = "NORMAL",
    no = "NORMAL",
    i = "INSERT",
    ic = "INSERT",
    v = "VISUAL",
    V = "V-LINE",
    ["\22"] = "V-BLOCK",
    c = "COMMAND",
    R = "REPLACE",
    t = "TERMINAL",
  })[vim.fn.mode()] or vim.fn.mode():upper()
end

local function cwd()
  return "󰉋 " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
end

local function nix_shell()
  return " " .. (vim.env.IN_NIX_SHELL or "")
end

local function clock()
  return os.date("󰥔 %H:%M")
end

local function setup_lualine()
  local colors = starship_colors()
  local starship_theme = {
    normal = {
      a = { fg = colors.dark, bg = colors.green, gui = "bold" },
      b = { fg = colors.purple, bg = "none", gui = "bold" },
      c = { fg = colors.white, bg = "none" },
    },
    insert = {
      a = { fg = colors.dark, bg = colors.blue, gui = "bold" },
      b = { fg = colors.purple, bg = "none", gui = "bold" },
      c = { fg = colors.white, bg = "none" },
    },
    visual = {
      a = { fg = colors.dark, bg = colors.purple, gui = "bold" },
      b = { fg = colors.purple, bg = "none", gui = "bold" },
      c = { fg = colors.white, bg = "none" },
    },
    replace = {
      a = { fg = colors.dark, bg = colors.red, gui = "bold" },
      b = { fg = colors.purple, bg = "none", gui = "bold" },
      c = { fg = colors.white, bg = "none" },
    },
    command = {
      a = { fg = colors.dark, bg = colors.yellow, gui = "bold" },
      b = { fg = colors.purple, bg = "none", gui = "bold" },
      c = { fg = colors.white, bg = "none" },
    },
    inactive = {
      a = { fg = colors.cyan, bg = "none" },
      b = { fg = colors.purple, bg = "none" },
      c = { fg = colors.white, bg = "none" },
    },
  }

  require("lualine").setup({
    options = {
      theme = starship_theme,
      globalstatus = true,
      icons_enabled = true,
      component_separators = { left = "│", right = "│" },
      section_separators = { left = "", right = "" },
    },
    sections = {
      lualine_a = {
        { nvim_mode, padding = { left = 1, right = 1 } },
      },
      lualine_b = {
        { cwd, color = { fg = colors.blue, gui = "bold" } },
        { "branch", icon = " ", color = { fg = colors.purple, gui = "bold" } },
        { "diff", symbols = { added = "+", modified = "!", removed = "-" }, color = { fg = colors.yellow, gui = "bold" } },
        { "diagnostics", symbols = { error = "✘ ", warn = "▲ ", info = "● ", hint = "⚑ " } },
      },
      lualine_c = {
        { "filename", path = 1, symbols = { modified = "●", readonly = "" } },
      },
      lualine_x = {
        { nix_shell, cond = function() return vim.env.IN_NIX_SHELL ~= nil end, color = { fg = colors.blue, gui = "bold" } },
        { "filetype", color = { fg = colors.cyan } },
      },
      lualine_y = { "progress" },
      lualine_z = {
        { clock, color = { fg = colors.white, gui = "bold" } },
        "location",
      },
    },
  })
end

setup_lualine()

vim.api.nvim_create_user_command("MatugenReload", function()
  load_matugen_colors()
  apply_transparency()
  setup_lualine()
  require("lualine").refresh()
  vim.cmd("redrawstatus")
end, { desc = "Reload Matugen palette" })

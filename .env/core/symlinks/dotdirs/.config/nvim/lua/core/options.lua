-- Location: ~/.config/nvim/lua/core/options.lua
-- Editor behavior settings
local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Tabs and indentation
opt.tabstop = 4
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

-- Line wrapping
opt.wrap = false

-- Search settings
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true

-- Appearance
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"
opt.cursorline = true

-- Backspace behavior
opt.backspace = "indent,eol,start"

-- Clipboard
opt.clipboard:append("unnamedplus")

-- Split windows
opt.splitright = true
opt.splitbelow = true

-- Mouse support
opt.mouse = "a"

-- Undo and backup
opt.undofile = true
opt.swapfile = false
opt.backup = false

-- Update time (for gitsigns, etc)
opt.updatetime = 250

-- Scroll offset
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Command line
opt.cmdheight = 1
opt.showmode = false

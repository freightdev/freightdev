-- Location: ~/.config/nvim/lua/core/keymaps.lua
-- VSCode-like keyboard shortcuts
local map = vim.keymap.set

-- Set leader key
vim.g.mapleader = " "

-- General keymaps
map("n", "<C-s>", "<cmd>w<CR>", { desc = "Save file" })
map("i", "<C-s>", "<Esc><cmd>w<CR>", { desc = "Save file" })
map("n", "<C-q>", "<cmd>q<CR>", { desc = "Quit" })
map("n", "<C-a>", "ggVG", { desc = "Select all" })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Resize windows
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- Buffer navigation
map("n", "<Tab>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<S-Tab>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<C-w>", "<cmd>bd<CR>", { desc = "Close buffer" })

-- Move lines
map("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Indenting
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Better paste
map("v", "p", '"_dP', { desc = "Paste without yanking" })

-- Plugin keymaps (will work after plugins are installed)
-- File tree toggle
map("n", "<C-b>", "<cmd>Neotree toggle<CR>", { desc = "Toggle file tree" })

-- Terminal toggle
map("n", "<C-j>", "<cmd>ToggleTerm direction=horizontal<CR>", { desc = "Toggle terminal" })
map("t", "<C-j>", "<cmd>ToggleTerm<CR>", { desc = "Toggle terminal" })

-- Telescope (fuzzy finder)
map("n", "<C-p>", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
map("n", "<C-f>", "<cmd>Telescope live_grep<CR>", { desc = "Find in project" })
map("n", "<C-e>", "<cmd>Telescope buffers<CR>", { desc = "Find buffers" })
map("n", "<C-S-p>", "<cmd>Telescope commands<CR>", { desc = "Command palette" })

-- LSP keymaps (will be set in lsp.lua when LSP attaches)
-- F12 = Go to definition
-- Shift+F12 = Find references
-- F2 = Rename
-- K = Hover documentation
-- Ctrl+Space = Show completion

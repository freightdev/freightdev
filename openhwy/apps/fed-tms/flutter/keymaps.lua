-- File: ~/.config/nvim/lua/config/keymaps.lua
-- Custom keybindings

local map = vim.keymap.set

-- Leader key is space (default in LazyVim)

-- AI Commands
map({ "n", "v" }, "<leader>ag", ":Gen<CR>", { desc = "AI Generate" })
map({ "n", "v" }, "<leader>ac", ":Gen Chat<CR>", { desc = "AI Chat" })
map({ "n", "v" }, "<leader>af", ":Gen Fix_Code<CR>", { desc = "AI Fix Code" })
map({ "n", "v" }, "<leader>ae", ":Gen Explain_Code<CR>", { desc = "AI Explain" })
map({ "n", "v" }, "<leader>ao", ":Gen Optimize_Code<CR>", { desc = "AI Optimize" })
map({ "n", "v" }, "<leader>at", ":Gen Generate_Tests<CR>", { desc = "AI Generate Tests" })
map("n", "<leader>aG", ":ChatGPT<CR>", { desc = "ChatGPT" })
map("n", "<leader>aA", ":ChatGPTActAs<CR>", { desc = "ChatGPT Act As" })

-- File Explorer
map("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle File Tree" })
map("n", "<leader>r", ":lua require('ranger-nvim').open()<CR>", { desc = "Open Ranger" })

-- Terminal
map("n", "<C-\\>", ":ToggleTerm<CR>", { desc = "Toggle Terminal" })
map("t", "<C-\\>", "<C-\\><C-n>:ToggleTerm<CR>", { desc = "Toggle Terminal" })
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit Terminal Mode" })

-- SSH to other systems
map("n", "<leader>sh", ":ToggleTerm ssh workbox<CR>", { desc = "SSH to workbox" })

-- Window navigation (like tmux)
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Buffer navigation
map("n", "<S-h>", ":bprevious<CR>", { desc = "Previous buffer" })
map("n", "<S-l>", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })

-- Split windows
map("n", "<leader>wv", ":vsplit<CR>", { desc = "Split vertically" })
map("n", "<leader>wh", ":split<CR>", { desc = "Split horizontally" })
map("n", "<leader>wq", ":close<CR>", { desc = "Close window" })

-- Quick save/quit
map("n", "<leader>w", ":w<CR>", { desc = "Save" })
map("n", "<leader>q", ":q<CR>", { desc = "Quit" })
map("n", "<leader>Q", ":qa!<CR>", { desc = "Quit all (force)" })

-- Code actions (LSP)
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code actions" })
map("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Rename" })
map("n", "<leader>cf", vim.lsp.buf.format, { desc = "Format" })
map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "gr", vim.lsp.buf.references, { desc = "Go to references" })
map("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })

-- Telescope (fuzzy finder)
map("n", "<leader>ff", ":Telescope find_files<CR>", { desc = "Find files" })
map("n", "<leader>fg", ":Telescope live_grep<CR>", { desc = "Live grep" })
map("n", "<leader>fb", ":Telescope buffers<CR>", { desc = "Find buffers" })
map("n", "<leader>fh", ":Telescope help_tags<CR>", { desc = "Help tags" })
map("n", "<leader>fr", ":Telescope oldfiles<CR>", { desc = "Recent files" })

-- Git
map("n", "<leader>gg", ":LazyGit<CR>", { desc = "LazyGit" })
map("n", "<leader>gb", ":Telescope git_branches<CR>", { desc = "Git branches" })
map("n", "<leader>gc", ":Telescope git_commits<CR>", { desc = "Git commits" })

-- Move lines up/down
map("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Better indenting
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- Clear search highlight
map("n", "<Esc>", ":noh<CR>", { desc = "Clear search" })

-- Copy to system clipboard
map("v", "<leader>y", '"+y', { desc = "Copy to clipboard" })
map("n", "<leader>Y", '"+Y', { desc = "Copy line to clipboard" })

-- Paste from system clipboard
map("n", "<leader>p", '"+p', { desc = "Paste from clipboard" })
map("v", "<leader>p", '"+p', { desc = "Paste from clipboard" })

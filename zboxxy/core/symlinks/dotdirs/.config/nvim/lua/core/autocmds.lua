-- Location: ~/.config/nvim/lua/core/autocmds.lua
-- Auto-save, format on save, and other automatic behaviors
local autocmd = vim.api.nvim_create_autocmd

-- Highlight on yank
autocmd("TextYankPost", {
  desc = "Highlight when yanking text",
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})

-- Remove trailing whitespace on save
autocmd("BufWritePre", {
  desc = "Remove trailing whitespace",
  group = vim.api.nvim_create_augroup("trim-whitespace", { clear = true }),
  pattern = "*",
  command = [[%s/\s\+$//e]],
})

-- Auto-save when leaving insert mode or text changes
autocmd({ "InsertLeave", "TextChanged" }, {
  desc = "Auto-save file",
  group = vim.api.nvim_create_augroup("auto-save", { clear = true }),
  pattern = "*",
  callback = function()
    if vim.bo.modified and not vim.bo.readonly and vim.fn.expand("%") ~= "" and vim.bo.buftype == "" then
      vim.cmd("silent! write")
    end
  end,
})

-- Set filetype-specific settings
autocmd("FileType", {
  desc = "Set language-specific settings",
  group = vim.api.nvim_create_augroup("filetype-settings", { clear = true }),
  pattern = { "rust", "go" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

-- Close certain windows with 'q'
autocmd("FileType", {
  desc = "Close with q",
  group = vim.api.nvim_create_augroup("close-with-q", { clear = true }),
  pattern = { "help", "lspinfo", "man", "checkhealth" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true })
  end,
})

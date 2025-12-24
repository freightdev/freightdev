-- Location: ~/.config/nvim/lua/types.lua
-- Type definitions for configuration sections

---@class CoreOptions
-- Editor behavior settings (line numbers, tabs, search, mouse, etc)

---@class CoreKeymaps
-- VSCode-like keyboard shortcuts

---@class CoreAutocmds
-- Auto-save, format on save, highlight on yank

---@class PluginsUI
-- Theme (tokyonight), statusline (lualine), bufferline, icons

---@class PluginsEditor
-- File tree (neo-tree), terminal (toggleterm), fuzzy finder (telescope)

---@class PluginsLSP
-- Language servers for Rust, Go, Python, JS/TS, Bash, JSON/YAML

---@class PluginsCompletion
-- Autocomplete engine with snippets

---@class PluginsGit
-- Git signs in gutter, git commands

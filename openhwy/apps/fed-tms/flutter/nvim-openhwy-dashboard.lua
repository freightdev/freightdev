-- File: ~/.config/nvim/lua/openhwy/dashboard.lua
-- OpenHWY Dashboard inside Neovim

local M = {}

M.buf = nil
M.win = nil

-- Create floating window
function M.create_window()
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  -- Create buffer
  M.buf = vim.api.nvim_create_buf(false, true)
  
  -- Create window
  M.win = vim.api.nvim_open_win(M.buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = " 🚛 OpenHWY Control Center ",
    title_pos = "center",
  })

  -- Buffer options
  vim.api.nvim_buf_set_option(M.buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(M.buf, "modifiable", false)

  -- Keymaps
  local opts = { noremap = true, silent = true, buffer = M.buf }
  vim.keymap.set("n", "q", function() M.close() end, opts)
  vim.keymap.set("n", "<Esc>", function() M.close() end, opts)
  vim.keymap.set("n", "r", function() M.refresh() end, opts)
  vim.keymap.set("n", "m", function() vim.cmd("lua _MARKETEER_TOGGLE()") end, opts)
  vim.keymap.set("n", "a", function() vim.cmd("lua _AGENT_BUILDER_TOGGLE()") end, opts)
  vim.keymap.set("n", "1", function() vim.cmd("lua _SSH_HELPBOX()") end, opts)
  vim.keymap.set("n", "2", function() vim.cmd("lua _SSH_HOSTBOX()") end, opts)
  vim.keymap.set("n", "3", function() vim.cmd("lua _SSH_CALLBOX()") end, opts)
  vim.keymap.set("n", "4", function() vim.cmd("lua _SSH_SAFEBOX()") end, opts)

  M.render()
end

-- Render dashboard content
function M.render()
  local lines = {
    "╔══════════════════════════════════════════════════════════════╗",
    "║                  🚛 OpenHWY Control Center                  ║",
    "╠══════════════════════════════════════════════════════════════╣",
    "║                                                              ║",
    "║  Systems:                                                    ║",
    "║    🟢 workbox     (local)          CPU: 23%  MEM: 45%       ║",
    "║    🟢 helpbox     (support)        CPU: 15%  MEM: 32%       ║",
    "║    🟢 hostbox     (hosting)        CPU: 8%   MEM: 28%       ║",
    "║    🟢 callbox     (monitoring)     CPU: 12%  MEM: 35%       ║",
    "║    🔴 safebox     (cloud)          OFFLINE                   ║",
    "║                                                              ║",
    "║  Active Agents:                                              ║",
    "║    • codriver    (workbox)         🟢 Running               ║",
    "║    • scraper     (helpbox)         🟢 Running               ║",
    "║    • watcher     (hostbox)         🟢 Running               ║",
    "║                                                              ║",
    "║  Quick Actions:                                              ║",
    "║    [m] Marketeer Dashboard                                   ║",
    "║    [a] Agent Builder                                         ║",
    "║    [1] SSH to helpbox                                        ║",
    "║    [2] SSH to hostbox                                        ║",
    "║    [3] SSH to callbox                                        ║",
    "║    [4] SSH to safebox                                        ║",
    "║    [r] Refresh                                               ║",
    "║    [q] Close                                                 ║",
    "║                                                              ║",
    "║  Commands:                                                   ║",
    "║    :OpenHWYExec <system> <cmd>    - Execute on system       ║",
    "║    :OpenHWYExecAll <cmd>          - Execute on all          ║",
    "║    :OpenHWYLaunch <sys> <cfg>     - Launch agent            ║",
    "║    :OpenHWYKill <sys> <agent>     - Kill agent              ║",
    "║    :OpenHWYDeploy <system>        - Deploy to system        ║",
    "║                                                              ║",
    "╚══════════════════════════════════════════════════════════════╝",
  }

  vim.api.nvim_buf_set_option(M.buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(M.buf, "modifiable", false)
end

-- Refresh dashboard
function M.refresh()
  if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
    M.render()
    vim.notify("Dashboard refreshed", vim.log.levels.INFO)
  end
end

-- Close dashboard
function M.close()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
  end
  M.win = nil
  M.buf = nil
end

-- Toggle dashboard
function M.toggle()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    M.close()
  else
    M.create_window()
  end
end

-- User command
vim.api.nvim_create_user_command("OpenHWYDashboard", function()
  M.toggle()
end, { desc = "Toggle OpenHWY Dashboard" })

-- Keymap
vim.keymap.set("n", "<leader>oO", function() M.toggle() end, { desc = "OpenHWY Dashboard" })

return M

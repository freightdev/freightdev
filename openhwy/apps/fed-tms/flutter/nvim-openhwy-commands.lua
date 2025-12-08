-- File: ~/.config/nvim/lua/openhwy/commands.lua
-- OpenHWY remote command execution

local M = {}

-- Systems configuration
M.systems = {
  workbox = { hostname = "localhost", local = true },
  helpbox = { hostname = "helpbox" },
  hostbox = { hostname = "hostbox" },
  callbox = { hostname = "callbox" },
  safebox = { hostname = "safebox" },
}

-- Execute command on a system
function M.exec_on_system(system, command)
  local sys = M.systems[system]
  if not sys then
    vim.notify("Unknown system: " .. system, vim.log.levels.ERROR)
    return
  end

  local cmd
  if sys.local then
    cmd = command
  else
    cmd = string.format("ssh admin@%s '%s'", sys.hostname, command)
  end

  -- Execute in terminal split
  vim.cmd("split")
  vim.cmd("terminal " .. cmd)
  vim.cmd("startinsert")
end

-- Execute command on all systems
function M.exec_on_all(command)
  for name, sys in pairs(M.systems) do
    vim.notify("Executing on " .. name .. "...", vim.log.levels.INFO)
    M.exec_on_system(name, command)
  end
end

-- Launch agent on a system
function M.launch_agent(system, agent_config, agent_script)
  local cmd = string.format(
    "cd ~/agents && moon-env %s %s",
    agent_config or "agent.toml",
    agent_script or "agent.lua"
  )
  M.exec_on_system(system, cmd)
end

-- Kill agent on a system
function M.kill_agent(system, agent_name)
  local cmd = string.format("pkill -f 'moon-env.*%s'", agent_name)
  M.exec_on_system(system, cmd)
end

-- Get system status
function M.get_status(system)
  local cmd = "openhwy status"
  M.exec_on_system(system, cmd)
end

-- Sync files to a system
function M.sync_to_system(system, local_path, remote_path)
  local sys = M.systems[system]
  if not sys then
    vim.notify("Unknown system: " .. system, vim.log.levels.ERROR)
    return
  end

  if sys.local then
    vim.notify("Already on local system", vim.log.levels.WARN)
    return
  end

  local cmd = string.format(
    "rsync -avz %s admin@%s:%s",
    local_path,
    sys.hostname,
    remote_path
  )

  vim.cmd("split")
  vim.cmd("terminal " .. cmd)
end

-- Deploy OpenHWY to a system
function M.deploy_to_system(system)
  M.sync_to_system(system, "~/bin/moon-env", "~/bin/")
  M.sync_to_system(system, "~/bin/openhwy", "~/bin/")
  M.exec_on_system(system, "chmod +x ~/bin/*")
end

-- User commands
vim.api.nvim_create_user_command("OpenHWYExec", function(opts)
  local args = vim.split(opts.args, " ", { trimempty = true })
  local system = args[1]
  local command = table.concat(args, " ", 2)
  M.exec_on_system(system, command)
end, {
  nargs = "+",
  complete = function()
    return vim.tbl_keys(M.systems)
  end,
  desc = "Execute command on OpenHWY system",
})

vim.api.nvim_create_user_command("OpenHWYExecAll", function(opts)
  M.exec_on_all(opts.args)
end, {
  nargs = "+",
  desc = "Execute command on all OpenHWY systems",
})

vim.api.nvim_create_user_command("OpenHWYLaunch", function(opts)
  local args = vim.split(opts.args, " ", { trimempty = true })
  M.launch_agent(args[1], args[2], args[3])
end, {
  nargs = "+",
  complete = function()
    return vim.tbl_keys(M.systems)
  end,
  desc = "Launch agent on system",
})

vim.api.nvim_create_user_command("OpenHWYKill", function(opts)
  local args = vim.split(opts.args, " ", { trimempty = true })
  M.kill_agent(args[1], args[2])
end, {
  nargs = "+",
  desc = "Kill agent on system",
})

vim.api.nvim_create_user_command("OpenHWYStatus", function(opts)
  if opts.args == "" then
    M.get_status("workbox")
  else
    M.get_status(opts.args)
  end
end, {
  nargs = "?",
  complete = function()
    return vim.tbl_keys(M.systems)
  end,
  desc = "Get OpenHWY system status",
})

vim.api.nvim_create_user_command("OpenHWYDeploy", function(opts)
  if opts.args == "all" then
    for name, _ in pairs(M.systems) do
      if name ~= "workbox" then
        M.deploy_to_system(name)
      end
    end
  else
    M.deploy_to_system(opts.args)
  end
end, {
  nargs = "?",
  complete = function()
    local systems = vim.tbl_keys(M.systems)
    table.insert(systems, "all")
    return systems
  end,
  desc = "Deploy OpenHWY to system",
})

-- Keymaps for quick access
vim.keymap.set("n", "<leader>ox", ":OpenHWYExec ", { desc = "OpenHWY Execute" })
vim.keymap.set("n", "<leader>oX", ":OpenHWYExecAll ", { desc = "OpenHWY Execute All" })
vim.keymap.set("n", "<leader>ol", ":OpenHWYLaunch ", { desc = "OpenHWY Launch Agent" })
vim.keymap.set("n", "<leader>ok", ":OpenHWYKill ", { desc = "OpenHWY Kill Agent" })
vim.keymap.set("n", "<leader>od", ":OpenHWYDeploy ", { desc = "OpenHWY Deploy" })

return M

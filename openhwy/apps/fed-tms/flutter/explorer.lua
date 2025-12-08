-- File: ~/.config/nvim/lua/plugins/explorer.lua
-- File tree and terminal setup

return {
  -- Neo-tree (file explorer on left)
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      close_if_last_window = false,
      popup_border_style = "rounded",
      enable_git_status = true,
      enable_diagnostics = true,
      filesystem = {
        follow_current_file = {
          enabled = true,
        },
        use_libuv_file_watcher = true,
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = false,
          hide_by_name = {
            "node_modules",
            "target",
            ".git",
          },
        },
      },
      window = {
        position = "left",
        width = 35,
        mappings = {
          ["<space>"] = "none",
          ["o"] = "open",
        },
      },
      default_component_configs = {
        indent = {
          with_expanders = true,
          expander_collapsed = "",
          expander_expanded = "",
        },
      },
    },
  },

  -- Toggleterm (terminal at bottom)
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
      open_mapping = [[<c-\>]],
      hide_numbers = true,
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      persist_size = true,
      persist_mode = true,
      direction = "horizontal",
      close_on_exit = true,
      shell = vim.o.shell,
      float_opts = {
        border = "curved",
      },
    },
  },

  -- Ranger integration
  {
    "kelly-lin/ranger.nvim",
    config = function()
      require("ranger-nvim").setup({
        replace_netrw = true,
        enable_cmds = false,
        keybinds = {
          ["ov"] = require("ranger-nvim").OPEN_MODE.vsplit,
          ["oh"] = require("ranger-nvim").OPEN_MODE.split,
          ["ot"] = require("ranger-nvim").OPEN_MODE.tabedit,
          ["or"] = require("ranger-nvim").OPEN_MODE.rifle,
        },
        ui = {
          border = "rounded",
          height = 0.8,
          width = 0.8,
          x = 0.5,
          y = 0.5,
        },
      })
      
      vim.keymap.set("n", "<leader>r", require("ranger-nvim").open, { desc = "Open Ranger" })
    end,
  },
}

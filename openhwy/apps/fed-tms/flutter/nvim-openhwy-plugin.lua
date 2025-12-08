-- File: ~/.config/nvim/lua/plugins/openhwy.lua
-- OpenHWY Control Center for Neovim

return {
  -- Terminal integration
  {
    "akinsho/toggleterm.nvim",
    config = function()
      require("toggleterm").setup({
        size = function(term)
          if term.direction == "horizontal" then
            return 15
          elseif term.direction == "vertical" then
            return vim.o.columns * 0.4
          end
        end,
        open_mapping = [[<c-\>]],
        direction = "horizontal",
        float_opts = {
          border = "curved",
        },
      })

      -- OpenHWY terminal commands
      local Terminal = require("toggleterm.terminal").Terminal

      -- Marketeer Dashboard
      local marketeer = Terminal:new({
        cmd = "marketeer-dashboard ~/marketeer-workbox.toml",
        direction = "float",
        hidden = true,
        on_open = function(term)
          vim.cmd("startinsert!")
        end,
      })

      function _MARKETEER_TOGGLE()
        marketeer:toggle()
      end

      -- Agent Builder
      local agent_builder = Terminal:new({
        cmd = "agent-builder",
        direction = "float",
        hidden = true,
      })

      function _AGENT_BUILDER_TOGGLE()
        agent_builder:toggle()
      end

      -- System Status
      local status = Terminal:new({
        cmd = "openhwy status",
        direction = "horizontal",
        hidden = true,
        close_on_exit = false,
      })

      function _STATUS_TOGGLE()
        status:toggle()
      end

      -- SSH terminals for each box
      local helpbox = Terminal:new({
        cmd = "ssh admin@helpbox",
        direction = "float",
        hidden = true,
      })

      function _SSH_HELPBOX()
        helpbox:toggle()
      end

      local hostbox = Terminal:new({
        cmd = "ssh admin@hostbox",
        direction = "float",
        hidden = true,
      })

      function _SSH_HOSTBOX()
        hostbox:toggle()
      end

      local callbox = Terminal:new({
        cmd = "ssh admin@callbox",
        direction = "float",
        hidden = true,
      })

      function _SSH_CALLBOX()
        callbox:toggle()
      end

      local safebox = Terminal:new({
        cmd = "ssh admin@safebox",
        direction = "float",
        hidden = true,
      })

      function _SSH_SAFEBOX()
        safebox:toggle()
      end

      -- Keymaps
      vim.keymap.set("n", "<leader>om", "<cmd>lua _MARKETEER_TOGGLE()<CR>", { desc = "OpenHWY Marketeer" })
      vim.keymap.set("n", "<leader>oa", "<cmd>lua _AGENT_BUILDER_TOGGLE()<CR>", { desc = "OpenHWY Agent Builder" })
      vim.keymap.set("n", "<leader>os", "<cmd>lua _STATUS_TOGGLE()<CR>", { desc = "OpenHWY Status" })
      vim.keymap.set("n", "<leader>oh", "<cmd>lua _SSH_HELPBOX()<CR>", { desc = "SSH helpbox" })
      vim.keymap.set("n", "<leader>oH", "<cmd>lua _SSH_HOSTBOX()<CR>", { desc = "SSH hostbox" })
      vim.keymap.set("n", "<leader>oc", "<cmd>lua _SSH_CALLBOX()<CR>", { desc = "SSH callbox" })
      vim.keymap.set("n", "<leader>oS", "<cmd>lua _SSH_SAFEBOX()<CR>", { desc = "SSH safebox" })
    end,
  },

  -- Which-key menu for OpenHWY
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      opts.defaults = opts.defaults or {}
      opts.defaults["<leader>o"] = { name = "+openhwy" }
    end,
  },

  -- Telescope integration for quick actions
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      {
        "<leader>oo",
        function()
          require("telescope.builtin").find_files({
            cwd = "~/WORKSPACE/openhwy",
            prompt_title = "OpenHWY Files",
          })
        end,
        desc = "OpenHWY Files",
      },
      {
        "<leader>og",
        function()
          require("telescope.builtin").live_grep({
            cwd = "~/WORKSPACE/openhwy",
            prompt_title = "OpenHWY Grep",
          })
        end,
        desc = "OpenHWY Grep",
      },
    },
  },

  -- Custom OpenHWY commands plugin
  {
    dir = "~/.config/nvim/lua/openhwy",
    name = "openhwy-commands",
    config = function()
      require("openhwy.commands")
    end,
  },
}

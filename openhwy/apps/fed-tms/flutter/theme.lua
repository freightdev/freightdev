-- File: ~/.config/nvim/lua/plugins/theme.lua
-- Theme and UI configuration

return {
  -- Catppuccin theme (dark, modern, like Cursor)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha", -- latte, frappe, macchiato, mocha
      transparent_background = false,
      term_colors = true,
      dim_inactive = {
        enabled = false,
        shade = "dark",
        percentage = 0.15,
      },
      styles = {
        comments = { "italic" },
        conditionals = { "italic" },
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
      },
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        telescope = true,
        notify = true,
        mini = true,
        neotree = true,
        treesitter = true,
        which_key = true,
      },
    },
  },

  -- Configure LazyVim to use catppuccin
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },

  -- Lualine (statusline)
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme = "catppuccin",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        globalstatus = true,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { "filename" },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },

  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      indent = {
        char = "│",
        tab_char = "│",
      },
      scope = { enabled = false },
      exclude = {
        filetypes = {
          "help",
          "alpha",
          "dashboard",
          "neo-tree",
          "Trouble",
          "lazy",
          "mason",
          "notify",
          "toggleterm",
          "lazyterm",
        },
      },
    },
  },

  -- Noice (better UI for messages, cmdline, popupmenu)
  {
    "folke/noice.nvim",
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
      },
    },
  },

  -- Dashboard (startup screen)
  {
    "goolord/alpha-nvim",
    opts = function()
      local dashboard = require("alpha.themes.dashboard")
      dashboard.section.header.val = {
        "                                                     ",
        "  ██████  ██▓███  ▓█████  ███▄    █  ██░ ██ █     █░▓██   ██▓",
        "▒██    ▒ ▓██░  ██▒▓█   ▀  ██ ▀█   █ ▓██░ ██▒▓█░ █ ░█░ ▒██  ██▒",
        "░ ▓██▄   ▓██░ ██▓▒▒███   ▓██  ▀█ ██▒▒██▀▀██░▒█░ █ ░█   ▒██ ██░",
        "  ▒   ██▒▒██▄█▓▒ ▒▒▓█  ▄ ▓██▒  ▐▌██▒░▓█ ░██ ░█░ █ ░█   ░ ▐██▓░",
        "▒██████▒▒▒██▒ ░  ░░▒████▒▒██░   ▓██░░▓█▒░██▓░░██▒██▓   ░ ██▒▓░",
        "▒ ▒▓▒ ▒ ░▒▓▒░ ░  ░░░ ▒░ ░░ ▒░   ▒ ▒  ▒ ░░▒░▒░ ▓░▒ ▒     ██▒▒▒ ",
        "░ ░▒  ░ ░░▒ ░      ░ ░  ░░ ░░   ░ ▒░ ▒ ░▒░ ░  ▒ ░ ░   ▓██ ░▒░ ",
        "░  ░  ░  ░░          ░      ░   ░ ░  ░  ░░ ░  ░   ░   ▒ ▒ ░░  ",
        "      ░              ░  ░         ░  ░  ░  ░    ░     ░ ░     ",
        "                                                       ░ ░     ",
        "                                                               ",
      }
      dashboard.section.buttons.val = {
        dashboard.button("f", " " .. " Find file", ":Telescope find_files <CR>"),
        dashboard.button("n", " " .. " New file", ":ene <BAR> startinsert <CR>"),
        dashboard.button("r", " " .. " Recent files", ":Telescope oldfiles <CR>"),
        dashboard.button("g", " " .. " Find text", ":Telescope live_grep <CR>"),
        dashboard.button("c", " " .. " Config", ":e $MYVIMRC <CR>"),
        dashboard.button("s", " " .. " Restore Session", [[:lua require("persistence").load() <cr>]]),
        dashboard.button("l", "󰒲 " .. " Lazy", ":Lazy<CR>"),
        dashboard.button("q", " " .. " Quit", ":qa<CR>"),
      }
      return dashboard
    end,
  },
}

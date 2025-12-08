-- File: ~/.config/nvim/lua/plugins/ai.lua
-- AI Integration via Ollama

return {
  -- Gen.nvim for AI code generation
  {
    "David-Kunz/gen.nvim",
    opts = {
      model = "codellama:13b", -- Change to your preferred model
      host = "localhost",
      port = "11434",
      display_mode = "split",
      show_prompt = true,
      show_model = true,
      no_auto_close = false,
      init = function(options)
        pcall(io.popen, "ollama serve > /dev/null 2>&1 &")
      end,
      command = function(options)
        return "curl --silent --no-buffer -X POST http://"
          .. options.host
          .. ":"
          .. options.port
          .. "/api/generate -d $body"
      end,
    },
    config = function(_, opts)
      require("gen").setup(opts)
      
      -- Custom prompts
      require("gen").prompts["Elaborate_Text"] = { prompt = "Elaborate the following text:\n$text" }
      require("gen").prompts["Fix_Code"] = { prompt = "Fix the following code:\n```$filetype\n$text\n```" }
      require("gen").prompts["Explain_Code"] = { prompt = "Explain the following code:\n```$filetype\n$text\n```" }
      require("gen").prompts["Optimize_Code"] = { prompt = "Optimize the following code:\n```$filetype\n$text\n```" }
      require("gen").prompts["Add_Comments"] = { prompt = "Add comments to the following code:\n```$filetype\n$text\n```" }
      require("gen").prompts["Refactor"] = { prompt = "Refactor the following code:\n```$filetype\n$text\n```" }
      require("gen").prompts["Generate_Tests"] = { prompt = "Generate tests for:\n```$filetype\n$text\n```" }
    end,
  },

  -- ChatGPT.nvim for conversational AI
  {
    "jackMort/ChatGPT.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("chatgpt").setup({
        api_host_cmd = "echo http://localhost:11434",
        api_key_cmd = "echo ''",
        openai_params = {
          model = "codellama:13b",
          frequency_penalty = 0,
          presence_penalty = 0,
          max_tokens = 4096,
          temperature = 0.2,
          top_p = 0.1,
          n = 1,
        },
      })
    end,
  },

  -- Copilot alternative (works with any model via Ollama)
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = {
          enabled = true,
          auto_trigger = true,
          keymap = {
            accept = "<Tab>",
            accept_word = false,
            accept_line = false,
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<C-]>",
          },
        },
        panel = { enabled = false },
        filetypes = {
          yaml = true,
          markdown = true,
          help = false,
          gitcommit = true,
          gitrebase = false,
          ["."] = true,
        },
      })
    end,
  },

  -- Codeium (free alternative, works out of the box)
  {
    "Exafunction/codeium.vim",
    event = "BufEnter",
    config = function()
      vim.g.codeium_disable_bindings = 1
      vim.keymap.set("i", "<C-g>", function()
        return vim.fn["codeium#Accept"]()
      end, { expr = true })
      vim.keymap.set("i", "<C-x>", function()
        return vim.fn["codeium#Clear"]()
      end, { expr = true })
      vim.keymap.set("i", "<C-]>", function()
        return vim.fn["codeium#CycleCompletions"](1)
      end, { expr = true })
      vim.keymap.set("i", "<C-[>", function()
        return vim.fn["codeium#CycleCompletions"](-1)
      end, { expr = true })
    end,
  },
}

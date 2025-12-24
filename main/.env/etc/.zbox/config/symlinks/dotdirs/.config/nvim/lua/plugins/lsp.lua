-- Location: ~/.config/nvim/lua/plugins/lsp.lua
-- LSP configuration: language servers for Rust, Go, Python, JS/TS, Bash, JSON/YAML
return {
  -- Mason (LSP installer)
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })
    end,
  },
  -- Mason-lspconfig bridge
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "rust_analyzer",
          "gopls",
          "pyright",
          "ts_ls",
          "svelte",
          "bashls",
          "jsonls",
          "yamlls",
          "lua_ls",
        },
      })
    end,
  },
  -- LSP configuration
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      
      -- LSP keymaps on attach
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local bufnr = args.buf
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr, desc = "Go to definition" })
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = bufnr, desc = "Go to declaration" })
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { buffer = bufnr, desc = "Go to implementation" })
          vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = bufnr, desc = "Show references" })
          vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Hover documentation" })
          vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename symbol" })
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code action" })
          vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { buffer = bufnr, desc = "Show diagnostics" })
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { buffer = bufnr, desc = "Previous diagnostic" })
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { buffer = bufnr, desc = "Next diagnostic" })
        end,
      })

      -- Define LSP configs
      vim.lsp.config['*'] = {
        capabilities = capabilities,
      }

      -- Rust
      vim.lsp.config.rust_analyzer = {
        cmd = { 'rust-analyzer' },
        root_markers = { 'Cargo.toml' },
        capabilities = capabilities,
        settings = {
          ["rust-analyzer"] = {
            checkOnSave = {
              command = "clippy",
            },
          },
        },
      }

      -- Go
      vim.lsp.config.gopls = {
        cmd = { 'gopls' },
        root_markers = { 'go.mod', 'go.work' },
        capabilities = capabilities,
      }

      -- Python
      vim.lsp.config.pyright = {
        cmd = { 'pyright-langserver', '--stdio' },
        root_markers = { 'pyproject.toml', 'setup.py', 'requirements.txt' },
        capabilities = capabilities,
      }

      -- TypeScript/JavaScript
      vim.lsp.config.ts_ls = {
        cmd = { 'typescript-language-server', '--stdio' },
        root_markers = { 'package.json', 'tsconfig.json' },
        capabilities = capabilities,
      }

      -- Svelte
      vim.lsp.config.svelte = {
        cmd = { 'svelteserver', '--stdio' },
        root_markers = { 'svelte.config.js' },
        capabilities = capabilities,
      }

      -- Bash
      vim.lsp.config.bashls = {
        cmd = { 'bash-language-server', 'start' },
        root_markers = { '.git' },
        capabilities = capabilities,
      }

      -- JSON
      vim.lsp.config.jsonls = {
        cmd = { 'vscode-json-language-server', '--stdio' },
        root_markers = { 'package.json', '.git' },
        capabilities = capabilities,
      }

      -- YAML
      vim.lsp.config.yamlls = {
        cmd = { 'yaml-language-server', '--stdio' },
        root_markers = { '.git' },
        capabilities = capabilities,
      }

      -- Lua
      vim.lsp.config.lua_ls = {
        cmd = { 'lua-language-server' },
        root_markers = { '.luarc.json', '.git' },
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
            },
          },
        },
      }

      -- Enable all LSP servers
      vim.lsp.enable({
        'rust_analyzer',
        'gopls',
        'pyright',
        'ts_ls',
        'svelte',
        'bashls',
        'jsonls',
        'yamlls',
        'lua_ls',
      })
    end,
  },
}

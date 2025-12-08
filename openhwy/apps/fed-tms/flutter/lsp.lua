-- File: ~/.config/nvim/lua/plugins/lsp.lua
-- LSP configuration for all your languages

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Rust
        rust_analyzer = {
          settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                runBuildScripts = true,
              },
              checkOnSave = {
                allFeatures = true,
                command = "clippy",
                extraArgs = { "--no-deps" },
              },
              procMacro = {
                enable = true,
                ignored = {
                  ["async-trait"] = { "async_trait" },
                  ["napi-derive"] = { "napi" },
                  ["async-recursion"] = { "async_recursion" },
                },
              },
            },
          },
        },

        -- Go
        gopls = {
          settings = {
            gopls = {
              gofumpt = true,
              codelenses = {
                gc_details = false,
                generate = true,
                regenerate_cgo = true,
                run_govulncheck = true,
                test = true,
                tidy = true,
                upgrade_dependency = true,
                vendor = true,
              },
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
              analyses = {
                fieldalignment = true,
                nilness = true,
                unusedparams = true,
                unusedwrite = true,
                useany = true,
              },
              usePlaceholders = true,
              completeUnimported = true,
              staticcheck = true,
              directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
              semanticTokens = true,
            },
          },
        },

        -- Lua
        lua_ls = {
          settings = {
            Lua = {
              workspace = {
                checkThirdParty = false,
              },
              completion = {
                callSnippet = "Replace",
              },
              telemetry = {
                enable = false,
              },
              hint = {
                enable = true,
              },
            },
          },
        },

        -- Dart/Flutter
        dartls = {
          cmd = { "dart", "language-server", "--protocol=lsp" },
        },

        -- YAML
        yamlls = {
          settings = {
            yaml = {
              schemas = {
                ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
                ["https://json.schemastore.org/kustomization.json"] = "kustomization.yaml",
              },
            },
          },
        },

        -- JSON
        jsonls = {},

        -- Bash
        bashls = {},

        -- Python
        pyright = {},

        -- HTML/CSS
        html = {},
        cssls = {},

        -- TypeScript (for Next.js)
        tsserver = {},
      },
    },
  },

  -- Mason (LSP installer)
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "rust-analyzer",
        "gopls",
        "lua-language-server",
        "yaml-language-server",
        "json-lsp",
        "bash-language-server",
        "pyright",
        "typescript-language-server",
        "html-lsp",
        "css-lsp",
        "prettier",
        "stylua",
        "shfmt",
      },
    },
  },

  -- Formatting
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        rust = { "rustfmt" },
        go = { "gofumpt", "goimports" },
        lua = { "stylua" },
        python = { "black", "isort" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        sh = { "shfmt" },
      },
    },
  },

  -- Rust tools
  {
    "simrat39/rust-tools.nvim",
    ft = "rust",
    opts = {
      server = {
        on_attach = function(_, bufnr)
          vim.keymap.set("n", "<leader>cR", "<cmd>RustRunnables<cr>", { buffer = bufnr, desc = "Rust Runnables" })
          vim.keymap.set("n", "<leader>cD", "<cmd>RustDebuggables<cr>", { buffer = bufnr, desc = "Rust Debuggables" })
        end,
      },
    },
  },
}

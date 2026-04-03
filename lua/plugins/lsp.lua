return {
  "neovim/nvim-lspconfig",
  lazy = false,
  deps = {
    "aznhe21/actions-preview.nvim",
    { "j-hui/fidget.nvim", opts = {} },
  },
  config = function()
    vim.lsp.config("*", {
      capabilities = {
        textDocument = {
          semanticTokens = {
            multilineTokenSupport = false,
          },
        },
      },
    })

    ---@type table<string, vim.lsp.Config>
    local servers = {
      -- Lua
      lua_ls = {
        settings = {
          Lua = {
            version = "LuaJIT",
            workspace = {
              library = { vim.env.VIMRUNTIME },
              checkThirdParty = false,
            },
            codeLens = { enable = true },
            hint = { enable = true },
          },
        },
      },
      -- Rust
      rust_analyzer = {},
      -- OCaml
      ocamllsp = {},
      -- C
      clangd = {
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--completion-style=detailed",
          "--header-insertion=iwyu",
          "--experimental-modules-support",
        },
        init_options = {
          clangdFileStatus = true,
          usePlaceholders = true,
          completeUnimported = true,
          semanticHighlighting = true,
        },
        capabilities = { offsetEncoding = { "utf-16" } }, -- fix clang formatter warnings
      },
      -- Go
      gopls = {
        cmd = { "gopls", "serve" },
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
              shadow = true,
            },
            staticcheck = true,
          },
        },
      },
      -- Zig
      zls = {},
      -- Odin
      ols = {},
      -- Erlang
      elp = {},
      -- Nim
      nim_langserver = {},
      -- TypeScript
      ts_ls = {
        single_file_support = true,
        settings = {
          typescript = {
            inlayHints = {
              includeInlayEnumMemberValueHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all';
              includeInlayParameterNameHintsWhenArgumentMatchesName = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayVariableTypeHints = false,
            },
          },
        },
      },
    }

    for server, config in pairs(servers) do
      vim.lsp.config(server, config)
      vim.lsp.enable(server)
    end

    -- Dont write logs to file, it gets massive over time
    --vim.lsp.log.set_level(vim.log.levels.OFF)

    vim.diagnostic.config({
      underline = true,
      virtual_text = {
        current_line = true,
        spacing = 4,
        source = "if_many",
        prefix = "●",
        enabled = true, -- extra field for toggling
      },
      update_in_insert = false,
      severity_sort = true,
    })

    local function jump(count, severity)
      return function()
        vim.diagnostic.jump({
          count = count,
          severity = severity,
        })
      end
    end

    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(ev)
        --local client = vim.lsp.get_client_by_id(ev.data.client_id)
        jvim.nmap({
          -- Movement
          { "gd", vim.lsp.buf.definition, "Goto Definition" },
          { "gr", "<cmd>Telescope lsp_references<cr>", "Goto References" },
          { "gD", vim.lsp.buf.declaration, "Goto Declaration" },
          { "gtd", vim.lsp.buf.type_definition, "Type Definition" },
          { "gI", vim.lsp.buf.implementation, "Goto Implementation" },
          { "]d", jump(1), "Goto Next Diagnostic" },
          { "[d", jump(-1), "Goto Previous Diagnostic" },
          { "]e", jump(1, vim.diagnostic.severity.ERROR), "Goto Next Error" },
          { "[e", jump(-1, vim.diagnostic.severity.ERROR), "Goto Previous Error" },
          { "]w", jump(1, vim.diagnostic.severity.WARN), "Goto Next Warning" },
          { "[w", jump(-1, vim.diagnostic.severity.WARN), "Goto Previous Warning" },

          -- Diagnostics
          --{ "<leader>di", JVim.diagnostic.open(), "Diagnostics" },
          --{ "<leader>de", JVim.diagnostic.open("ERROR"), "Diagnostics (error)" },
          --{ "<leader>dc", JVim.diagnostic.open_buf(), "Diagnostics (current buf)" },

          -- Actions
          { "K", vim.lsp.buf.hover, "Hover Documentation" },
          { "<leader>k", vim.diagnostic.open_float, "Open diagnostic float" },
          { "<leader>ca", require("actions-preview").code_actions, "Code Action" },
          { "<leader>rn", vim.lsp.buf.rename, "Rename" },
        }, function(opts)
          ---@diagnostic disable-next-line: inject-field
          opts.buffer = ev.buf
          opts.desc = "LSP " .. opts.desc
        end)
      end,
    })
  end,
}

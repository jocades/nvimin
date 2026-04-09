return {
  "neovim/nvim-lspconfig",
  deps = {
    { "j-hui/fidget.nvim", opts = {} },
    { "mason-org/mason.nvim", opts = {} },
    "aznhe21/actions-preview.nvim",
  },
  config = function()
    ---@type table<string, vim.lsp.Config>
    local servers = {
      -- Lua
      lua_ls = {
        settings = {
          Lua = {
            version = "LuaJIT",
            workspace = { checkThirdParty = false },
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
      tsgo = {},
    }

    for server, config in pairs(servers) do
      vim.lsp.config(server, config)
      vim.lsp.enable(server)
    end

    -- Dont write logs to file, it gets massive over time
    vim.lsp.log.set_level(vim.log.levels.WARN)

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

    local severity = vim.diagnostic.severity

    jvim.nmap({
      { "<leader>di", jvim.diagnostic.open(), "Diagnostics" },
      { "<leader>de", jvim.diagnostic.open(severity.ERROR), "Diagnostics (error)" },
      { "<leader>dc", jvim.diagnostic.open_buf(), "Diagnostics (current buf)" },
    })

    local function jump(count, sev)
      return function()
        vim.diagnostic.jump({ count = count, severity = sev })
      end
    end

    ---@param client vim.lsp.Client
    ---@param buf integer
    local function on_attach(client, buf)
      -- stylua: ignore
      local keys = {
        -- Movement
        { "gd", vim.lsp.buf.definition, "Goto Definition" },
        { "gr", function() Snacks.picker.lsp_references() end, "Goto References" },
        { "gD", vim.lsp.buf.declaration, "Goto Declaration" },
        { "gtd", vim.lsp.buf.type_definition, "Type Definition" },
        { "gI", vim.lsp.buf.implementation, "Goto Implementation" },
        { "]d", jump(1), "Goto Next Diagnostic" },
        { "[d", jump(-1), "Goto Previous Diagnostic" },
        { "]i", jump(1, severity.INFO), "Goto Next Info" },
        { "[i", jump(-1, severity.INFO), "Goto Previous Info" },
        { "]e", jump(1, severity.ERROR), "Goto Next Error" },
        { "[e", jump(-1, severity.ERROR), "Goto Previous Error" },
        { "]w", jump(1, severity.WARN), "Goto Next Warning" },
        { "[w", jump(-1, severity.WARN), "Goto Previous Warning" },

        -- Actions
        { "K", vim.lsp.buf.hover, "Hover Documentation" },
        { "<leader>k", vim.diagnostic.open_float, "Open diagnostic float" },
        { "<leader>rn", vim.lsp.buf.rename, "Rename" },
        { "<leader>ca", function() require("actions-preview").code_actions() end, "Code Action" },
      }

      if client:supports_method("textDocument/inlayHint", buf) then
        table.insert(keys, { "<leader>th", jvim.toggle.inlay_hints, "Toggle inlay hints" })
      end

      if client:supports_method("textDocument/codeLens", buf) then
        table.insert(keys, {
          "<leader>tcl",
          function()
            jvim.toggle({
              name = "code lens",
              get = vim.lsp.codelens.is_enabled,
              set = function(state)
                vim.lsp.codelens.enable(state)
                if state then
                  jvim.map("n", "<leader>clr", vim.lsp.codelens.run, "Run code lens")
                else
                  vim.keymap.del("n", "<leader>clr")
                end
              end,
            })
          end,
          "Toggle codelens",
        })
      end

      if client:supports_method("textDocument/documentHighlight", buf) then
        local augroup = vim.api.nvim_create_augroup("jvim-lsp-doc-hl", { clear = false })
        table.insert(keys, {
          "<leader>tdh",
          function()
            jvim.toggle({
              name = "document highlight",
              get = vim.g.lsp_doc_hl_enabled,
              set = function(state)
                vim.g.lsp_doc_hl_enabled = state
                if state then
                  vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                    buffer = buf,
                    group = augroup,
                    callback = vim.lsp.buf.document_highlight,
                  })
                  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                    buffer = buf,
                    group = augroup,
                    callback = vim.lsp.buf.clear_references,
                  })
                else
                  vim.lsp.buf.clear_references()
                  vim.api.nvim_clear_autocmds({ group = augroup })
                end
              end,
            })
          end,
          "Toggle document highlights",
        })

        vim.api.nvim_create_autocmd("LspDetach", {
          group = vim.api.nvim_create_augroup("jvim-lsp-detach", { clear = true }),
          callback = function(ev)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = ev.buf })
          end,
        })
      end

      return keys
    end

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("jvim-lsp-attach", { clear = true }),
      callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id) ---@cast client -?
        local keys = on_attach(client, ev.buf)
        jvim.nmap(keys, function(opts)
          opts.buf = ev.buf
          opts.desc = "LSP " .. (opts.desc or "")
        end)
      end,
    })
  end,
}

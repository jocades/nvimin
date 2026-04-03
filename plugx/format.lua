jvim.lazy_event("BufWritePre", function()
  vim.pack.add({ gh("stevearc/conform.nvim") })

  require("conform").setup({
    format_on_save = function(buf)
      if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then
        return
      end
      return { timeout_ms = 500, lsp_format = "fallback" }
    end,

    formatters_by_ft = {
      lua = { "stylua" },
      rust = { "rustfmt" },
    },
  })

  local fmt = require("conform").formatters

  fmt.stylua = {
    prepend_args = {
      "--config-path",
      vim.fs.joinpath(vim.fn.stdpath("config"), "stylua.toml"),
    },
  }
end)

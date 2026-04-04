return {
  "stevearc/conform.nvim",
  opts = {
    format_on_save = function(buf)
      if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then
        return
      end
      return { timeout_ms = 500, lsp_format = "fallback" }
    end,
    formatters_by_ft = {
      lua = { "stylua" },
      rust = { "rustfmt" },
      c = { "clang_format" },
      sh = { "shfmt" },
      python = { "ruff_format" },
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      json = { "prettier" },
      html = { "prettier" },
      css = { "prettier" },
      go = { "gofmt" },
      asm = { "asmfmt" },
      ocaml = { "ocamlformat" },
    },
  },
  config = function(opts)
    require("conform").setup(opts)
    local fmt = require("conform").formatters

    fmt.stylua = {
      prepend_args = { "--config-path", vim.fs.joinpath(vim.fn.stdpath("config"), "stylua.toml") },
    }

    fmt.rustfmt = { prepend_args = { "--config", "max_width=100" } }
    fmt.shfmt = { prepend_args = { "-i", "4" } }

    if vim.uv.fs_stat(vim.fs.joinpath(vim.uv.cwd(), ".prettierrc")) then
      fmt.prettier = { prepend_args = { "--semi=false", "--print-width=100", "--end-of-line=lf" } }
    end
  end,
}

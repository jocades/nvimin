_G.jvim = require("jvim.util")

local M = {}

local function colorscheme()
  vim.pack.add({
    -- Completely destroyed rust highlighting after this commit
    { src = "https://github.com/catppuccin/nvim", name = "catppuccin", version = "1bf0701" },
  })

  require("catppuccin").setup({
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    no_italic = true,
    show_end_of_buffer = true,
    integrations = {
      native_lsp = {
        enabled = true,
        underlines = {
          errors = { "undercurl" },
          hints = { "undercurl" },
          warnings = { "undercurl" },
          information = { "undercurl" },
        },
      },
    },
  })

  vim.cmd.colorscheme("catppuccin-mocha")
end

function M.setup()
  vim.loader.enable()

  require("config.options")
  require("config.autocmds")

  colorscheme()

  require("jvim.load").setup()

  for mode, mappings in pairs(require("config.keymaps")) do
    for k, t in pairs(mappings) do
      jvim.map(mode, k, t[1], t[2])
    end
  end
end

return M

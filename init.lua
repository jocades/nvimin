vim.loader.enable()
require("vim._core.ui2").enable({})

_G.jvim = require("jvim.util")

require("config.options")
require("config.autocmds")
require("config.colorscheme")

require("jvim.load").setup({ dev = "~/.config/nvim/dev" })

for mode, mappings in pairs(require("config.keymaps")) do
  for k, t in pairs(mappings) do
    jvim.map(mode, k, t[1], t[2])
  end
end

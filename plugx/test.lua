--vim.pack.del({"nvim-autopairs"})
--vim.pack.add({
--  "https://github.com/windwp/nvim-autopairs",
--}, {
--  load = function(plug)
--    --vim.print(plug)
--    vim.cmd.packadd(plug.spec.name)
--    require("nvim-autopairs").setup()
--  end,
--})

vim.pack.add({ "https://github.com/folke/trouble.nvim" })

--  {
--    "folke/trouble.nvim",
--    opts = { auto_preview = false },
--  },

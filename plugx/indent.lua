vim.pack.add({
  gh("lukas-reineke/indent-blankline.nvim"),
}, {
  load = function(plug)
    vim.print(plug)
    vim.cmd.packadd(plug.spec.name)
  end,
})

vim.print(vim.pack.get({ "indent-blankline.nvim" }))

return {
  "bar",
  opts = { wtf = true },
  config = function(opts)
    vim.print({ load_bar = opts })
  end,
}

vim.pack.add({
  { src = gh("saghen/blink.cmp"), version = vim.version.range("1") },
}, {
  load = function(plug)
    jvim.lazy_event("InsertEnter", function()
      print("load cmp")
      vim.print(plug)
      vim.cmd.packadd(plug.spec.name)
      require("blink.cmp").setup()
    end)
  end,
})

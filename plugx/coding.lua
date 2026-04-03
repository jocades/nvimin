jvim.lazy_event("InsertEnter", function()
  vim.pack.add({
    gh("windwp/nvim-autopairs"),
    gh("kylechui/nvim-surround"),
    { src = gh("saghen/blink.cmp"), version = vim.version.range("1") },
  })

  require("nvim-autopairs").setup()
  require("nvim-surround").setup()

  require("blink.cmp").setup({
    keymap = {
      preset = "default",
      ["<C-j>"] = { "select_next" },
      ["<C-k>"] = { "select_prev" },
      ["<C-u>"] = { "select_and_accept" },
    },
  })
end)

jvim.lazy_event("BufReadPost", function()
  vim.pack.add({
    gh("lukas-reineke/indent-blankline.nvim"),
    gh("numToStr/Comment.nvim"),
  })

  require("ibl").setup({
    indent = {
      char = "│",
      tab_char = "│",
    },
    scope = { show_start = false, show_end = false },
    exclude = {
      filetypes = {
        "help",
        "alpha",
        "dashboard",
        "neo-tree",
        "Trouble",
        "trouble",
        "lazy",
        "mason",
        "notify",
      },
    },
  })

  require("Comment").setup({
    toggler = {
      line = "<leader>cc",
      block = "<leader>cb",
    },
  })
end)

vim.pack.add({ gh("folke/trouble.nvim") })
require("trouble").setup({ auto_preview = false })

---@type jvim.Spec[]
return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  {
    "kylechui/nvim-surround",
    event = "InsertEnter",
    opts = {},
  },

  {
    "saghen/blink.cmp",
    version = vim.version.range("1"),
    event = "InsertEnter",
    opts = {
      keymap = {
        preset = "default",
        ["<C-j>"] = { "select_next" },
        ["<C-k>"] = { "select_prev" },
        ["<C-u>"] = { "select_and_accept" },
      },
    },
  },

  {
    "folke/trouble.nvim",
    opts = { auto_preview = false },
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "BufReadPost",
    opts = {
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
    },
  },
}

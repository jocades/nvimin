return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  {
    "nvim-mini/mini.surround",
    event = "InsertEnter",
    opts = {},
  },

  {
    "saghen/blink.cmp",
    version = vim.version.range("1"),
    event = "InsertEnter",
    ---@module "blink.cmp"
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = "default",
        ["<C-j>"] = { "select_next" },
        ["<C-k>"] = { "select_prev" },
        ["<C-u>"] = { "select_and_accept" },
      },
      sources = {
        default = { "lsp", "buffer", "snippets", "path" },
        per_filetype = { lua = { inherit_defaults = true, "lazydev" } },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
        },
      },
      signature = { enabled = true },
    },
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

  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "snacks.nvim", words = { "Snacks" } },
      },
    },
  },
}

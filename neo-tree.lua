return {
  "nvim-neo-tree/neo-tree.nvim",
  version = vim.version.range("3"),
  deps = {
    { "nvim-lua/plenary.nvim", lazy = true },
    { "MunifTanjim/nui.nvim", lazy = true },
    { "nvim-tree/nvim-web-devicons", lazy = true },
  },
  keys = {
    { "<C-n>", "<cmd>Neotree toggle<cr>" },
  },
  opts = {
    close_if_last_window = true,
    window = {
      position = "left",
      width = 30,
      mappings = {
        ["<space>"] = "none",
        ["l"] = "open",
        ["P"] = { "toggle_preview", config = { use_float = false } },
      },
    },
    filesystem = {
      bind_to_cwd = false,
      use_libuv_file_watcher = true,
      hijack_netrw_behavior = "open_current",
      filtered_items = {
        always_show = { ".gitignore", ".cargo" },
      },
    },
    source_selector = {
      winbar = false,
      statusline = false,
    },
    git_status = {
      symbols = {
        -- Change type
        added = "✚",
        deleted = "✖",
        modified = "",
        renamed = "󰁕",
        -- Status type
        untracked = "",
        ignored = "",
        unstaged = "󰄱",
        staged = "",
        conflict = "",
      },
    },
  },
}

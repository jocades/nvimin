jvim.lazy_cmd("Neotree", function()
  vim.pack.add({
    {
      src = gh("nvim-neo-tree/neo-tree.nvim"),
      version = vim.version.range("3"),
    },
    gh("nvim-lua/plenary.nvim"),
    gh("MunifTanjim/nui.nvim"),
    gh("nvim-tree/nvim-web-devicons"),
  })

  require("neo-tree").setup({
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
  })
end)

jvim.nmap({
  { "<C-n>", "<cmd>Neotree toggle<cr>", "Toggle Neotree" },
})

--vim.api.nvim_create_user_command("Neotree", function(args)
--  vim.api.nvim_del_user_command("Neotree")
--  vim.api.nvim_cmd({ cmd = "Neotree", args = args.fargs }, {})
--end, { nargs = "*" })

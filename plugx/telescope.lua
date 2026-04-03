jvim.lazy_cmd("Telescope", function()
  vim.pack.add({
    gh("nvim-telescope/telescope.nvim"),
    gh("nvim-lua/plenary.nvim"),
  })

  local actions = require("telescope.actions")
  require("telescope").setup({
    defaults = {
      mappings = {
        i = {
          ["<C-u>"] = false,
          ["<C-d>"] = false,
          ["<C-j>"] = actions.move_selection_next,
          ["<C-k>"] = actions.move_selection_previous,
          ["<C-n>"] = actions.cycle_history_next,
          ["<C-p>"] = actions.cycle_history_prev,
          ["<C-l>"] = require("trouble.sources.telescope").open,
        },
      },
      prompt_prefix = " ",
      selection_caret = " ",
      path_display = { "smart" }, -- truncate, shorten, absolute, tail, smart
      file_ignore_patterns = { ".git/", "node_modules" },
      layout_strategy = "horizontal",
      layout_config = { prompt_position = "top" },
      selection_strategy = "reset",
      sorting_strategy = "ascending",
      scroll_strategy = "cycle",
      color_devicons = true,
    },
  })
end)

jvim.nmap({
  { "<C-p>", "<cmd>Telescope find_files<cr>", "Find files" },
  { "<leader>ts", "<cmd>Telescope builtin<cr>", "Telescope builtins" },
  { "<leader>fg", "<cmd>Telescope git_files<cr>", "Find git files" },
  { "<leader>fw", "<cmd>Telescope live_grep<cr>", "Find word (grep)" },
  { "<leader>fc", "<cmd>Telescope grep_string<cr>", "Find current word" },
  { "<leader>fb", "<cmd>Telescope buffers<cr>", "Find buffers" },
  { "<leader>fh", "<cmd>Telescope help_tags<cr>", "Find Help" },
  { "<leader>fm", "<cmd>Telescope man_pages<cr>", "Find man pages" },
  { "<leader>fk", "<cmd>Telescope keymaps<cr>", "Find keymaps" },
  { "<leader>:", "<cmd>Telescope command_history<cr>", "Command history" },
  { "<leader>?", "<cmd>Telescope oldfiles<cr>", "Find recently opened files" },
})

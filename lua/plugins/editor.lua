return {
  {
    "nvim-mini/mini.files",
    lazy = false,
    deps = { "nvim-mini/mini.icons" },
    opts = {},
    -- stylua: ignore
    keys = {
      { "<leader>e", function() require("mini.files").open(vim.api.nvim_buf_get_name(0)) end },
      { "<leader>E", function() require("mini.files").open() end },
    },
  },

  {
    "folke/snacks.nvim",
    lazy = false,
    opts = {
      picker = {},
    },
    -- stylua: ignore
    keys = {
      { "<C-p>", function() Snacks.picker.files() end, "Find help" },
      { "<leader>fp", function() Snacks.picker.pickers() end, "Find pickers" },
      { "<leader>fw", function() Snacks.picker.grep() end, "Find word (grep)" },
      { "<leader>fc", function() Snacks.picker.grep_word() end, "Find word under cursor (grep)" },
      { "<leader>fl", function() Snacks.picker.lines() end, "Find lines" },
      { "<leader>fh", function() Snacks.picker.help() end, "Find help" },
      { "<leader>fm", function() Snacks.picker.man() end, "Find man" },
      { "<leader>fk", function() Snacks.picker.keymaps() end, "Find keys" },
    },
  },

  -- {
  --   "nvim-telescope/telescope.nvim",
  --   deps = { { "nvim-lua/plenary.nvim", lazy = true } },
  --   cmd = { "Telescope" },
  --   keys = {
  --     { "<C-p>", "<cmd>Telescope find_files<cr>", "Find files" },
  --     { "<leader>ts", "<cmd>Telescope builtin<cr>", "Telescope builtins" },
  --     { "<leader>fg", "<cmd>Telescope git_files<cr>", "Find git files" },
  --     { "<leader>fw", "<cmd>Telescope live_grep<cr>", "Find word (grep)" },
  --     { "<leader>fc", "<cmd>Telescope grep_string<cr>", "Find current word" },
  --     { "<leader>fb", "<cmd>Telescope buffers<cr>", "Find buffers" },
  --     { "<leader>fh", "<cmd>Telescope help_tags<cr>", "Find Help" },
  --     { "<leader>fm", "<cmd>Telescope man_pages<cr>", "Find man pages" },
  --     { "<leader>fk", "<cmd>Telescope keymaps<cr>", "Find keymaps" },
  --     { "<leader>:", "<cmd>Telescope command_history<cr>", "Command history" },
  --     { "<leader>?", "<cmd>Telescope oldfiles<cr>", "Find recently opened files" },
  --   },
  --   config = function()
  --     local actions = require("telescope.actions")
  --     require("telescope").setup({
  --       defaults = {
  --         mappings = {
  --           i = {
  --             ["<C-u>"] = false,
  --             ["<C-d>"] = false,
  --             ["<C-j>"] = actions.move_selection_next,
  --             ["<C-k>"] = actions.move_selection_previous,
  --             ["<C-n>"] = actions.cycle_history_next,
  --             ["<C-p>"] = actions.cycle_history_prev,
  --             ["<C-l>"] = function()
  --               require("trouble.sources.telescope").open()
  --             end,
  --           },
  --         },
  --         prompt_prefix = " ",
  --         selection_caret = " ",
  --         path_display = { "smart" }, -- truncate, shorten, absolute, tail, smart
  --         file_ignore_patterns = { ".git/", "node_modules" },
  --         layout_strategy = "horizontal",
  --         layout_config = { prompt_position = "top" },
  --         selection_strategy = "reset",
  --         sorting_strategy = "ascending",
  --         scroll_strategy = "cycle",
  --         color_devicons = true,
  --       },
  --     })
  --   end,
  -- },

  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
    },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>" },
    },
  },

  {
    "jocades/bbuf",
    dev = true,
    -- stylua: ignore
    keys = {
      { "<leader>x", function() require("bbuf").remove() end },
      { "<leader>nf", function() require("bbuf").new() end },
      { "<leader>bd", function() require("bbuf").close_all() end },
    },
  },
}

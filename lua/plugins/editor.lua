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
    "folke/trouble.nvim",
    opts = { auto_preview = false },
  },

  {
    "folke/snacks.nvim",
    lazy = false,
    opts = {
      picker = {},
      scratch = {},
    },
    -- stylua: ignore
    keys = {
      { "<C-p>", function() Snacks.picker.files() end, "Find files" },
      { "<leader>fp", function() Snacks.picker.pickers() end, "Find pickers" },
      { "<leader>fw", function() Snacks.picker.grep() end, "Find word (grep)" },
      { "<leader>fc", function() Snacks.picker.grep_word() end, "Find word under cursor (grep)" },
      { "<leader>fl", function() Snacks.picker.lines() end, "Find lines" },
      { "<leader>fb", function() Snacks.picker.buffers() end, "Find buffers" },
      { "<leader>fh", function() Snacks.picker.help() end, "Find help" },
      { "<leader>fm", function() Snacks.picker.man() end, "Find man" },
      { "<leader>fk", function() Snacks.picker.keymaps() end, "Find keys" },

      { "<leader>sb", function() Snacks.scratch() end, "Open scratch buffer" },
      { "<leader>fs", function() Snacks.scratch.select() end, "Search scratch buffer" },
    },
  },

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

  {
    "jocades/laser",
    dev = true,
    opts = {},
    keys = function()
      -- stylua: ignore start
      local keys = {
        { "<leader>h", function() require("laser").toggle() end, "Laser toggle" },
        { "<leader>a", function() require("laser").add() end, "Laser add" },
      }
      for i = 1, 5 do
        table.insert(keys, {
          "<leader>" .. i,
          function() require("laser").select(i) end,
          desc = "Laser file " .. i,
        })
      end
      return keys
    end,
  },
}

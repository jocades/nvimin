return {
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

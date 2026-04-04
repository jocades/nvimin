return {
  "christoomey/vim-tmux-navigator",

  {
    "jocades/bbuf",
    dev = true,
    keys = {
      {
        "<leader>x",
        function()
          require("bbuf").remove()
        end,
      },
      {
        "<leader>nf",
        function()
          require("bbuf").new()
        end,
      },
      {
        "<leader>bd",
        function()
          require("bbuf").close_all()
        end,
      },
    },
  },
}

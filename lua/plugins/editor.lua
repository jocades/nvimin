return {
  {
    "nvim-mini/mini.files",
    lazy = false,
    deps = { { "nvim-mini/mini.icons", opts = {} } },
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
      picker = {
        layout = { preset = "default", layout = { backdrop = false } },
      },
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
    "lewis6991/gitsigns.nvim",
    opts = function()
      local signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      }

      return {
        signs = signs,
        signs_staged = signs,
        on_attach = function(buf)
          local gs = require("gitsigns")
          jvim.nmap({
            {
              "]h",
              function()
                if vim.wo.diff then
                  vim.cmd.normal({ "]c", bang = true })
                else
                  gs.nav_hunk("next")
                end
              end,
              "Next hunk",
            },
            {
              "[h",
              function()
                if vim.wo.diff then
                  vim.cmd.normal({ "[c", bang = true })
                else
                  gs.nav_hunk("prev")
                end
              end,
              "Prev hunk",
            },
            { -- Diff current file in new tab
              "<leader>gd",
              function()
                vim.cmd.tabnew(vim.api.nvim_buf_get_name(0))
                gs.diffthis("~")
              end,
              "diff",
            },
            { "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline" },
            { "<leader>ghP", gs.preview_hunk, "Preview Hunk" },
            {
              "<leader>gb",
              function()
                gs.blame_line({ full = true })
              end,
              "Blame Line",
            },
            { "<leader>gB", gs.blame, "Blame Buffer" },
            {
              "<leader>tg",
              function()
                jvim.toggle({
                  name = "git signs",
                  get = function()
                    return require("gitsigns.config").config.signcolumn
                  end,
                  set = function(state)
                    gs.toggle_signs(state)
                  end,
                })
              end,
              "Toggle signs",
            },
          }, function(opts)
            opts.buf = buf
            opts.desc = "Git " .. opts.desc
          end)
        end,
      }
    end,
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
          function() require("laser").jump(i) end,
          "Laser file " .. i,
        })
      end
      return keys
    end,
  },
}

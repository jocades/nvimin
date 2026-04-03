return {
  n = {
    --["<leader>x"] = { JVim.buf.remove, "Close buffer" },
    ["<leader>X"] = { vim.cmd.tabc, "Close tab" },
    ["<leader>y"] = { "<cmd>%y+<cr>", "Copy buffer" },
    ["<leader>v"] = { "gg0vG$", "Select buffer" },
    ["<leader>so"] = { "<cmd>w | so %<cr>", "Save and source buffer" },
    --["<leader>nf"] = { JVim.buf.new, "New buffer" },

    -- Windows
    ["<leader>ss"] = { vim.cmd.vsplit, "Vertical split" },
    ["<leader>sh"] = { vim.cmd.split, "Horizontal split" },
    ["<leader>z"] = { vim.cmd.close, "Close window" },

    -- Centralization
    ["<C-d>"] = { "<C-d>zz" },
    ["<C-u>"] = { "<C-u>zz" },
  },

  i = {
    -- Exit insert mode
    ["jk"] = { "<ESC>", { nowait = true } },

    -- Navigate horizontally
    ["<C-h>"] = { "<Left>" },
    ["<C-l>"] = { "<Right>" },
  },

  v = {
    -- Stay in indent mode
    ["<"] = { "<gv" },
    [">"] = { ">gv" },
  },
}

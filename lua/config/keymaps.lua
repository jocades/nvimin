return {
  n = {
    ["<leader>X"] = { vim.cmd.tabc, "Close tab" },
    ["<leader>y"] = { "<cmd>%y+<cr>", "Copy buffer" },
    ["<leader>v"] = { "gg0vG$", "Select buffer" },
    ["<leader>so"] = { "<cmd>w | so %<cr>", "Save and source buffer" },

    -- Windows
    ["<leader>ss"] = { vim.cmd.vsplit, "Vertical split" },
    ["<leader>sh"] = { vim.cmd.split, "Horizontal split" },
    ["<leader>z"] = { vim.cmd.close, "Close window" },

    -- Toggle
    ["<Esc>"] = { jvim.toggle.hlsearch, "Toggle hlsearch" },
    ["<leader>td"] = { jvim.toggle.diagnostics, "Toggle diagnostics" },
    ["<leader>th"] = { jvim.toggle.inlay_hints, "Toggle inlay hints" },
    ["<leader>tf"] = { jvim.toggle.autoformat, "Toggle autoformat" },

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

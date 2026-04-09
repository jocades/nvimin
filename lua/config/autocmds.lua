jvim.maybe_lazy(function()
  -- Highlight on yank
  vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
      vim.highlight.on_yank()
    end,
  })

  -- Go to last loc when opening a buffer
  vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
      vim.o.formatoptions = "jqlnt" -- dont add comment on new line

      local mark = vim.api.nvim_buf_get_mark(0, '"')
      local lcount = vim.api.nvim_buf_line_count(0)
      if mark[1] > 0 and mark[1] <= lcount then
        pcall(vim.api.nvim_win_set_cursor, 0, mark)
      end
    end,
  })

  -- Check if we need to reload the file when it changed
  vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
    callback = function()
      if vim.o.buftype ~= "nofile" then
        vim.cmd.checktime()
      end
    end,
  })

  -- Set wrap and spell for some filetypes
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "text", "plaintext", "gitcommit" },
    callback = function()
      vim.opt_local.wrap = true
      vim.opt_local.spell = true
    end,
  })

  -- Show `:help` and `:Man` vertically
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "help", "man" },
    callback = function()
      vim.cmd.wincmd("L")
    end,
  })

  -- Close some filetypes with <q>
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "help", "man", "qf" },
    callback = function(ev)
      vim.bo[ev.buf].buflisted = false
      vim.keymap.set("n", "q", vim.cmd.q, { buffer = ev.buf, silent = true })
    end,
  })
end)

package.loaded["laser.win"] = nil
local Window = require("laser.win")

local function dbg(msg)
  Snacks.notifier.notify(msg)
end

local win = Window.new({
  keys = {
    {
      "q",
      function(self)
        --vim.print({ win = self.win, buf = self.buf })
        self:hide()
      end,
    },
  },

  on_buf = function(self)
    dbg("on_buf(" .. self.buf .. ")")
    self:on("BufUnload", function()
      dbg("BufUnload")
    end)
    self:on("BufWipeout", function()
      dbg("BufWipeout")
    end)
    self:on("BufDelete", function()
      dbg("BufDelete")
    end)
    self:on("BufHidden", function()
      -- if self:buf_valid() then
      --   vim.api.nvim_buf_delete(self.buf, { force = true })
      -- end
      dbg("BufHidden")
    end)
    self:set_lines({ "foo" })
  end,

  on_win = function(self)
    --dbg("on_win()")
  end,
})

vim.keymap.set("n", "<leader>h", function()
  win:toggle()
end)

local w = Snacks.win.new({
  show = false,
  keys = {
    ["<Esc>"] = function(self)
      self:hide()
    end,
  },
  on_buf = function(self)
    dbg("on_buf()")
  end,
  backdrop = false,
})

vim.keymap.set("n", "<leader>w", function()
  w:show()
end)

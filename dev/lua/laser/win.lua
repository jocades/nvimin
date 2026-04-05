---@class laser.Window
---@field id number
---@field buf number
---@field win number
---@field opts laser.win.Opts
local Window = {}
Window.__index = Window

---@class laser.win.Key
---@field [1] string
---@field [2] string|fun(self: laser.Window)
---@field mode? string

---@class laser.win.Opts
---@field on_buf? fun(self: laser.Window)
---@field on_win? fun(self: laser.Window)
---@field keys? laser.win.Key[]
---@field augroup? integer

local id = 0

---@param opts? laser.win.Opts
function Window.new(opts)
  id = id + 1
  local self = setmetatable({}, Window)
  self.id = id
  self.buf = -1
  self.win = -1
  self.opts = opts or {}
  return self
end

function Window:buf_valid()
  return vim.api.nvim_buf_is_valid(self.buf)
end

function Window:win_valid()
  return vim.api.nvim_win_is_valid(self.win)
end

function Window:valid()
  return self:buf_valid() and self:win_valid()
end

---Optional call
local function ocall(f, ...)
  if vim.is_callable(f) then
    f(...)
  end
end

function Window:_wrap(f)
  return function()
    f(self)
  end
end

function Window:show()
  if not self.opts.augroup then
    self.opts.augroup = vim.api.nvim_create_augroup("laser.window#" .. self.id, { clear = true })
  end

  if not self:buf_valid() then
    self.buf = vim.api.nvim_create_buf(false, true)
    if self.opts.keys then
      for _, map in ipairs(self.opts.keys) do
        local rhs = vim.is_callable(map[2]) and self:_wrap(map[2]) or map[2]
        vim.keymap.set(map.mode or "n", map[1], rhs, { buf = self.buf })
      end
    end

    ---Buf delete is not triggered on scratch buffers, this is a workaround to catch the
    ---self:buf_valid() and set keymaps etc..
    self:on("BufUnload", function()
      --vim.api.nvim_buf_delete(self.buf, { unload = true })
    end)

    ocall(self.opts.on_buf, self)
  end

  if not self:win_valid() then
    local maxw = vim.o.columns
    local maxh = vim.o.lines
    local w = math.floor(maxw * 0.35)
    local h = math.floor(maxh * 0.25)
    self.win = vim.api.nvim_open_win(self.buf, true, {
      title = "Laser",
      title_pos = "center",
      relative = "editor",
      width = w,
      height = h,
      row = math.floor((maxh - h) / 2 - 1),
      col = math.floor((maxw - w) / 2),
    })
    ocall(self.opts.on_win, self)
  end
end

function Window:hide()
  vim.api.nvim_win_close(self.win, true)
  --vim.api.nvim_buf_delete(self.buf, { force = true })
end

function Window:toggle()
  if self:valid() then
    self:hide()
  else
    self:show()
  end
end

function Window:focus()
  if self:win_valid() then
    vim.api.nvim_set_current_win(self.win)
  end
end

function Window:map(lhs, rhs)
  vim.keymap.set("n", lhs, rhs, { buf = self.buf })
end

---@param ev vim.api.keyset.events|vim.api.keyset.events[]
---@param cb fun()
function Window:on(ev, cb)
  vim.api.nvim_create_autocmd(ev, {
    callback = cb,
    buffer = self.buf,
    group = self.opts.augroup,
  })
end

---@return number line, number column
function Window:get_cursor()
  local cursor = vim.api.nvim_win_get_cursor(self.win)
  return cursor[1], cursor[2]
end

---@param ln number
---@param col number
function Window:set_cursor(ln, col)
  vim.api.nvim_win_set_cursor(self.win, { ln, col })
end

---@param from? number
---@param to? number
function Window:get_lines(from, to)
  return vim.api.nvim_buf_get_lines(self.buf, from or 0, to or -1, false)
end

---@param lines string[]
---@param from? number
---@param to? number
function Window:set_lines(lines, from, to)
  vim.api.nvim_buf_set_lines(self.buf, from or 0, to or -1, false, lines)
end

return Window

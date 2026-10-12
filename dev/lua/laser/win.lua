---@class laser.Window
---@field id number
---@field buf number
---@field win number
---@field opts laser.win.Opts
---@field _win_opts vim.api.keyset.win_config
local Window = {}
Window.__index = Window

---@class laser.win.Opts: vim.api.keyset.win_config
---@field enter? boolean
---@field on_buf? fun(self: laser.Window)
---@field on_win? fun(self: laser.Window)
---@field keys? table<string, fun(self: laser.Window)|laser.win.Key>,
---@field augroup? integer

---@class laser.win.Key
---@field [1] string|fun(self: laser.Window)
---@field mode? string

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

function Window:_open_buf()
  self.buf = vim.api.nvim_create_buf(false, true)

  if self.opts.keys then
    for lhs, map in pairs(self.opts.keys) do
      local rhs, mode
      if type(map) == "table" then
        rhs = vim.is_callable(map[1]) and self:_wrap(map[1]) or map[1]
        mode = map.mode or "n"
      elseif vim.is_callable(map) then
        rhs = self:_wrap(map)
        mode = "n"
      else
        jvim.error(("Invalid rhs for `%s`"):format(lhs))
      end

      if rhs and mode then
        vim.keymap.set(mode, lhs, rhs, { buf = self.buf })
      end
    end
  end

  ocall(self.opts.on_buf, self)
end

function Window:_open_win()
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

function Window:show()
  if not self.opts.augroup then
    self.opts.augroup = vim.api.nvim_create_augroup("laser.window#" .. self.id, { clear = true })
  end

  if not self:buf_valid() then
    self:_open_buf()
  end

  if not self:win_valid() then
    self:_open_win()
  end
end

function Window:hide()
  vim.api.nvim_win_close(self.win, true)
end

function Window:close()
  vim.api.nvim_buf_delete(self.buf, { force = true })
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
  if self:buf_valid() then
    vim.keymap.set("n", lhs, rhs, { buf = self.buf })
  end
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

local M = {}

local augroup = vim.api.nvim_create_augroup("laser.window", { clear = true })

---@class laser.Window
---@field buf? number
---@field win? number
---@field opts laser.win.Opts
local Window = {}
Window.__index = Window

---Optional call
local function ocall(f, ...)
  if vim.is_callable(f) then
    f(...)
  end
end

---@class laser.win.Key
---@field [1] string
---@field [2] string|fun(self: laser.Window)
---@field mode? string

---@class laser.win.Opts
---@field on_buf? fun(self: laser.Window)
---@field on_win? fun(self: laser.Window)
---@field keys? laser.win.Key[]

---@param opts? laser.win.Opts
function Window.new(opts)
  local self = setmetatable({}, Window)
  self.opts = opts or {}
  return self
end

function Window:buf_valid()
  return self.buf and vim.api.nvim_buf_is_valid(self.buf)
end

function Window:win_valid()
  return self.win and vim.api.nvim_win_is_valid(self.win)
end

function Window:valid()
  return self:buf_valid() and self:win_valid()
end

function Window:_wrap(f)
  return function()
    f(self)
  end
end

function Window:show()
  if not self:buf_valid() then
    self.buf = vim.api.nvim_create_buf(false, true)
    if self.opts.keys then
      for _, map in ipairs(self.opts.keys) do
        local rhs = vim.is_callable(map[2]) and self:_wrap(map[2]) or map[2]
        vim.keymap.set(map.mode or "n", map[1], rhs, { buf = self.buf })
      end
    end
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
  self.win = nil
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
    group = augroup,
    buffer = self.buf,
    callback = cb,
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

---@class laser.Config
local config = {
  root = vim.fs.joinpath(vim.fn.stdpath("data"), "laser"),
  save_on_toggle = false,
}

---Merge two tables recursively, modifying `dst`.
---@param dst table
---@param src table
local function merge(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" then
      if not dst[k] then
        dst[k] = {}
      end
      merge(dst[k], v)
    else
      dst[k] = v
    end
  end
end

---@type {win: laser.Window, cwd: string, path: string, items: string[], fresh: boolean}
local state = {}

local function write()
  Snacks.notifier.notify("write")
  vim.fn.writefile(state.items, state.path)
end

function M.load()
  state.cwd = assert(vim.uv.cwd())
  local hash = vim.fn.sha256(state.cwd):sub(1, 8)
  state.path = vim.fs.joinpath(config.root, hash)
  if not vim.uv.fs_stat(state.path) then
    state.items = {}
    state.fresh = true
  else
    state.items = vim.fn.readfile(state.path)
    state.fresh = false
  end
end

function M.store()
  if not vim.tbl_isempty(state.items) then
    write()
    state.fresh = false
  else
    if not state.fresh then
      write()
    end
  end
end

local function create_window()
  state.win = Window.new({
    keys = {
      {
        "q",
        function(self)
          self:hide()
        end,
      },
      {
        "<cr>",
        function(self)
          local index = self:get_cursor()
          M.select(index)
        end,
      },
      {
        "<C-v>",
        function(self)
          local index = self:get_cursor()
          M.select(index, "vertical")
        end,
      },
      {
        "<C-h>",
        function(self)
          local index = self:get_cursor()
          M.select(index, "horizontal")
        end,
      },
    },

    on_buf = function(self)
      self:on("BufLeave", function()
        local clean = {}
        for _, line in ipairs(self:get_lines()) do
          if vim.trim(line) ~= "" then
            table.insert(clean, line)
          end
        end

        state.items = clean

        if config.save_on_toggle then
          M.store()
        end

        self:hide()
      end)
    end,

    on_win = function(self)
      self:set_lines(state.items)
    end,
  })
end

function M.toggle()
  state.win:toggle()
end

function M.add()
  local rel = vim.fs.relpath(state.cwd, vim.api.nvim_buf_get_name(0))
  if rel and rel ~= "." then
    table.insert(state.items, rel)
  end
end

---@param index number
---@param mode? "vertical"|"horizontal"
function M.select(index, mode)
  local relpath = state.items[index]
  if not relpath then
    return
  end
  if mode == "vertical" then
    vim.cmd.vsplit(relpath)
  elseif mode == "horizontal" then
    vim.cmd.split(relpath)
  else
    vim.cmd.edit(relpath)
  end
end

---@param opts? laser.Config
function M.setup(opts)
  if opts then
    merge(config, opts)
  end
  vim.fn.mkdir(config.root, "p")
  create_window()
  M.load()
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = augroup,
    callback = function()
      M.store()
    end,
  })
end

vim.keymap.set("n", "<leader>h", function()
  M.toggle()
end)

vim.keymap.set("n", "<leader>H", function()
  M.add()
end)

for i = 1, 5 do
  vim.keymap.set("n", "<leader>" .. i, function()
    M.select(i)
  end)
end

M.setup()

return M

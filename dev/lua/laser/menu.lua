local M = {}

---@class fisher.Config
---@root = string
local config = {}

local augroup = vim.api.nvim_create_augroup("fisher", { clear = true })

---@class fisher.List
---@field path string
---@field items string[]
local List = {}

---@param path string
---@param items? string[]
function List.new(path, items)
  local self = setmetatable({}, { __index = List })
  self.path = path
  self.items = items or {}
  return self
end

---@class fisher.Menu
---@field buf? number
---@field win? number
---@field items? fisher.List
local Menu = {}

function Menu.new()
  local self = setmetatable({}, { __index = Menu })
  self.buf = nil
  self.win = nil
  self.list = nil
  return self
end

function Menu:buf_valid()
  return self.buf and vim.api.nvim_buf_is_valid(self.buf)
end

function Menu:win_valid()
  return self.win and vim.api.nvim_win_is_valid(self.win)
end

function Menu:valid()
  return self:buf_valid() and self:win_valid()
end

function Menu:show()
  if not self:buf_valid() then
    self.buf = vim.api.nvim_create_buf(false, true)
    self:map("q", function()
      self:hide()
    end)

    self:on("BufLeave", function()
      --print(self:win_valid())
    end)
  end

  if self.list then
    self:set_lines(self.list.items)
  end

  if not self:win_valid() then
    local maxw = vim.o.columns
    local maxh = vim.o.lines
    local w = math.floor(maxw * 0.35)
    local h = math.floor(maxh * 0.25)

    self.win = vim.api.nvim_open_win(self.buf, true, {
      title = "Fisher",
      title_pos = "center",
      relative = "editor",
      width = w,
      height = h,
      row = math.floor((maxh - h) / 2 - 1),
      col = math.floor((maxw - w) / 2),
    })
  end
end

string.isempty = function(s)
  return vim.trim(s) == ""
end

function Menu:sync()
  if not self.list then
    return
  end
  local clean = {}
  for _, line in ipairs(self:get_lines()) do
    if not line:isempty() then
      table.insert(clean, line)
    end
  end
  self.list.items = clean
  vim.fn.writefile(clean, self.list.path)
end

function Menu:hide()
  self:sync()
  vim.api.nvim_win_close(self.win, true)
  self.win = nil
end

function Menu:toggle()
  if self:valid() then
    self:hide()
  else
    self:show()
  end
end

function Menu:map(lhs, rhs)
  vim.keymap.set("n", lhs, rhs, { buf = self.buf })
end

---@param ev vim.api.keyset.events|vim.api.keyset.events[]
---@param cb fun()
function Menu:on(ev, cb)
  vim.api.nvim_create_autocmd(ev, {
    group = augroup,
    buffer = self.buf,
    callback = cb,
  })
end

---@param from? number
---@param to? number
function Menu:get_lines(from, to)
  return vim.api.nvim_buf_get_lines(self.buf, from or 0, to or -1, false)
end

---@param lines string[]
---@param from? number
---@param to? number
function Menu:set_lines(lines, from, to)
  vim.api.nvim_buf_set_lines(self.buf, from or 0, to or -1, false, lines)
end

---@return number line, number column
function Menu:get_cursor()
  local cursor = vim.api.nvim_win_get_cursor(self.win)
  return cursor[1], cursor[2]
end

---@param ln number
---@param col number
function Menu:set_cursor(ln, col)
  vim.api.nvim_win_set_cursor(self.win, { ln, col })
end

function Menu:focus()
  if self:win_valid() then
    vim.api.nvim_set_current_win(self.win)
  end
end

function Menu:add()
  if not self.list then
    local name = vim.fn.sha256(assert(vim.uv.cwd()))
    local path = vim.fs.joinpath(config.root, name)
    if not vim.uv.fs_stat(path) then
      self.list = List.new(path)
    else
      local items = vim.fn.readfile(path)
      self.list = List.new(path, items)
    end
  end

  local rel = vim.fs.relpath(self.list.key, vim.api.nvim_buf_get_name(0))
  table.insert(self.list.items, rel)
end

local function select()
  local index = unpack(vim.api.nvim_win_get_cursor(0))
  print(index)
  local path = paths[index]

  if not path then
    jvim.warn("no path selected")
    return
  end

  vim.cmd.edit(path)
end

local menu = Menu.new()

function M.add()
  menu:add()
end

function M.setup()
  config.root = vim.fs.joinpath(vim.fn.stdpath("data"), "fisher")
  vim.fn.mkdir(config.root, "p")
end

vim.keymap.set("n", "<leader>l", function()
  menu:toggle()
end)

vim.keymap.set("n", "<leader>L", function()
  menu:add()
end)

M.setup()

return M

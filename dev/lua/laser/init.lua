local M = {}

---@class laser.Config
local config = {
  root = vim.fs.joinpath(vim.fn.stdpath("data"), "laser"),
  autowrite = false,
}

---An ordered set
---@class laser.Set
---@field vec string[]
---@field map table<string, number>
local Set = {}
Set.__index = Set

---@param items? string[]
function Set.new(items)
  local self = setmetatable({}, Set)
  self.vec = {}
  self.map = {}
  if items then
    for _, item in ipairs(items) do
      self:add(item)
    end
  end
  return self
end

---@param item string
function Set:add(item)
  if not self.map[item] then
    table.insert(self.vec, item)
    self.map[item] = #self.vec
  end
end

function Set:isempty()
  return next(self.vec) == nil
end

function Set:iter()
  return ipairs(self.vec)
end

---@type {win:laser.Window, root:string, file:string, items:laser.Set, fresh:boolean}
local state = {}

local function write()
  vim.fn.writefile(state.items.vec, state.file)
end

function M.load()
  local cwd = assert(vim.uv.cwd())
  state.root = vim.fs.root(cwd, ".git") or cwd

  local hash = vim.fn.sha256(state.root):sub(1, 8)
  state.file = vim.fs.joinpath(config.root, hash)

  if not vim.uv.fs_stat(state.file) then
    state.items = Set.new()
    state.fresh = true
  else
    state.items = Set.new(vim.fn.readfile(state.file))
    state.fresh = false
  end
end

function M.store()
  if not state.items:isempty() then
    write()
    state.fresh = false
  elseif not state.fresh then
    write()
  end
end

function M.add()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return
  end
  state.items:add(path)
end

---@param path string
---@param opts? {split: boolean, vsplit: boolean}
local function open(path, opts)
  local buf = vim.fn.bufadd(path)
  if not vim.api.nvim_buf_is_loaded(buf) then
    vim.fn.bufload(buf)
  end

  if opts then
    if opts.split then
      vim.cmd.split()
    elseif opts.vsplit then
      vim.cmd.vsplit()
    end
  end

  vim.api.nvim_set_current_buf(buf)
end

---@param index number
---@param opts? {split: boolean, vsplit: boolean}
function M.jump(index, opts)
  local path = state.items.vec[index]
  if not path then
    return
  end
  open(path, opts)
end

---@param line string
---@param opts? {split: boolean, vsplit: boolean}
function M.select(line, opts)
  line = vim.trim(line)
  if line == "" then
    return
  end
  local path = vim.fs.abspath(vim.fs.joinpath(state.root, line))
  open(path, opts)
end

function M.toggle()
  state.win:toggle()
end

function M.list()
  return state.items.vec
end

---@param lines string[]
local function sync(lines)
  local items = Set.new()

  for _, line in ipairs(lines) do
    line = vim.trim(line)
    if line ~= "" then
      local path = vim.fs.joinpath(state.root, line)
      items:add(path)
    end
  end

  state.items = items

  if config.autowrite then
    M.store()
  end
end

local function display()
  local lines = {}
  for _, path in state.items:iter() do
    local line = vim.fs.relpath(state.root, path)
    table.insert(lines, line)
  end
  return lines
end

local function create_window()
  state.win = require("laser.win").new({
    keys = {
      {
        "q",
        function(self)
          self:hide()
        end,
      },
      {
        "<cr>",
        function()
          M.select(vim.api.nvim_get_current_line())
        end,
      },
      {
        "<C-v>",
        function()
          M.select(vim.api.nvim_get_current_line(), { vsplit = true })
        end,
      },
      {
        "<C-h>",
        function()
          M.select(vim.api.nvim_get_current_line(), { split = true })
        end,
      },
    },

    on_buf = function(self)
      self:on("BufLeave", function()
        sync(self:get_lines())
        self:hide()
      end)
      vim.bo[self.buf].ft = "laser"
    end,

    on_win = function(self)
      self:set_lines(display())
      vim.wo[self.win].fillchars = "eob: "
    end,
  })
end

---@param opts? laser.Config
function M.setup(opts)
  jvim.merge(config, opts or {})
  vim.fn.mkdir(config.root, "p")

  M.load()
  create_window()

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      M.store()
    end,
  })
end

return M

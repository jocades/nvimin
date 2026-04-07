local M = {}

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

---@class laser.List
---@field vec string[]
---@field map table<string, number>
local List = {}
List.__index = List

function List.new()
  local self = setmetatable({}, List)
  self.vec = {}
  self.map = {}
  return self
end

---@param items string[]
function List.from(items)
  local self = List.new()
  for _, item in ipairs(items) do
    item = vim.trim(item)
    if item ~= "" and not self.map[item] then
      self:push(item)
    end
  end
  return self
end

---@param item string
function List:push(item)
  table.insert(self.vec, item)
  self.map[item] = #self.vec
end

function List:isempty()
  return next(self.vec) == nil
end

---@type {win: laser.Window, cwd: string, path: string, items: laser.List, fresh: boolean}
local state = {}

local function write()
  vim.fn.writefile(state.items.vec, state.path)
end

function M.load()
  state.cwd = assert(vim.uv.cwd())
  local hash = vim.fn.sha256(state.cwd):sub(1, 8)
  state.path = vim.fs.joinpath(config.root, hash)
  if not vim.uv.fs_stat(state.path) then
    state.items = List.new()
    state.fresh = true
  else
    state.items = List.from(vim.fn.readfile(state.path))
    state.fresh = false
  end
end

function M.store()
  if not state.items:isempty() then
    write()
    state.fresh = false
  else
    if not state.fresh then
      write()
    end
  end
end

function M.add()
  local item = vim.fs.relpath(state.cwd, vim.api.nvim_buf_get_name(0))
  if not item or item == "." or state.items.map[item] then
    return
  end
  state.items:push(item)
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
  local relpath = state.items.vec[index]
  if not relpath then
    return
  end
  open(relpath, opts)
end

---@param line string
---@param opts? {split: boolean, vsplit: boolean}
function M.select(line, opts)
  line = vim.trim(line)
  if line == "" then
    return
  end
  open(line, opts)
end

function M.toggle()
  state.win:toggle()
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
      vim.bo[self.buf].ft = "laser"

      self:on("BufLeave", function()
        state.items = List.from(self:get_lines())

        if config.save_on_toggle then
          M.store()
        end

        self:hide()
      end)
    end,

    on_win = function(self)
      self:set_lines(state.items.vec)
      vim.wo[self.win].fillchars = "eob: "
    end,
  })
end

---@param opts? laser.Config
function M.setup(opts)
  merge(config, opts or {})
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

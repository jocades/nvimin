---@class Laser
---@field win laser.Window
_G.Laser = setmetatable({}, {
  __index = function(t, k)
    t[k] = require("laser." .. k)
    return rawget(t, k)
  end,
})

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

---@type {win: laser.Window, cwd: string, path: string, items: string[], fresh: boolean}
local state = {}

local function write()
  vim.fn.writefile(state.items, state.path)
end

function M.toggle()
  state.win:toggle()
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

function M.add()
  local rel = vim.fs.relpath(state.cwd, vim.api.nvim_buf_get_name(0))
  if rel and rel ~= "." then
    table.insert(state.items, rel)
  end
end

---@param index number
---@param opts? {split: boolean, vsplit: boolean}
function M.select(index, opts)
  local relpath = state.items[index]
  if not relpath then
    return
  end

  local buf = vim.fn.bufadd(relpath)
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

local function create_window()
  state.win = Laser.win.new({
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
          M.select(index, { vsplit = true })
        end,
      },
      {
        "<C-h>",
        function(self)
          local index = self:get_cursor()
          M.select(index, { split = true })
        end,
      },
    },

    on_buf = function(self)
      vim.bo[self.buf].ft = "laser"

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

---@param opts? laser.Config
function M.setup(opts)
  merge(config, opts or {})
  vim.fn.mkdir(config.root, "p")
  create_window()
  M.load()
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      M.store()
    end,
  })
end

return M

---@class Laser
---@field win laser.Window
_G.Laser = setmetatable({}, {
  __index = function(t, k)
    t[k] = require("laser." .. k)
    return rawget(t, k)
  end,
})

local function dbg(msg)
  Snacks.notifier.notify(msg)
end

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
        dbg("BufLeave")
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
  if opts then
    merge(config, opts)
  end
  vim.fn.mkdir(config.root, "p")
  create_window()
  M.load()
  vim.api.nvim_create_autocmd("VimLeavePre", {
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

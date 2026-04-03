---@class jvim.Spec
---@field [1] string
---@field version? string|vim.VersionRange
---@field main? string
---@field lazy? boolean
---@field deps? (string|jvim.Spec)[]
---@field keys? jvim.KeySpec[]
---@field event? vim.api.keyset.events|vim.api.keyset.events[]
---@field cmd? string|string[]
---@field opts? table|fun():table?
---@field config? fun(opts: table)

---@class jvim.KeySpec
---@field [1] string
---@field [2] string|fun()
---@field desc? string
---@field mode? string|string[]

---@type table<string, jvim.Plugin>
local cache = {}

---@type vim.pack.Spec[]
local toadd = {}

---@class jvim.LoadState
---@field debug_file integer
local state = {}

---@class jvim.Plugin
---@field spec jvim.Spec
---@field loaded boolean
local Plugin = {}

function Plugin.new(spec)
  local self = setmetatable({}, { __index = Plugin })
  self.spec = spec
  self.loaded = false
  return self
end

---@param ev vim.api.keyset.events|vim.api.keyset.events[]
---@param cb fun()
local function on_event(ev, cb)
  vim.api.nvim_create_autocmd(ev, {
    once = true,
    callback = cb,
  })
end

---@param cmd string
---@param cb fun()
local function on_cmd(cmd, cb)
  vim.api.nvim_create_user_command(cmd, function(args)
    pcall(vim.api.nvim_del_user_command, cmd)
    cb()
    vim.api.nvim_cmd({ cmd = cmd, args = args.fargs }, {})
  end, { nargs = "*" })
end

---@param keymap jvim.KeySpec
---@param cb fun()
local function on_key(keymap, cb)
  local mode = keymap.mode or "n"
  local lhs = keymap[1]
  local rhs = keymap[2]
  vim.keymap.set(mode, lhs, function()
    vim.keymap.del(mode, lhs)
    cb()
    vim.keymap.set(mode, lhs, rhs)
    local feed = vim.api.nvim_replace_termcodes("<Ignore>" .. lhs, true, true, true)
    vim.api.nvim_feedkeys(feed, "i", false)
  end)
end

local function stem(name)
  return vim.fn.fnamemodify(name, ":t")
end

local function modname(name)
  return name:lower():gsub("^n?vim%-", ""):gsub("%.n?vim$", ""):gsub("[%.%-]lua", "")
end

function Plugin:setup()
  if self.spec.lazy ~= nil then
    if not self.spec.lazy then
      self:load()
    end
    return
  end

  local scheduled = false

  if self.spec.event then
    scheduled = true

    on_event(self.spec.event, function()
      self:load()
      --local message = ("Load on event(%s): %s\n"):format(self.spec.event, self.spec[1])
      --vim.uv.fs_write(state.debug_file, message, nil, function(err)
      --  if err then
      --    jvim.error(err)
      --  end
      --end)
    end)
  end

  if self.spec.cmd then
    scheduled = true
    local cmds = type(self.spec.cmd) == "string" and { self.spec.cmd } or self.spec.cmd
    ---@cast cmds string[]
    for _, cmd in ipairs(cmds) do
      on_cmd(cmd, function()
        self:load()
        --local message = ("Load on cmd(%s): %s\n"):format(cmd, self.spec[1])
        --vim.uv.fs_write(state.debug_file, message, nil, function(err)
        --  if err then
        --    jvim.error(err)
        --  end
        --end)
      end)
    end
  end

  if self.spec.keys then
    scheduled = true
    for _, keymap in ipairs(self.spec.keys) do
      on_key(keymap, function()
        self:load()
        --local message = ("Load on key(%s): %s\n"):format(keymap[1], self.spec[1])
        --vim.uv.fs_write(state.debug_file, message, nil, function(err)
        --  if err then
        --    jvim.error(err)
        --  end
        --end)
      end)
    end
  end

  if not scheduled then
    vim.api.nvim_create_autocmd("User", {
      once = true,
      pattern = "LazyLoad",
      callback = function()
        self:load()
        --local message = ("Load on event(LazyLoad): %s\n"):format(self.spec[1])
        --vim.uv.fs_write(state.debug_file, message, nil, function(err)
        --  if err then
        --    jvim.error(err)
        --  end
        --end)
      end,
    })
  end
end

---@return table?
function Plugin:opts()
  if type(self.spec.opts) == "function" then
    return self.spec.opts()
  end
  return self.spec.opts --[[@as table]]
end

function Plugin:load()
  if self.loaded then
    return
  end

  if self.spec.deps then
    for _, dep in ipairs(self.spec.deps) do
      cache[type(dep) == "string" and dep or dep[1]]:load()
    end
  end

  local name = stem(self.spec[1])
  vim.cmd.packadd(name)

  if self.spec.config then
    self.spec.config(self:opts() or {})
  elseif self.spec.opts then
    if not self.spec.main then
      self.spec.main = modname(name)
    end

    local ok, mod = pcall(require, self.spec.main)
    if not ok then
      ok, mod = pcall(require, name)
      if not ok then
        jvim.error(("Unable to resolve modname for `%s`"):format(self.spec[1]))
        return
      end
    end

    if mod.setup then
      mod.setup(self.spec.opts)
    end
  end

  self.loaded = true
end

---@param specs (string|jvim.Spec)[]
local function add(specs)
  for _, spec in ipairs(specs) do
    spec = type(spec) == "string" and { spec } or spec

    if spec.deps then
      add(spec.deps)
    end

    local name = spec[1]
    local existing = cache[name]

    if existing then
      existing.spec = vim.tbl_deep_extend("force", existing.spec, spec)
      return
    end

    cache[name] = Plugin.new(spec)
    table.insert(toadd, {
      src = "https://github.com/" .. name,
      version = spec.version,
    })
  end
end

---Recursive `WalkDir` depth first.
---@param path string
---@param cb fun(path: string): nil|boolean If `true` stop walking.
local function walkdir(path, cb)
  local handle = vim.uv.fs_scandir(path)
  while handle do
    local name, ty = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if ty == "file" then
      if cb(vim.fs.joinpath(path, name)) then
        break
      end
    elseif ty == "directory" then
      walkdir(vim.fs.joinpath(path, name), cb)
    end
  end
end

local M = {}

---@param path string
local function import(path)
  local mod = dofile(path)
  if not mod then
    return
  end
  if type(mod[1]) == "table" then -- spec list
    add(mod)
  else -- single spec
    add({ mod })
  end
end

---@param relpath? string
function M.setup(relpath)
  --state.debug_file = assert(vim.uv.fs_open("debug.txt", "w", tonumber("644", 8)))

  local root = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", relpath or "plugins")
  walkdir(root, import)

  vim.pack.add(toadd, { load = function() end })

  for _, plugin in pairs(cache) do
    plugin:setup()
  end

  on_event("UIEnter", function()
    vim.api.nvim_exec_autocmds("User", { pattern = "LazyLoad" })
  end)
end

return M

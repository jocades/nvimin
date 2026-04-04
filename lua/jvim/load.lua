local M = {}

---@class jvim.Spec
---@field [1] string
---@field version? string|vim.VersionRange
---@field main? string
---@field lazy? boolean
---@field deps? (string|jvim.Spec)[]
---@field keys? jvim.KeySpec[]
---@field event? vim.api.keyset.events|vim.api.keyset.events[]
---@field cmd? string|string[]
---@field ft? string|string[]
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
local state = { debug_file = -1 }

---@param message string
local function writeln(message)
  if state.debug_file == -1 then
    return
  end
  vim.uv.fs_write(state.debug_file, ("[%s] %s\n"):format(os.date("%X"), message), nil, function(err)
    if err then
      jvim.error("failed to write to `debug_file`: " .. err)
    end
  end)
end

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
---@param pattern? string|string[]
local function on_event(ev, cb, pattern)
  vim.api.nvim_create_autocmd(ev, {
    once = true,
    callback = cb,
    pattern = pattern,
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

---@param v string|string[]
local function aslist(v)
  return type(v) == "string" and { v } or v
end

function Plugin:setup()
  ---@param on string
  local function loadme(on)
    return function()
      self:load()
      writeln(("Load on %s: %s"):format(on, self.spec[1]))
    end
  end

  if self.spec.lazy ~= nil then
    if not self.spec.lazy then
      -- Eager load must set keymaps too since `on_key` will not be called
      loadme("start")()
      if self.spec.keys then
        for _, keymap in ipairs(self.spec.keys) do
          vim.keymap.set(keymap.mode or "n", keymap[1], keymap[2])
        end
      end
    end
    return
  end

  local scheduled = false

  if self.spec.event then
    scheduled = true
    on_event(self.spec.event, loadme(("event(%s)"):format(self.spec.event)))
  end

  if self.spec.cmd then
    scheduled = true
    for _, cmd in ipairs(aslist(self.spec.cmd)) do
      on_cmd(cmd, loadme(("cmd(%s)"):format(cmd)))
    end
  end

  if self.spec.keys then
    scheduled = true
    for _, keymap in ipairs(self.spec.keys) do
      on_key(keymap, loadme(("key(%s)"):format(keymap[1])))
    end
  end

  if self.spec.ft then
    scheduled = true
    for _, ft in ipairs(aslist(self.spec.ft)) do
      on_event("FileType", loadme(("ft(%s)"):format(ft)), ft)
    end
  end

  if not scheduled then
    on_event("User", loadme("event(LazyLoad)"), "LazyLoad")
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
  state.debug_file = assert(vim.uv.fs_open("debug.txt", "w", tonumber("644", 8)))

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

local M = {}

---@class jvim.Spec
---@field [1] string
---@field version? string|vim.VersionRange
---@field main? string
---@field lazy? boolean
---@field deps? (string|jvim.Spec)[]
---@field dev? boolean
---@field event? vim.api.keyset.events|vim.api.keyset.events[]
---@field cmd? string|string[]|fun():string|string[]
---@field ft? string|string[]|fun():string|string[]
---@field keys? jvim.KeySpec[]|fun():jvim.KeySpec[]
---@field opts? table|fun():table?
---@field config? fun(opts: table)

---@class jvim.KeySpec
---@field [1] string
---@field [2] string|fun()
---@field [3]? string Same as desc
---@field desc? string
---@field mode? string|string[]

---@type table<string, jvim.Plugin>
local cache = {}

---@type vim.pack.Spec[]
local toadd = {}

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
---@field parent? jvim.Plugin
---@field loaded boolean
local Plugin = {}
Plugin.__index = Plugin

---@param spec jvim.Spec
---@param parent? jvim.Plugin
function Plugin.new(spec, parent)
  local self = setmetatable({}, Plugin)
  self.spec = spec
  self.parent = parent
  self.loaded = false
  return self
end

local augroup = vim.api.nvim_create_augroup("jvim.load", { clear = true })

---@param ev vim.api.keyset.events|vim.api.keyset.events[]
---@param cb fun()
---@param pattern? string|string[]
local function on_event(ev, cb, pattern)
  vim.api.nvim_create_autocmd(ev, {
    once = true,
    group = augroup,
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
local function set_keymap(keymap)
  vim.keymap.set(keymap.mode or "n", keymap[1], keymap[2], { desc = keymap[3] or keymap.desc })
end

---@param keymap jvim.KeySpec
---@param cb fun()
local function on_key(keymap, cb)
  local mode = keymap.mode or "n"
  local lhs = keymap[1]
  vim.keymap.set(mode, lhs, function()
    vim.keymap.del(mode, lhs)
    cb()
    set_keymap(keymap)
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

  self:resolve()

  if self.spec.lazy ~= nil then
    if not self.spec.lazy then
      -- Eager load must set keymaps too since `on_key` will not be called
      loadme("start")()
      if self.spec.keys then
        for _, keymap in ipairs(self.spec.keys) do ---@diagnostic disable-line: param-type-mismatch
          set_keymap(keymap)
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
    for _, cmd in ipairs(aslist(self.spec.cmd)) do ---@diagnostic disable-line: param-type-mismatch
      on_cmd(cmd, loadme(("cmd(%s)"):format(cmd)))
    end
  end

  if self.spec.keys then
    scheduled = true
    for _, keymap in ipairs(self.spec.keys) do ---@diagnostic disable-line: param-type-mismatch
      on_key(keymap, loadme(("key(%s)"):format(keymap[1])))
    end
  end

  if self.spec.ft then
    scheduled = true
    for _, ft in ipairs(aslist(self.spec.ft)) do ---@diagnostic disable-line: param-type-mismatch
      on_event("FileType", loadme(("ft(%s)"):format(ft)), ft)
    end
  end

  if not scheduled then
    on_event("User", loadme("event(LazyLoad)"), "LazyLoad")
  end
end

---@generic T
---@param f T | fun(...): T
---@return T
local function ocall(f, ...)
  if vim.is_callable(f) then
    return f(...)
  end
  return f
end

---Merge two tables recursively, modifying `dst`.
---@param dst table
---@param src table
---@param keep? boolean
local function merge(dst, src, keep)
  for k, v in pairs(src) do
    local existing = dst[k]
    if type(v) == "table" then
      if not existing then
        dst[k] = {}
      end
      merge(dst[k], v, keep)
    else
      if not existing or (existing and not keep) then
        dst[k] = v
      end
    end
  end
end

local merge_keys = { "deps", "event", "cmd", "ft", "keys", "opts", "config" }

function Plugin:resolve()
  -- resolve function values
  for k, v in pairs(self.spec) do
    if k ~= "config" and vim.is_callable(v) then
      self.spec[k] = v()
    end
  end

  -- merge spec with parents
  local parent = self.parent
  while parent do
    for _, k in ipairs(merge_keys) do
      if parent.spec[k] then
        if k == "config" and self.spec[k] then
          jvim.warn("Multiple `config` fields defined for plugin `%s` " .. parent.spec[1])
          self.spec[k] = parent.spec[k]
        else
          if not self.spec[k] then
            self.spec[k] = {}
          end
          local src = ocall(parent.spec[k])
          if k == "opts" then
            merge(self.spec[k], src, true)
          else
            vim.list_extend(self.spec[k], src)
          end
        end
      end
    end
    parent = parent.parent
  end
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
  if not self.spec.dev then
    vim.cmd.packadd(name)
  end

  if self.spec.config then
    self.spec.config(self.spec.opts) ---@diagnostic disable-line: param-type-mismatch
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
    local parent = cache[name]

    cache[name] = Plugin.new(spec, parent)

    if not spec.dev and not parent then
      table.insert(toadd, {
        src = "https://github.com/" .. name,
        version = spec.version,
      })
    end
  end
end

---@param path string
local function import(path)
  local mod = dofile(path)
  if not mod then
    return
  end
  add(vim.islist(mod) and mod or { mod })
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

---@class jvim.LoadConfig
---@field import? string Relative path to `plugins` directory
---@field dev? string Path to be added to neovim's runtime.

---@param opts? jvim.LoadConfig
function M.setup(opts)
  opts = opts or {}

  if vim.env.DEBUG_LOAD then
    state.debug_file = assert(vim.uv.fs_open("debug.load", "w", tonumber("644", 8)))
  end

  if opts.dev then
    vim.opt.rtp:append(vim.fn.expand(opts.dev))
  end

  local root = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", opts.import or "plugins")
  walkdir(root, import)

  vim.pack.add(toadd, { load = function() end })

  for _, plugin in pairs(cache) do
    plugin:setup()
  end

  vim.schedule(function()
    vim.api.nvim_exec_autocmds("User", { pattern = "LazyLoad" })
  end)
end

return M

local M = {}

---comment
---@param mode string|string[]
---@param lhs string
---@param rhs fun()|string
---@param opts? string|vim.keymap.set.Opts
---@param mod? fun(opts: vim.keymap.set.Opts)
function M.map(mode, lhs, rhs, opts, mod)
  opts = type(opts) == "string" and { desc = opts } or opts
  if mod then ---@cast opts -?
    mod(opts)
  end
  vim.keymap.set(mode, lhs, rhs, opts)
end

---@param keymaps [string, fun()|string, string|vim.keymap.set.Opts][]
---@param mod? fun(opts: vim.keymap.set.Opts)
function M.nmap(keymaps, mod)
  for _, km in ipairs(keymaps) do
    M.map("n", km[1], km[2], km[3], mod)
  end
end

---@param message string|string[]
---@param level? vim.log.levels
function M.notify(message, level)
  if type(message) == "table" then
    message = table.concat(
      vim.tbl_filter(function(line)
        return line or false
      end, message),
      "\n"
    )
  end
  vim.schedule(function()
    vim.notify(message, level or vim.log.levels.INFO)
  end)
end

---@param message string|string[]
function M.error(message)
  M.notify(message, vim.log.levels.ERROR)
end

---@param message string|string[]
function M.warn(message)
  M.notify(message, vim.log.levels.WARN)
end

---Optional call (type narrowing is kind of cursed in lua_ls, needs manual @cast at call site)
---@generic T
---@param x T | fun(...): T
---@return T
function M.ocall(x, ...)
  if vim.is_callable(x) then
    return x(...)
  end
  return x
end

---@class jvim.toggle.Opts
---@field name string
---@field get boolean|(fun():boolean)
---@field set fun(state:boolean)}

---@param opts jvim.toggle.Opts
local function toggle(opts)
  local state = not M.ocall(opts.get) ---@cast state boolean
  opts.set(state)
  M.notify(
    (state and "Enabled" or "Disabled") .. " **" .. opts.name .. "**",
    state and vim.log.levels.INFO or vim.log.levels.WARN
  )
end

---@class jvim.toggle
---@overload fun(opts: jvim.toggle.Opts)
M.toggle = setmetatable({}, {
  __call = function(_, ...)
    toggle(...)
  end,
})

function M.toggle.autoformat()
  toggle({
    name = "autoformat",
    get = vim.g.autoformat,
    set = function(state)
      vim.g.autoformat = state
    end,
  })
end

function M.toggle.diagnostics()
  toggle({
    name = "diagnostics",
    get = vim.diagnostic.is_enabled,
    set = vim.diagnostic.enable,
  })
end

function M.toggle.inlay_hints()
  toggle({
    name = "inlay hints",
    get = vim.lsp.inlay_hint.is_enabled,
    set = vim.lsp.inlay_hint.enable,
  })
end

function M.toggle.hlsearch()
  if vim.opt.hlsearch:get() then
    vim.cmd.nohlsearch()
  end
end

M.diagnostic = {}

---@param severity? vim.diagnostic.Severity
function M.diagnostic.open(severity)
  return function()
    require("trouble").open({
      mode = "diagnostics",
      filter = { severity = severity },
    })
  end
end

---@param severity? vim.diagnostic.Severity
---@param buf? integer
function M.diagnostic.open_buf(severity, buf)
  return function()
    require("trouble").open({
      mode = "diagnostics",
      filter = { severity = severity, buf = buf or 0 },
    })
  end
end

M.lsp = {}

---@param from string
---@param to string
---@param rename? fun()
function M.lsp.request_rename(from, to, rename)
  local changes = {
    files = {
      {
        oldUri = vim.uri_from_fname(from),
        newUri = vim.uri_from_fname(to),
      },
    },
  }

  local clients = vim.lsp.get_clients()
  for _, client in ipairs(clients) do
    if client:supports_method("workspace/willRenameFiles") then
      local resp = client:request_sync("workspace/willRenameFiles", changes, 1000, 0)
      if resp and resp.result ~= nil then
        vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding)
      end
    end
  end

  if rename then
    rename()
  end

  for _, client in ipairs(clients) do
    if client:supports_method("workspace/didRenameFiles") then
      client:notify("workspace/didRenameFiles", changes)
    end
  end
end

return M

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

M.toggle = {}

function M.toggle.autoformat()
  vim.g.disable_autoformat = not vim.g.disable_autoformat
  jvim.notify(("toggle(autoformat) = %s"):format(vim.g.disable_autoformat))
end

function M.toggle.diagnostics()
  local enable = not vim.diagnostic.is_enabled()
  vim.diagnostic.enable(enable)
  jvim.notify(("toggle(diagnostics) = %s"):format(enable))
end

function M.toggle.inlay_hints()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
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

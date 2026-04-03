local M = {}

function gh(x)
  return "https://github.com/" .. x
end

function M.map(mode, lhs, rhs, opts, mod)
  opts = type(opts) == "string" and { desc = opts } or opts
  vim.keymap.set(mode, lhs, rhs, mod and mod(opts) or opts)
end

---@param keymaps [string, fun()|string, string|vim.keymap.set.Opts][]
---@param mod? fun(opts: vim.keymap.set.Opts): nil
function M.nmap(keymaps, mod)
  for _, km in ipairs(keymaps) do
    M.map("n", km[1], km[2], km[3], mod)
  end
end

M.augroup = vim.api.nvim_create_augroup("jvim", { clear = false })

---@param ev vim.api.keyset.events|vim.api.keyset.events[]
---@param cb fun(args: vim.api.keyset.create_autocmd.callback_args)
function M.lazy_event(ev, cb)
  vim.api.nvim_create_autocmd(ev, {
    once = true,
    group = M.augroup,
    callback = cb,
  })
end

---@param cmd string
---@param cb fun()
function M.lazy_cmd(cmd, cb)
  vim.api.nvim_create_user_command(cmd, function(args)
    pcall(vim.api.nvim_del_user_command, cmd)
    cb()
    vim.api.nvim_cmd({
      cmd = cmd,
      args = args.fargs,
    }, {})
  end, { nargs = "*" })
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

return M

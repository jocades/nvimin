local M = {}

---@class resurrect.Config
local config = {
  root = vim.fs.joinpath(vim.fn.stdpath("data"), "resurrect"),
  min_bufs = 1,
}

local cached ---@type string
local function get()
  if cached then
    return cached
  end
  local cwd = assert(vim.uv.cwd())
  local root = vim.fs.root(cwd, ".git") or cwd
  local hash = vim.fn.sha256(root):sub(1, 8)
  cached = vim.fs.joinpath(config.root, hash)
  return cached
end

function M.load()
  local file = get()
  if vim.uv.fs_stat(file) then
    vim.cmd.source(file)
  end
end

function M.store()
  local file = get()
  vim.cmd("mksession! " .. file)
end

local function needs_store()
  if config.min_bufs < 1 then
    return true
  end

  local count = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if
      (vim.bo[buf].buftype == "" or vim.bo[buf].buftype == "help")
      and vim.bo[buf].ft ~= "gitcommit"
      and vim.api.nvim_buf_get_name(buf) ~= ""
    then
      count = count + 1
      if count == config.min_bufs then
        return true
      end
    end
  end

  return false
end

---@param opts? resurrect.Config
function M.setup(opts)
  jvim.merge(config, opts or {})
  vim.fn.mkdir(config.root, "p")

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if needs_store() then
        M.store()
      end
    end,
  })
end

return M

vim.pack.add({
  gh("nvim-treesitter/nvim-treesitter"),
  gh("nvim-treesitter/nvim-treesitter-textobjects"),
  gh("windwp/nvim-ts-autotag"),
})

require("nvim-treesitter").install({
  "c",
  "bash",
  "rust",
  "css",
  "diff",
  "elixir",
  "html",
  "javascript",
  "jsdoc",
  "json",
  "json5",
  "lua",
  "markdown",
  "markdown_inline",
  "python",
  "rust",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "xml",
  "yaml",
})

--vim.api.nvim_create_autocmd("FileType", {
--  callback = function(args)
--    local ft = args.match
--    if vim.treesitter.language.get_lang(ft) then
--      vim.treesitter.start()
--      --vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
--      --vim.wo[0][0].foldmethod = "expr"
--    end
--  end,
--})

require("nvim-ts-autotag").setup()
require("nvim-treesitter-textobjects").setup()

local function incremental_selection()
  local method = "textDocument/selectionRange"
  local client = vim.lsp.get_clients({ method = method, bufnr = 0 })[1]

  if not client then
    require("vim.treesitter._select").select_parent(vim.v.count1)
  else
    vim.lsp.buf.selection_range(vim.v.count1)
  end
end

local function move(to, next)
  return function()
    local objs = require("nvim-treesitter-textobjects.move")
    if next then
      objs.goto_next_start(to, "textobjects")
    else
      objs.goto_previous_start(to, "textobjects")
    end
  end
end

local function swap(with, next)
  return function()
    local objs = require("nvim-treesitter-textobjects.swap")
    if next then
      objs.swap_next(with)
    else
      objs.swap_previous(with)
    end
  end
end

jvim.nmap({
  { "<C-Space>", incremental_selection },
  { "]f", move("@function.outer", true) },
  { "[f", move("@function.outer", false) },
  { "]c", move("@class.outer", true) },
  { "[c", move("@class.outer", false) },
  { "<leader>sp", swap("@parameter.inner", true) },
  { "<leader>sP", swap("@parameter.outer", false) },
})

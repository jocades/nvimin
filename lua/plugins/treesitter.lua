return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    config = function()
      local langs = {
        "bash",
        "c",
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
        "nix",
        "python",
        "rust",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
      }

      require("nvim-treesitter").install(langs)

      local fts = {}
      for _, lang in ipairs(langs) do
        for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
          table.insert(fts, ft)
        end
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter-start-on-ft", { clear = true }),
        pattern = fts,
        callback = function(ev)
          vim.treesitter.start(ev.buf)
        end,
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = "InsertEnter",
    config = function()
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
    end,
  },
}

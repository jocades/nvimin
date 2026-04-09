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
        "sql",
        "xml",
        "yaml",
        "go",
        "ocaml",
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
          vim.bo.indentexpr = "v:lua.require('nvim-treesitter').indentexpr()"
        end,
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = "InsertEnter",
    config = function()
      require("nvim-treesitter-textobjects").setup()

      local function select(capture)
        return function()
          require("nvim-treesitter-textobjects.select").select_textobject(capture, "textobjects")
        end
      end

      local function incremental_selection()
        local method = "textDocument/selectionRange"
        local client = vim.lsp.get_clients({ method = method, bufnr = 0 })[1]

        if not client then
          require("vim.treesitter._select").select_parent(vim.v.count1)
        else
          vim.lsp.buf.selection_range(vim.v.count1)
        end
      end

      local function move(capture, next)
        return function()
          local objs = require("nvim-treesitter-textobjects.move")
          if next then
            objs.goto_next_start(capture, "textobjects")
          else
            objs.goto_previous_start(capture, "textobjects")
          end
        end
      end

      local function swap(capture, next)
        return function()
          local objs = require("nvim-treesitter-textobjects.swap")
          if next then
            objs.swap_next(capture)
          else
            objs.swap_previous(capture)
          end
        end
      end

      for lhs, rhs in pairs({
        ["af"] = select("@function.outer"),
        ["if"] = select("@function.inner"),
        ["ac"] = select("@class.outer"),
        ["ic"] = select("@class.inner"),
      }) do
        vim.keymap.set({ "x", "o" }, lhs, rhs)
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

  {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    opts = {},
  },
}

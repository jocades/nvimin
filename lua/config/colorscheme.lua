vim.pack.add({
  {
    src = "https://github.com/catppuccin/nvim",
    name = "catppuccin", --[[version = "1bf0701"]]
  },
})

-- Use previous highlights, the new ones completely break rust.
-- https://github.com/catppuccin/nvim/releases/tag/v2.0.0
require("catppuccin").setup({
  no_italic = true,
  lsp_styles = {
    underlines = {
      errors = { "undercurl" },
      hints = { "undercurl" },
      warnings = { "undercurl" },
      information = { "undercurl" },
      ok = { "undercurl" },
    },
    inlay_hints = {
      background = true,
    },
  },
  custom_highlights = function(C)
    local O = require("catppuccin").options
    return {
      ["@variable.member"] = { fg = C.lavender }, -- For fields.
      ["@module"] = { fg = C.lavender, style = O.styles.miscs or { "italic" } }, -- For identifiers referring to modules and namespaces.
      ["@string.special.url"] = { fg = C.rosewater, style = { "italic", "underline" } }, -- urls, links and emails
      ["@type.builtin"] = { fg = C.yellow, style = O.styles.properties or { "italic" } }, -- For builtin types.
      ["@property"] = { fg = C.lavender, style = O.styles.properties or {} }, -- Same as TSField.
      ["@constructor"] = { fg = C.sapphire }, -- For constructor calls and definitions: = { } in Lua, and Java constructors.
      ["@keyword.operator"] = { link = "Operator" }, -- For new keyword operator
      ["@keyword.export"] = { fg = C.sky, style = O.styles.keywords },
      ["@markup.strong"] = { fg = C.maroon, style = { "bold" } }, -- bold
      ["@markup.italic"] = { fg = C.maroon, style = { "italic" } }, -- italic
      ["@markup.heading"] = { fg = C.blue, style = { "bold" } }, -- titles like: # Example
      ["@markup.quote"] = { fg = C.maroon, style = { "bold" } }, -- block quotes
      ["@markup.link"] = { link = "Tag" }, -- text references, footnotes, citations, etc.
      ["@markup.link.label"] = { link = "Label" }, -- link, reference descriptions
      ["@markup.link.url"] = { fg = C.rosewater, style = { "italic", "underline" } }, -- urls, links and emails
      ["@markup.raw"] = { fg = C.teal }, -- used for inline code in markdown and for doc in python (""")
      ["@markup.list"] = { link = "Special" },
      ["@tag"] = { fg = C.mauve }, -- Tags like html tag names.
      ["@tag.attribute"] = { fg = C.teal, style = O.styles.miscs or { "italic" } }, -- Tags like html tag names.
      ["@tag.delimiter"] = { fg = C.sky }, -- Tag delimiter like < > /
      ["@property.css"] = { fg = C.lavender },
      ["@property.id.css"] = { fg = C.blue },
      ["@type.tag.css"] = { fg = C.mauve },
      ["@string.plain.css"] = { fg = C.peach },
      ["@constructor.lua"] = { fg = C.flamingo }, -- For constructor calls and definitions: = { } in Lua.
      -- typescript
      ["@property.typescript"] = { fg = C.lavender, style = O.styles.properties or {} },
      ["@constructor.typescript"] = { fg = C.lavender },
      -- TSX (Typescript React)
      ["@constructor.tsx"] = { fg = C.lavender },
      ["@tag.builtin.tsx"] = { link = "Special" },
      ["@tag.attribute.tsx"] = { fg = C.teal, style = O.styles.miscs or { "italic" } },
      ["@type.builtin.c"] = { fg = C.yellow, style = {} },
      ["@type.builtin.cpp"] = { fg = C.yellow, style = {} },

      ["@lsp.typemod.class.defaultLibrary"] = { link = "@type.builtin" },
      ["@lsp.typemod.enum.defaultLibrary"] = { link = "@type.builtin" },
      ["@lsp.typemod.enumMember.defaultLibrary"] = { link = "@constant.builtin" },
      ["@lsp.typemod.function.defaultLibrary"] = { link = "@function.builtin" },
      ["@lsp.typemod.keyword.async"] = { link = "@keyword.coroutine" },
      ["@lsp.typemod.macro.defaultLibrary"] = { link = "@function.builtin" },
      ["@lsp.typemod.method.defaultLibrary"] = { link = "@function.builtin" },
      ["@lsp.typemod.operator.injected"] = { link = "@operator" },
      ["@lsp.typemod.string.injected"] = { link = "@string" },
      ["@lsp.typemod.type.defaultLibrary"] = { link = "@type.builtin" },
      ["@lsp.typemod.variable.defaultLibrary"] = { link = "@variable.builtin" },
      ["@lsp.typemod.variable.injected"] = { link = "@variable" },
    }
  end,
})

vim.cmd.colorscheme("catppuccin-mocha")

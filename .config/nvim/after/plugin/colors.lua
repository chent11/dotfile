function RenderColor(color)
  color = color or 'gruvbox-material'
  -- vim.cmd.colorscheme('gruvbox-material')
  -- vim.cmd.colorscheme('everforest')
  -- vim.cmd.colorscheme('rose-pine')
  vim.cmd.colorscheme(color)

  -- Make the color of the virtual text more beautiful
  vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextHint', { fg = '#8a3fa0', bg = '#322e3f' })
  vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextInfo', { fg = '#2b6f77', bg = '#28333b' })
  vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextOk', { link = 'DiagnosticOk' })
  vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextWarn', { fg = '#93691d', bg = '#333232' })
  vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextError', { fg = '#993939', bg = '#332d35' })

  -- Don't let the LSP semantic highlight override treesitter.
  vim.api.nvim_set_hl(0, '@lsp.type.macro.c', {})
  vim.api.nvim_set_hl(0, '@lsp.type.macro.cpp', {})

  -- Put this line at the bottom of this function
  vim.api.nvim_set_hl(0, 'IndentBlanklineIndent1', { fg = '#444444', nocombine = true })
end

RenderColor('gruvbox-material')
-- RenderColor('everforest')
-- RenderColor('rose-pine')
-- RenderColor('onedark')

-- leap.nvim mappings (replaces create_default_mappings() — Sneak-style)
vim.keymap.set({ 'n', 'x', 'o' }, 's',  '<Plug>(leap-forward)',  { silent = true })
vim.keymap.set({ 'n', 'x', 'o' }, 'S',  '<Plug>(leap-backward)', { silent = true })
vim.keymap.set('n',              'gs', '<Plug>(leap-from-window)', { silent = true })

-- highlights (applied after your colorscheme loads, so they don't get overwritten)
vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function()
    vim.api.nvim_set_hl(0, 'LeapBackdrop', { link = 'Comment' })
    vim.api.nvim_set_hl(0, 'LeapMatch', {
      fg = 'white',
      bold = true,
      nocombine = true,
    })
  end,
})

-- apply once right now too (in case colorscheme already loaded)
vim.api.nvim_exec_autocmds('ColorScheme', {})

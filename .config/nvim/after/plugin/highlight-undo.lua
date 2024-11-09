require('highlight-undo').setup({
  duration = 300,
  keymaps = {
    Keymap_name = {
      -- most fields here are the same as in vim.keymap.set
      desc = "a description",
      hlgroup = 'HighlightUndo',
      mode = 'n',
      lhs = 'flhs',
      rhs = 'optional, can be nil',
      opts = {
        -- same as opts to vim.keymap.set. if rhs is nil, there should be a
        -- callback key which points to a function
      },
    },
  },
})

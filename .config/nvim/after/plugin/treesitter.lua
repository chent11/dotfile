require('nvim-treesitter.configs').setup {
  -- Add languages to be installed here that you want installed for treesitter
  ensure_installed = { 'c', 'cpp', 'go', 'lua', 'python', 'rust', 'typescript', 'vim', 'query', 'comment' },
  sync_install = false,
  auto_install = true,

  highlight = {
    enable = true,

    disable = function(lang, bufnr)
      -- List of languages to disable
      local disabled_languages = { "asm", "make", "xml", "bitbake" }

      -- Disable if the language is in the disabled list
      if vim.tbl_contains(disabled_languages, lang) then
        return true
      end

      -- Disable if the buffer has more than 100000 lines
      if vim.api.nvim_buf_line_count(bufnr) > 100000 then
        print("Buffer is too large, disabling treesitter highlighting")
        return true
      end

      -- Otherwise, do not disable
      return false
    end,

    additional_vim_regex_highlighting = false,
  },

  -- indent = { enable = true },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = '<c-space>',
      node_incremental = '<c-space>',
      scope_incremental = '<c-s>',
      node_decremental = '<c-backspace>',
    },
  },
  context = {
    enable = false,
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ['aa'] = '@parameter.outer',
        ['ia'] = '@parameter.inner',
        ['af'] = '@function.outer',
        ['if'] = '@function.inner',
        ['ac'] = '@class.outer',
        ['ic'] = '@class.inner',
      },
    },
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        [']m'] = '@function.outer',
        -- [']]'] = '@class.outer',
      },
      goto_next_end = {
        [']M'] = '@function.outer',
        -- [']['] = '@class.outer',
      },
      goto_previous_start = {
        ['[m'] = '@function.outer',
        -- ['[['] = '@class.outer',
      },
      goto_previous_end = {
        ['[M'] = '@function.outer',
        -- ['[]'] = '@class.outer',
      },
    },
    -- swap = {
    --     enable = true,
    --     swap_next = {
    --         ['<leader>a'] = '@parameter.inner',
    --     },
    --     swap_previous = {
    --         ['<leader>A'] = '@parameter.inner',
    --     },
    -- },
  },
}

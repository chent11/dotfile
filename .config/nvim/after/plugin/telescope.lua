-- Enable telescope fzf native, if installed
require('telescope').load_extension('aerial')
require('telescope').load_extension('fzf')
require("telescope").load_extension('harpoon')

require('telescope').setup {
  defaults = {
    vimgrep_arguments = {
      "rg",
      "--color=never",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
      "--smart-case",
      "--no-ignore-vcs",
      "--hidden",
      "--ignore-file=.fdignore",
      "--trim",
    },
    mappings = {
      i = {
        ['<c-x>'] = require('telescope.actions').delete_buffer,
        -- ['<c-a>'] = function(prompt_bufnr)
        --   local entry = require("telescope.actions.state").get_selected_entry()
        --   if entry.filename then
        --     os.execute('echo "' ..
        --       vim.inspect(require("telescope.actions")) .. '" > /tmp/debug-feedback-vim &')
        --     entry.indicator = '$'
        --     require('telescope.actions').close(prompt_bufnr)
        --     require('telescope.builtin').buffers()
        --     -- require("harpoon.mark").add_file(filename)
        --   end
        -- end
      }
    },
  },
  pickers = {
    find_files = {
      find_command = { "fd", "--type", "f", "--strip-cwd-prefix", "--no-ignore-vcs", "--hidden" }
    },
  },
  extensions = {
    aerial = {
      -- Display symbols as <root>.<parent>.<symbol>
      show_nesting = {
        ['_'] = false, -- This key will be the default
        json = true,   -- You can set the option for specific filetypes
        yaml = true,
      }
    }
  }
}

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>o', require('telescope').load_extension('aerial').aerial, { desc = 'Show [O]utline' })
vim.keymap.set('n', '<leader>s;', builtin.buffers, { desc = 'Find existing [b]uffers' })
vim.keymap.set('n', '<leader>/', function()
  builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = true,
  })
end, { desc = '[/] Fuzzily search in current buffer]' })
vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('v', '<leader>sw', function()
  vim.cmd('noau normal! "vy"')
  local text = vim.fn.getreg('v')
  vim.fn.setreg('v', {})

  text = string.gsub(text, "\n", "")
  -- Escape special characters for grep
  local specials = "{}\\*()"
  for i = 1, #specials do
    local char = string.sub(specials, i, i)
    text = string.gsub(text, "%" .. char, "\\" .. char)
  end

  if #text <= 0 then
    text = ''
  end
  builtin.live_grep({ default_text = text })
end, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>gg', function()
  builtin.grep_string({ default_text = '' })
end, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })

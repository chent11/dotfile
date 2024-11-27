return {
  -- Color Theme
  { 'rose-pine/neovim',         lazy = true },
  { 'navarasu/onedark.nvim',    lazy = true },
  { 'sainnhe/everforest',       lazy = true },
  { 'sainnhe/gruvbox-material', lazy = true },
  { 'morhetz/gruvbox',          lazy = true },

  -- Git related plugins
  'tpope/vim-fugitive',
  -- 'tpope/vim-rhubarb'
  'lewis6991/gitsigns.nvim',

  -- Fuzzy Finder (files, lsp, etc)
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' }
  },
  -- Fuzzy Finder Algorithm which requires local dependencies to be built. Only load if `make` is available
  {
    'nvim-telescope/telescope-fzf-native.nvim',
    build = 'make'
  },

  -- Motion
  'ggandor/leap.nvim',

  -- Treesitter
  {
    -- 'chent11/nvim-treesitter',
    url = 'git@github.com:chent11/nvim-treesitter.git',
    build = ':TSUpdate',
    branch = 'spell-checking-for-string'
  },
  'nvim-treesitter/nvim-treesitter-textobjects',
  'nvim-treesitter/nvim-treesitter-context',

  -- LSP Related
  { 'neovim/nvim-lspconfig' },
  { 'williamboman/mason.nvim' },
  { 'williamboman/mason-lspconfig.nvim' },
  { 'nvimtools/none-ls.nvim' },

  -- Autocompletion
  { 'hrsh7th/nvim-cmp' },
  { 'hrsh7th/cmp-nvim-lsp' },
  { 'L3MON4D3/LuaSnip' },

  -- Outline Window
  {
    'stevearc/aerial.nvim',
    opts = {},
  },

  -- Folding
  -- { 'kevinhwang91/nvim-ufo', dependencies = 'kevinhwang91/promise-async' },

  -- Others
  'github/copilot.vim',
  'nvim-tree/nvim-web-devicons',
  'mbbill/undotree',
  'nvim-lualine/lualine.nvim',                                        -- Fancier statusline
  { 'lukas-reineke/indent-blankline.nvim', main = "ibl", opts = {} }, -- Add indentation guides even on blank lines
  {
    'numToStr/Comment.nvim',                                          -- "gc" to comment visual regions/lines
    config = function()
      require('Comment').setup()
    end
  },
  {
    'tzachar/highlight-undo.nvim',
    keys = { { "u" }, { "<C-r>" } },
  },
}

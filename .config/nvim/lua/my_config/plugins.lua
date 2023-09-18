return {
  -- Color Theme
  { 'rose-pine/neovim',         lazy = true },
  { 'navarasu/onedark.nvim',    lazy = true },
  { 'sainnhe/everforest',       lazy = true },
  { 'sainnhe/gruvbox-material', lazy = true },

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

  -- Bufferline
  -- { 'akinsho/bufferline.nvim', tag = "v3.*" }

  -- Treesitter
  { 'chent11/nvim-treesitter', build = ':TSUpdate', branch = 'spell-checking-for-string' },
  'nvim-treesitter/nvim-treesitter-textobjects',
  'nvim-treesitter/nvim-treesitter-context',

  -- LSP Related
  {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v2.x',
    dependencies = {
      -- LSP Support
      { 'neovim/nvim-lspconfig' },                   -- Required
      { 'williamboman/mason.nvim' },                 -- Optional
      { 'williamboman/mason-lspconfig.nvim' },       -- Optional
      -- { 'jose-elias-alvarez/null-ls.nvim' },   -- Optional

      -- Autocompletion
      { 'hrsh7th/nvim-cmp' },           -- Required
      { 'hrsh7th/cmp-nvim-lsp' },       -- Required
      { 'L3MON4D3/LuaSnip' },           -- Required
    }
  },

  -- Outline Window
  {
    'stevearc/aerial.nvim',
    opts = {},
  },

  -- Others
  'nvim-tree/nvim-web-devicons',
  'theprimeagen/harpoon',
  'mbbill/undotree',
  'nvim-lualine/lualine.nvim',             -- Fancier statusline
  'lukas-reineke/indent-blankline.nvim',   -- Add indentation guides even on blank lines
  {
    'numToStr/Comment.nvim',               -- "gc" to comment visual regions/lines
    config = function()
      require('Comment').setup()
    end
  },
}

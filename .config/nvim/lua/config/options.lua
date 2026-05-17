vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt
local o   = vim.o
local g   = vim.g

-- ---------------------------------------------------------------------------
-- Folding (treesitter-based)
-- ---------------------------------------------------------------------------
o.foldmethod     = "expr"
o.foldexpr       = "nvim_treesitter#foldexpr()"
o.foldenable     = true
o.foldlevel      = 99
o.foldcolumn     = "1"
o.foldlevelstart = 99

-- ---------------------------------------------------------------------------
-- Filetype tweaks
-- ---------------------------------------------------------------------------
-- Treat *.h files as C headers (not C++)
g.c_syntax_for_h = 1

-- ---------------------------------------------------------------------------
-- Diff: ignore whitespace changes
-- ---------------------------------------------------------------------------
opt.diffopt:append("iwhite")

-- ---------------------------------------------------------------------------
-- Spell checking
-- ---------------------------------------------------------------------------
o.spell = true

-- ---------------------------------------------------------------------------
-- Line numbers
-- ---------------------------------------------------------------------------
o.number         = true
o.relativenumber = true

-- ---------------------------------------------------------------------------
-- Visible column ruler
-- ---------------------------------------------------------------------------
opt.colorcolumn = "120"
opt.textwidth   = 120

-- ---------------------------------------------------------------------------
-- Indentation: 4-space default
-- ---------------------------------------------------------------------------
opt.tabstop      = 4
opt.softtabstop  = 4
opt.shiftwidth   = 4
opt.expandtab    = true
opt.smartindent  = true
opt.wrap         = false

-- ---------------------------------------------------------------------------
-- Persistent undo
-- ---------------------------------------------------------------------------
opt.backup   = false
opt.undodir  = os.getenv("HOME") .. "/.nvim/undodir"
opt.undofile = true

-- ---------------------------------------------------------------------------
-- Search
-- ---------------------------------------------------------------------------
o.hlsearch  = true
o.incsearch = true

-- Use ripgrep for :grep
o.grepprg = "rg --vimgrep"

-- ---------------------------------------------------------------------------
-- Misc UI
-- ---------------------------------------------------------------------------
o.mouse         = ""    -- disable mouse
o.termguicolors = true  -- 24-bit colors

opt.scrolloff   = 8
opt.signcolumn  = "yes"
opt.isfname:append("@-@")
o.updatetime    = 50

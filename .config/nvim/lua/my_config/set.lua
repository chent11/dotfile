-- Set the leader key to space
vim.g.mapleader = " "

-- Set fold method
vim.o.foldmethod = "expr"
vim.o.foldexpr = "nvim_treesitter#foldexpr()"
-- vim.o.foldenable = false
vim.o.foldlevel = 99

-- Make the nvim treat *.h file as C header
vim.g.c_syntax_for_h = 1

-- Turn off white-spaces compare
vim.api.nvim_command('set diffopt+=iwhite')

-- Set spell
vim.o.spell = true

-- Set line number and relative number line
vim.o.nu = true
vim.o.relativenumber = true

-- Set a visible column line
vim.opt.colorcolumn = "120"
vim.opt.textwidth = 120

-- Set tab style to spaces
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = true

-- Set undo file
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.nvim/undodir"
vim.opt.undofile = true

-- Set highlight on search
vim.o.hlsearch = true
vim.o.incsearch = true

-- Set grep method
vim.o.grepprg = "rg --vimgrep"
-- Disable mouse mode
vim.o.mouse = ''
-- Set colorscheme
vim.o.termguicolors = true

-- Others
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")
vim.o.updatetime = 50

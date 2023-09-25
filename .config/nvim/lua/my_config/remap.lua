vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Move selected chunks
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Put cursor at the beginning instead of at the last when using J
vim.keymap.set("n", "J", "mzJ`z")

-- Keep cursor at the middle of the screen when screen down/up or searching
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Keep copied content when overwriting
vim.keymap.set("x", "<leader>p", [["_dP]])
-- vim.keymap.set("x", "p", [["_dP]])

-- Real delete without affecting current register's content
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- Yank text to system clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
-- vim.keymap.set("n", "<leader>yy", [["+yy]])

-- Quick Fix List
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

-- Replace word under cursor
-- vim.keymap.set("n", "<leader>rw", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
-- Replace word and it could be repeated using [n.]
vim.keymap.set("n", "<leader>cw", [[/<C-r><C-w><CR>Ncw]])

-- Open nvim in a new tmux-window at the configuration folder
vim.api.nvim_command('command! TmuxOpenVimConfig silent !tmux new-window -n "nvim-config" -c ~/.config/nvim nvim')

-- Others
vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set({ "n", "v" }, "<leader>fmt", vim.lsp.buf.format)

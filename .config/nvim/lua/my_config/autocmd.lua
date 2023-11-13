local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Set fugitive buffers to read-only and unmodifiable
autocmd({ "User" }, {
  pattern = "FugitiveBlob,FugitiveStageBlob",
  group = augroup('FugitiveBuffers', { clear = true }),
  command = 'setlocal readonly nomodifiable noswapfile'
})

-- Set a cursor line for current buffer only
local cursorlineGroup = augroup('cursorlineGroup', { clear = true })
autocmd({ "BufEnter" }, {
  pattern = "*",
  group = cursorlineGroup,
  command = 'setlocal cursorline'
})

autocmd({ "BufLeave" }, {
  pattern = "*",
  group = cursorlineGroup,
  command = 'setlocal nocursorline'
})

-- Another workaround for the folding issue
-- autocmd({ "BufEnter", "BufNew", "BufWinEnter" }, {
--   group = augroup("ts_fold_workaround", { clear = true }),
--   command = "set foldexpr=nvim_treesitter#foldexpr()",
-- })

-- Trim white spaces on save
autocmd({ "BufWritePre" }, {
  pattern = { "*" },
  group = augroup('trimWhiteSpaces', { clear = true }),
  callback = function(_)
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos(".", save_cursor)
  end,
})

local fileTypeGroups = augroup('fileTypeGroups', { clear = true })
autocmd("FileType", {
  pattern = {
    "vim",
    "html",
    "css",
    "json",
    "javascript",
    "javascriptreact",
    "markdown.mdx",
    "typescript",
    "typescriptreact",
    "lua",
    "sh",
    "zsh",
  },
  group = fileTypeGroups,
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.tabstop = 2
  end,
})

autocmd("FileType", {
  pattern = "markdown",
  group = fileTypeGroups,
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.conceallevel = 2
  end,
})

autocmd({ "BufNew", "BufNewFile", "BufRead" }, {
  pattern = "*.json",
  group = augroup("json_file_recognition", { clear = true }),
  callback = function()
    vim.bo.filetype = "jsonc"
  end,
})

autocmd("TermOpen", {
  pattern = "term://*",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.cursorline = false
    vim.opt_local.signcolumn = "no"
  end,
})

autocmd("TextYankPost", {
  group = augroup("HighlightYank", {}),
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Add rules for git commit message for copilot
local function append_diff()
  -- Get the Git repository root directory
  local git_dir = vim.fn.FugitiveGitDir()
  local git_root = vim.fn.fnamemodify(git_dir, ':h')

  -- Get the diff of the staged changes relative to the Git repository root
  local diff_cmd = 'git -C ' .. git_root .. ' diff --cached'
  local diff = vim.fn.system(diff_cmd)

  -- Diff header and footer
  local diff_header = '##Here is the diff of changes:'
  local diff_footer = '##End of diff'

  -- Add a comment character to each line of the diff
  local comment_diff = {}
  table.insert(comment_diff, '# ' .. diff_header)
  for line in string.gmatch(diff, '[^\r\n]+') do
    table.insert(comment_diff, '# ' .. line)
  end
  table.insert(comment_diff, '# ' .. diff_footer)
  local joined_comment_diff = table.concat(comment_diff, '\n')

  -- Define the commit prefix rules as a multi-line string
  local commit_rules = [[
Commit Message Guidelines:
- **fix:** Patch a bug in your codebase (correlates with PATCH in Semantic Versioning).
- **feat:** Introduce a new feature to the codebase (correlates with MINOR in Semantic Versioning).
- **BREAKING CHANGE:** Introduce a breaking change. Add `!` after the type/scope or include a footer `BREAKING CHANGE: <description>`.
- **refactor:** Refactor code without changing its external behavior.
- **chore:** minor changes that don't fit in any of the above categories.
- **docs:** Documentation only changes.
- **test:** Adding missing tests or correcting existing tests.
- Additional footers may follow the git trailer format.
Based on the differences outlined above, please create a concise commit message that adheres to the provided guidelines. Enclose the commit message within a code block.
]]

  -- Split the commit_rules string into individual lines and prepend each with a comment character
  local comment_rules = {}
  for line in string.gmatch(commit_rules, '[^\r\n]+') do
    table.insert(comment_rules, '# ' .. line)
  end
  -- Combine the commented rules into a single string separated by newlines
  local joined_comment_rules = table.concat(comment_rules, '\n')

  local full_template = joined_comment_diff .. '\n' .. joined_comment_rules

  -- Copy the full template to the clipboard and print a message
  vim.fn.setreg('+', full_template)
  vim.defer_fn(function()
    vim.notify("Copied diff to clipboard", vim.log.levels.INFO)
  end, 100)
  -- full_template = full_template .. '\n\n' .. "Commit Message:"

  -- Insert the full template at the start of the buffer
  vim.api.nvim_buf_set_lines(0, 0, 0, false, vim.split(full_template, '\n'))
end

local group = augroup('GitCommitAppend', { clear = true })
autocmd('BufReadPost', {
  group = group,
  pattern = 'COMMIT_EDITMSG',
  callback = append_diff,
})


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

autocmd("FileType", {
  pattern = "asm",
  group = augroup("disable_ts_fold", { clear = true }),
  callback = function()
    vim.o.foldmethod = "manual"
  end,
})

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

autocmd("FileType", {
  pattern = "kconfig",
  group = fileTypeGroups,
  callback = function()
    -- Delay the execution to ensure it runs after other settings
    vim.defer_fn(function()
        vim.opt_local.textwidth = 80
    end, 0)
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

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- ===========================================================================
-- COMMIT_EDITMSG: append staged diff + commit-message guidelines
-- ===========================================================================
local function append_commit_template()
  -- Fugitive is loaded eagerly (see plugins/git.lua), but defend anyway
  -- so this never blows up if the plugin is unavailable.
  if vim.fn.exists("*FugitiveGitDir") ~= 1 then
    return
  end

  local git_dir    = vim.fn.FugitiveGitDir()
  local git_root   = vim.fn.fnamemodify(git_dir, ":h")

  local diff       = vim.fn.system("git -C " .. git_root .. " diff --cached")

  local line_count = select(2, diff:gsub("\n", "\n"))
  if line_count > 10000 then
    vim.defer_fn(function()
      vim.notify(
        "Diff too large (" .. line_count .. " lines), skipping commit rules",
        vim.log.levels.WARN
      )
    end, 100)
    return
  end

  local diff_header = "##Here is the diff of changes:"
  local diff_footer = "##End of diff"

  local comment_diff = { "# " .. diff_header }
  for line in string.gmatch(diff, "[^\r\n]+") do
    table.insert(comment_diff, "# " .. line)
  end
  table.insert(comment_diff, "# " .. diff_footer)
  local joined_comment_diff = table.concat(comment_diff, "\n")

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

  local comment_rules = {}
  for line in string.gmatch(commit_rules, "[^\r\n]+") do
    table.insert(comment_rules, "# " .. line)
  end
  local joined_comment_rules = table.concat(comment_rules, "\n")

  local full_template = joined_comment_diff .. "\n" .. joined_comment_rules

  vim.fn.setreg("+", full_template)
  vim.defer_fn(function()
    vim.notify("Copied diff to clipboard", vim.log.levels.INFO)
  end, 100)

  vim.api.nvim_buf_set_lines(0, 0, 0, false, vim.split(full_template, "\n"))
end

autocmd("BufReadPost", {
  group    = augroup("GitCommitAppend", { clear = true }),
  pattern  = "COMMIT_EDITMSG",
  callback = append_commit_template,
})

-- ===========================================================================
-- Fugitive blob buffers are read-only
-- ===========================================================================
autocmd("User", {
  group   = augroup("FugitiveBuffers", { clear = true }),
  pattern = "FugitiveBlob,FugitiveStageBlob",
  command = "setlocal readonly nomodifiable noswapfile",
})

-- ===========================================================================
-- Cursor line only on the focused window
-- ===========================================================================
local cursorline_group = augroup("CursorLineFocused", { clear = true })
autocmd("BufEnter", {
  group   = cursorline_group,
  pattern = "*",
  command = "setlocal cursorline",
})
autocmd("BufLeave", {
  group   = cursorline_group,
  pattern = "*",
  command = "setlocal nocursorline",
})

-- ===========================================================================
-- Trim trailing whitespace on save
-- ===========================================================================
autocmd("BufWritePre", {
  group    = augroup("TrimTrailingWhitespace", { clear = true }),
  pattern  = "*",
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos(".", save_cursor)
  end,
})

-- ===========================================================================
-- Per-filetype settings
-- ===========================================================================
local ft_group = augroup("FileTypeSettings", { clear = true })

-- 2-space indentation for these filetypes
autocmd("FileType", {
  group    = ft_group,
  pattern  = {
    "vim", "html", "css", "json", "javascript", "javascriptreact",
    "markdown.mdx", "typescript", "typescriptreact", "lua", "sh", "zsh",
  },
  callback = function()
    vim.opt_local.shiftwidth  = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.tabstop     = 2
  end,
})

-- Markdown: soft wrap + conceal
autocmd("FileType", {
  group    = ft_group,
  pattern  = "markdown",
  callback = function()
    vim.opt_local.wrap         = true
    vim.opt_local.linebreak    = true
    vim.opt_local.conceallevel = 2
  end,
})

-- Kconfig: deferred so it wins against other ftplugins
autocmd("FileType", {
  group    = ft_group,
  pattern  = "kconfig",
  callback = function()
    vim.defer_fn(function()
      vim.opt_local.textwidth = 80
    end, 0)
  end,
})

-- Disable treesitter folding for assembly
autocmd("FileType", {
  group    = ft_group,
  pattern  = "asm",
  callback = function()
    vim.o.foldmethod = "manual"
  end,
})

-- ===========================================================================
-- Treat *.json as jsonc (allow comments)
-- ===========================================================================
autocmd({ "BufNew", "BufNewFile", "BufRead" }, {
  group    = augroup("JsonAsJsonc", { clear = true }),
  pattern  = "*.json",
  callback = function()
    vim.bo.filetype = "jsonc"
  end,
})

-- ===========================================================================
-- Cleaner terminal buffers
-- ===========================================================================
autocmd("TermOpen", {
  group    = augroup("TerminalSettings", { clear = true }),
  pattern  = "term://*",
  callback = function()
    vim.opt_local.number         = false
    vim.opt_local.relativenumber = false
    vim.opt_local.cursorline     = false
    vim.opt_local.signcolumn     = "no"
  end,
})

-- ===========================================================================
-- Briefly highlight yanked text
-- ===========================================================================
autocmd("TextYankPost", {
  group    = augroup("HighlightYank", { clear = true }),
  pattern  = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})

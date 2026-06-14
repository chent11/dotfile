-- <A-h> pressed while focused INSIDE the Claude window:
--   * floating window  -> hide it (toggle off)
--   * side split       -> just switch back to the previous window (Claude stays open)
local function claude_window_alt_h()
  local cfg = vim.api.nvim_win_get_config(0)
  local is_float = cfg.relative ~= nil and cfg.relative ~= ""
  if is_float then
    require("claudecode.terminal").simple_toggle() -- hide the float
  else
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes([[<C-\><C-n><C-w>p]], true, false, true),
      "n", false
    )
  end
end

-- Buffer-local keys applied to the Claude window regardless of layout. Merged on
-- top of the provider's own keys (e.g. <S-CR> newline) via tbl_deep_extend.
local win_keys = {
  claude_alt_h = {
    "<A-h>",
    claude_window_alt_h,
    mode = { "n", "t" },
    desc = "Hide (float) / switch out (split)",
  },
}

-- Per-call layout overrides. A per-call snacks_win_opts REPLACES the default one
-- (build_config does not merge), so each layout must carry win_keys itself.
local float_win = { position = "float", width = 0.85, height = 0.85, border = "rounded", keys = win_keys }
local split_win = { position = "right", width = 0.35, keys = win_keys }

return {
  {
    "coder/claudecode.nvim",
    cmd = {
      "ClaudeCode",
      "ClaudeCodeFocus",
      "ClaudeCodeSelectModel",
      "ClaudeCodeAdd",
      "ClaudeCodeSend",
      "ClaudeCodeTreeAdd",
      "ClaudeCodeStatus",
      "ClaudeCodeStart",
      "ClaudeCodeStop",
      "ClaudeCodeOpen",
      "ClaudeCodeClose",
      "ClaudeCodeDiffAccept",
      "ClaudeCodeDiffDeny",
      "ClaudeCodeCloseAllDiffs",
    },
    keys = {
      { "<leader>a",  nil,                              desc = "AI/Claude Code" },
      { "<leader>ac", function() require("claudecode.terminal").simple_toggle({ snacks_win_opts = split_win }) end,
        desc = "Toggle Claude (side split)" },
      { "<A-h>",      function() require("claudecode.terminal").focus_toggle({ snacks_win_opts = float_win }) end,
        desc = "Toggle Claude (floating)" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>",   desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select model" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",       desc = "Add buffer to Claude" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>",        mode = "v",           desc = "Send selection to Claude" },
      { "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>",     ft = { "netrw" },     desc = "Add file to Claude" },
      { "<leader>aa", function()
          local file  = vim.fn.expand("%:.")
          local line  = vim.api.nvim_win_get_cursor(0)[1]
          local buf   = vim.api.nvim_get_current_buf()
          local ft    = vim.bo.filetype
          local total = vim.api.nvim_buf_line_count(buf)
          local s     = math.max(0, line - 10)
          local e     = math.min(total, line + 10)
          local snippet = table.concat(vim.api.nvim_buf_get_lines(buf, s, e, false), "\n")
          local context = string.format("Context: %s:%d\n```%s\n%s\n```\n", file, line, ft, snippet)

          local term = require("claudecode.terminal")
          -- submit=false leaves the context in the prompt to edit/extend; focus=true
          -- shows + focuses the terminal (un-hiding a hidden float, never jumping to it).
          local function send()
            term.send_to_terminal(context, { submit = false, focus = true })
          end
          if term.get_active_terminal_bufnr() then
            send()
          else
            -- No session yet: spawn a floating Claude, then paste once it has booted.
            term.focus_toggle({ snacks_win_opts = float_win })
            vim.defer_fn(send, 500)
          end
        end, desc = "Ask Claude with cursor context" },
      { "<leader>aA", "<cmd>ClaudeCodeDiffAccept<cr>",  desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",    desc = "Deny diff" },
    },
    dependencies = { "folke/snacks.nvim" },
    opts = {
      terminal = {
        provider               = "snacks",
        split_side             = "right",
        split_width_percentage = 0.35,
        auto_close             = true,
        -- Default layout/keys for plain commands (resume, continue, context send).
        -- <A-h> and <leader>ac override snacks_win_opts per-call (float / split).
        snacks_win_opts        = { keys = win_keys },
      },
    },
  },
}

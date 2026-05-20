local map = vim.keymap.set

-- ---------------------------------------------------------------------------
-- Netrw
-- ---------------------------------------------------------------------------
map("n", "<leader>pv", vim.cmd.Ex, { desc = "Open netrw" })

-- ---------------------------------------------------------------------------
-- Treat wrapped lines as separate lines for j / k
-- ---------------------------------------------------------------------------
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- ---------------------------------------------------------------------------
-- Move visual selection up / down
-- ---------------------------------------------------------------------------
map("v", "<C-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<C-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- ---------------------------------------------------------------------------
-- Keep the cursor steady on common motions
-- ---------------------------------------------------------------------------
map("n", "J", "mzJ`z")       -- join, cursor stays put
map("n", "<C-d>", "<C-d>zz") -- half-page down, recenter
map("n", "<C-u>", "<C-u>zz") -- half-page up, recenter
map("n", "n", "nzzzv")       -- search next, recenter + unfold
map("n", "N", "Nzzzv")       -- search prev, recenter + unfold

-- ---------------------------------------------------------------------------
-- Paste / yank / delete without trampling the register
-- ---------------------------------------------------------------------------
map("x", "<leader>p", [["_dP]], { desc = "Paste without yanking replaced text" })
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
map("n", "<leader>Y", [["+y$]], { desc = "Yank to EOL into system clipboard" })

-- ---------------------------------------------------------------------------
-- Quickfix / location list navigation
-- ---------------------------------------------------------------------------
map("n", "<C-k>", "<cmd>cnext<CR>zz", { desc = "Next quickfix item" })
map("n", "<C-j>", "<cmd>cprev<CR>zz", { desc = "Prev quickfix item" })
map("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Next location list item" })
map("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Prev location list item" })

-- ---------------------------------------------------------------------------
-- Change word under cursor; repeat with `.` (or `n.` to step + repeat)
-- ---------------------------------------------------------------------------
map("n", "<leader>cw", [[/<C-r><C-w><CR>Ncw]], { desc = "Change word under cursor (repeat with .)" })

-- ---------------------------------------------------------------------------
-- Copilot inline completion: accept suggestion with <Tab>
-- ---------------------------------------------------------------------------
map("i", "<Tab>", function()
  if vim.lsp.inline_completion
      and vim.lsp.inline_completion.get()
  then
    return ""
  end

  return "<Tab>"
end, {
  expr = true,
  replace_keycodes = true,
  desc = "Accept Copilot inline completion or insert <Tab>",
})

-- ---------------------------------------------------------------------------
-- 3-way merge: pick from left / right
-- ---------------------------------------------------------------------------
map("n", "dg<", ":diffget //2<CR>", { desc = "Diffget left  (//2)" })
map("n", "dg>", ":diffget //3<CR>", { desc = "Diffget right (//3)" })

-- ---------------------------------------------------------------------------
-- Misc
-- ---------------------------------------------------------------------------
map("n", "Q", "<nop>")            -- disable Ex mode
map("t", "<Esc>", [[<C-\><C-n>]]) -- exit terminal mode

map({ "n", "v" }, "<leader>fmt", function()
  vim.lsp.buf.format()
  print("Code formatted")
end, { desc = "Format buffer via LSP" })

-- ---------------------------------------------------------------------------
-- User commands
-- ---------------------------------------------------------------------------
vim.api.nvim_create_user_command(
  "TmuxOpenVimConfig",
  function()
    vim.cmd('silent !tmux new-window -n "nvim-config" -c ~/.config/nvim nvim')
  end,
  { desc = "Open nvim config in a new tmux window" }
)

vim.api.nvim_create_user_command("ToggleFoldings", function()
  if vim.o.foldmethod == "manual" then
    vim.o.foldmethod = "expr"
    print("Fold method set to expr")
  else
    vim.o.foldmethod = "manual"
    print("Fold method set to manual")
  end
end, { desc = "Toggle between manual and expr fold methods" })

return {
  {
    "tpope/vim-fugitive",
    cmd = { "G", "Git", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite" },
  },

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
    },
    config = function(_, opts)
      opts.on_attach = function(bufnr)
        local gs = require("gitsigns")

        local function map(mode, lhs, rhs, map_opts)
          map_opts = map_opts or {}
          map_opts.buffer = bufnr
          map_opts.silent = map_opts.silent ~= false
          vim.keymap.set(mode, lhs, rhs, map_opts)
        end

        map("n", "]c", function()
          if vim.wo.diff then
            return "]c"
          end
          vim.schedule(function()
            gs.nav_hunk("next")
          end)
          return "<Ignore>"
        end, { expr = true, desc = "Next git hunk" })

        map("n", "[c", function()
          if vim.wo.diff then
            return "[c"
          end
          vim.schedule(function()
            gs.nav_hunk("prev")
          end)
          return "<Ignore>"
        end, { expr = true, desc = "Previous git hunk" })

        map({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>", { desc = "Stage hunk" })
        map({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>", { desc = "Reset hunk" })
        map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
        map("n", "<leader>hu", gs.stage_hunk, { desc = "Undo stage hunk" })
        map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset buffer" })
        map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
        map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, { desc = "Blame line" })
        map("n", "<leader>hD", function() gs.diffthis("HEAD") end, { desc = "Diff against HEAD" })
        map("n", "<leader>td", gs.toggle_deleted, { desc = "Toggle deleted lines" })
      end

      require("gitsigns").setup(opts)
    end,
  },
}

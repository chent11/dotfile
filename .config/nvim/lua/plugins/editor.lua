return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<C-s>", mode = "c", function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },

  {
    "stevearc/aerial.nvim",
    cmd = { "AerialToggle", "AerialOpen", "AerialPrev", "AerialNext" },
    keys = {
      { "<leader>o", function() require("aerial").toggle({ focus = false }) end, desc = "Toggle outline" },
    },
    opts = {
      on_attach = function(bufnr)
        vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr, desc = "Previous symbol" })
        vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr, desc = "Next symbol" })
      end,
    },
  },

  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = {
      { "<leader>u", vim.cmd.UndotreeToggle, desc = "Toggle undo tree" },
    },
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        icons_enabled = true,
        theme = "gruvbox",
        component_separators = "|",
        section_separators = "",
      },
    },
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
    config = function(_, opts)
      vim.opt.list = true
      require("ibl").setup(opts)
    end,
  },

  {
    "numToStr/Comment.nvim",
    keys = {
      { "gc", mode = { "n", "v" } },
      { "gb", mode = { "n", "v" } },
    },
    opts = {},
  },

  {
    "tzachar/highlight-undo.nvim",
    event = "VeryLazy",
    opts = { duration = 300 },
    keys = {
      { "u", desc = "Undo" },
      { "<C-r>", desc = "Redo" },
    },
  },

  -- {
  --   "kevinhwang91/nvim-ufo",
  --   dependencies = { "kevinhwang91/promise-async" },
  --   enabled = false,
  -- },
}

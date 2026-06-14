return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    keys = {
      -- Top Pickers & Explorer
      { "<leader>:",       function() Snacks.picker.command_history() end, desc = "Command History" },
      { "<leader>n",       function() Snacks.picker.notifications() end,   desc = "Notification History" },
      { "<leader>e",       function() Snacks.explorer() end,               desc = "File Explorer" },
      { "<leader><space>", function() Snacks.picker.smart() end,           desc = "Smart Find Files" },
      -- find
      { "<leader>sb",      function() Snacks.picker.buffers() end,         desc = "Search buffers" },
      { "<leader>/",       function() Snacks.picker.lines() end,           desc = "Search current buffer" },
      { "<leader>sf",      function() Snacks.picker.files() end,           desc = "Search files" },
      {
        "<leader>sw",
        function()
          local mode = vim.fn.mode()
          if mode == "v" or mode == "V" or mode == "\22" then
            vim.cmd('noau normal! "vy')
            local text = vim.fn.getreg("v")
            Snacks.picker.grep({ search = text })
          else
            Snacks.picker.grep_word()
          end
        end,
        mode = { "n", "v" },
        desc = "Search word or selection"
      },
      { "<leader>sg", function() Snacks.picker.grep() end,                 desc = "Search by grep" },
      { "<leader>sd", function() Snacks.picker.diagnostics() end,          desc = "Search diagnostics" },
      { "<leader>sr", function() Snacks.picker.resume() end,               desc = "Resume picker" },
      { '<leader>s/', function() Snacks.picker.search_history() end,       desc = "Search History" },
      { "<leader>sc", function() Snacks.picker.command_history() end,      desc = "Command History" },
      { "<leader>sC", function() Snacks.picker.commands() end,             desc = "Commands" },
      { "<leader>sd", function() Snacks.picker.diagnostics() end,          desc = "Diagnostics" },
      { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end,   desc = "Buffer Diagnostics" },
      { "<leader>su", function() Snacks.picker.undo() end,                 desc = "Undo History" },
      { "<leader>df", function() Snacks.picker.git_status() end,           desc = "Diff files" },
      -- LSP
      { "gd",         function() Snacks.picker.lsp_definitions() end,      desc = "Goto Definition" },
      { "gD",         function() Snacks.picker.lsp_declarations() end,     desc = "Goto Declaration" },
      { "gr",         function() Snacks.picker.lsp_references() end,       nowait = true,                     desc = "References" },
      { "gI",         function() Snacks.picker.lsp_implementations() end,  desc = "Goto Implementation" },
      { "gy",         function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
      -- Other
      { "<leader>z",  function() Snacks.zen() end,                         desc = "Toggle Zen Mode" },
      { "<leader>Z",  function() Snacks.zen.zoom() end,                    desc = "Toggle Zoom" },
      { "<leader>.",  function() Snacks.scratch() end,                     desc = "Toggle Scratch Buffer" },
      { "<leader>S",  function() Snacks.scratch.select() end,              desc = "Select Scratch Buffer" },
      { "<leader>n",  function() Snacks.notifier.show_history() end,       desc = "Notification History" },
      { "<leader>cR", function() Snacks.rename.rename_file() end,          desc = "Rename File" },
    },
    opts = {
      picker       = {
        sources = {
          files = {
            hidden = true,
            args   = { "--no-ignore-vcs", "--ignore-file=.gitignore", "--ignore-file=.fdignore" },
          },
          grep = {
            hidden = true,
            args   = { "--trim", "--no-ignore-vcs", "--ignore-file=.gitignore", "--ignore-file=.fdignore" },
          },
          grep_word = {
            hidden = true,
            args   = { "--word-regexp", "--no-ignore-vcs", "--ignore-file=.gitignore", "--ignore-file=.fdignore" },
          },
        },
        win = {
          input = {
            keys = {
              ["<C-x>"] = { "bufdelete", mode = { "i", "n" } },
              ["<C-h>"] = { "edit_split", mode = { "i", "n" } },
            },
          },
          list = {
            keys = {
              ["<C-x>"] = "bufdelete",
              ["<C-h>"] = "edit_split",
            },
          },
        },
      },
      indent       = {
        enabled = true,
        indent  = { hl = "IblIndent" },
        scope   = { enabled = false },
        chunk   = { enabled = false },
        animate = { enabled = false },
      },
      terminal     = { enabled = true },
      scroll       = { enabled = false },
      dashboard    = { enabled = false },
      explorer     = { enabled = false },
      notifier     = { enabled = false },
      statuscolumn = { enabled = false },
    },
  },
}

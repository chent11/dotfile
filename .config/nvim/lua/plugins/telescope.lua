local function ignore_files()
  local files = {}
  if vim.fn.filereadable(".gitignore") == 1 then
    table.insert(files, ".gitignore")
  end
  if vim.fn.filereadable(".fdignore") == 1 then
    table.insert(files, ".fdignore")
  end
  return files
end

local function make_vimgrep_args()
  local args = {
    "rg",
    "--color=never",
    "--no-heading",
    "--with-filename",
    "--line-number",
    "--column",
    "--smart-case",
    "--hidden",
    "--glob=!.git/",
    "--trim",
    "--no-ignore-vcs",
  }

  for _, file in ipairs(ignore_files()) do
    table.insert(args, "--ignore-file=" .. file)
  end

  return args
end

local function make_find_command()
  local cmd = {
    "fd",
    "--type",
    "f",
    "--strip-cwd-prefix",
    "--hidden",
    "--no-ignore-vcs",
  }

  for _, file in ipairs(ignore_files()) do
    table.insert(cmd, "--ignore-file=" .. file)
  end

  return cmd
end

local function visual_text()
  local old_reg = vim.fn.getreg("v")
  local old_regtype = vim.fn.getregtype("v")
  vim.cmd([[noau normal! "vy]])
  local text = vim.fn.getreg("v")
  vim.fn.setreg("v", old_reg, old_regtype)
  return (text:gsub("\n", " "))
end

return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/aerial.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
    },
    keys = {
      { "<leader>sb", function() require("telescope.builtin").buffers() end, desc = "Search buffers" },
      { "<leader>/", function()
        require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
          winblend = 10,
          previewer = true,
        }))
      end, desc = "Search current buffer" },
      { "<leader>sf", function() require("telescope.builtin").find_files() end, desc = "Search files" },
      { "<leader>sw", function() require("telescope.builtin").grep_string() end, desc = "Search current word" },
      { "<leader>sw", function() require("telescope.builtin").grep_string({ search = visual_text() }) end, mode = "v", desc = "Search selection" },
      { "<leader>sg", function() require("telescope.builtin").live_grep() end, desc = "Search by grep" },
      { "<leader>gg", function() require("telescope.builtin").live_grep({ default_text = "" }) end, desc = "Live grep" },
      { "<leader>gg", function() require("telescope.builtin").live_grep({ default_text = visual_text() }) end, mode = "v", desc = "Grep selection" },
      { "<leader>sd", function() require("telescope.builtin").diagnostics() end, desc = "Search diagnostics" },
      { "<leader>sr", function() require("telescope.builtin").resume() end, desc = "Resume Telescope" },
      { "<leader>df", function() require("telescope.builtin").git_status() end, desc = "Diff files" },
      { "<leader>to", function() require("telescope").extensions.aerial.aerial() end, desc = "Telescope outline" },
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")

      telescope.setup({
        defaults = {
          vimgrep_arguments = make_vimgrep_args(),
          mappings = {
            n = {
              ["<C-x>"] = actions.delete_buffer,
              ["<C-h>"] = actions.select_horizontal,
            },
            i = {
              ["<C-x>"] = actions.delete_buffer,
              ["<C-h>"] = actions.select_horizontal,
            },
          },
        },
        pickers = {
          find_files = {
            find_command = make_find_command(),
          },
        },
        extensions = {
          aerial = {
            show_nesting = {
              ["_"] = false,
              json = true,
              yaml = true,
            },
          },
        },
      })

      pcall(telescope.load_extension, "fzf")
      pcall(telescope.load_extension, "aerial")
    end,
  },
}

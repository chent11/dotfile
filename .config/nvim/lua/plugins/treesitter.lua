local parsers = {
  "c",
  "cpp",
  "go",
  "lua",
  "python",
  "rust",
  "typescript",
  "vim",
  "query",
  "comment",
}

local disabled_languages = {
  asm = true,
  make = true,
  bitbake = true,
  tmux = true,
  dockerfile = true,
}

return {
  {
    -- url = "nvim-treesitter/nvim-treesitter",
    url = "git@github.com:chent11/nvim-treesitter.git",
    branch = "spell-checking-for-string",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      local ok, ts = pcall(require, "nvim-treesitter")
      if not ok then
        return
      end

      ts.setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })
      ts.install(parsers)

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserTreesitterStart", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local ft = vim.bo[bufnr].filetype
          local lang = vim.treesitter.language.get_lang(ft)

          if not lang or disabled_languages[lang] or disabled_languages[ft] then
            return
          end

          if vim.api.nvim_buf_line_count(bufnr) > 100000 then
            vim.notify("Buffer is too large, disabling treesitter highlighting", vim.log.levels.WARN)
            return
          end

          pcall(vim.treesitter.start, bufnr, lang)
        end,
      })
    end,
  },
}

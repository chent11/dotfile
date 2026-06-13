local servers = {
  "pyright",
  "clangd",
  "lua_ls",
  "kotlin_lsp",
}

local mason_servers = {
  "copilot",
  "pyright",
  "clangd",
  "lua_ls",
  "kotlin_lsp",
}

local tools = {
  "prettier",
  "hadolint",
}

return {
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
    },
    config = function()
      local cmp = require("cmp")

      cmp.setup({
        mapping = {
          ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
          ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
          ["<C-y>"] = cmp.mapping.confirm({ select = true }),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<Tab>"] = nil,
          ["<S-Tab>"] = nil,
        },
        sources = {
          { name = "nvim_lsp" },
          { name = "buffer" },
          { name = "path" },
        },
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      { "mason-org/mason.nvim", opts = {} },
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()
      vim.opt.signcolumn = "yes"

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local opts = { buffer = bufnr, remap = false, silent = true }

          vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Go to declaration" }))
          vim.keymap.set("n", "gr", function() Snacks.picker.lsp_references() end, vim.tbl_extend("force", opts, { desc = "References" }))
          vim.keymap.set("n", "gI", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Implementations" }))
          vim.keymap.set("n", "K", function() vim.lsp.buf.hover({ border = "rounded" }) end, vim.tbl_extend("force", opts, { desc = "Hover" }))
          vim.keymap.set("n", "<leader>K", function() vim.lsp.buf.signature_help({ border = "rounded" }) end, vim.tbl_extend("force", opts, { desc = "Signature help" }))
          vim.keymap.set("n", "<leader>lo", function() Snacks.picker.lsp_symbols() end, vim.tbl_extend("force", opts, { desc = "Document symbols" }))
          vim.keymap.set("n", "<C-w>d", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Open diagnostic float" }))
          vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))
          vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, vim.tbl_extend("force", opts, { desc = "Previous diagnostic" }))
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename" }))
          vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature help" }))
        end,
      })

      vim.diagnostic.config({
        virtual_text = {
          severity = { min = vim.diagnostic.severity.WARN },
        },
        float = { border = "rounded" },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.HINT] = "",
            [vim.diagnostic.severity.INFO] = "󰋼",
          },
        },
      })

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_cmp_lsp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if ok_cmp_lsp then
        capabilities = cmp_lsp.default_capabilities(capabilities)
      end

      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
          },
        },
      })

      vim.lsp.config("kotlin_lsp", {
          cmd = {
            "intellij-server",
            "--stdio",
            "--system-path",
            vim.fn.stdpath("cache") .. "/kotlin-lsp/PhairPlay",
          },
          filetypes = { "kotlin" },
          root_markers = {
            "settings.gradle",
            "settings.gradle.kts",
            "pom.xml",
            "build.gradle",
            "build.gradle.kts",
            "workspace.json",
          },
          single_file_support = false,
        })

      local clangd_markers = { ".clangd", "compile_commands.json", "compile_flags.txt", ".git" }
      vim.lsp.config("clangd", {
        cmd = {
          "clangd",
          "--log=error",
          "--background-index",
          "--header-insertion=never",
          "--header-insertion-decorators",
          "--offset-encoding=utf-16",
        },
        root_dir = function(bufnr, on_dir)
          local uri = vim.uri_from_bufnr(bufnr)
          if not vim.startswith(uri, "file://") then
            return
          end

          local fname = vim.api.nvim_buf_get_name(bufnr)
          local root = vim.fs.root(fname, clangd_markers)
          on_dir(root or vim.fs.dirname(fname))
        end,
      })

      require("mason-lspconfig").setup({
        ensure_installed = mason_servers,
        automatic_enable = false,
      })

      require("config.copilot").setup()
      vim.lsp.enable(servers)

      vim.lsp.log.set_level("ERROR")
    end,
  },

  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = tools,
      run_on_start = true,
      auto_update = false,
      debounce_hours = 24,
    },
  },

  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = "ConformInfo",
    opts = {
      formatters_by_ft = {
        yaml = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        markdown = { "prettier" },
      },
      -- format_on_save = {
      --   timeout_ms = 1000,
      --   lsp_format = "fallback",
      -- },
    },
  },

  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        dockerfile = { "hadolint" },
      }

      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("UserLint", { clear = true }),
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },

  { "tpope/vim-sleuth", event = { "BufReadPost", "BufNewFile" } },
}

local servers = {
  'pyright',
  'clangd',
  -- 'ruff',
  'lua_ls',
}

-- Reserve a space in the gutter
vim.opt.signcolumn = 'yes'

-- nvim-cmp setup
local cmp = require('cmp')
local cmp_mappings = {
  ['<C-p>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
  ['<C-n>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
  ['<C-y>'] = cmp.mapping.confirm({ select = true }),
  ['<C-Space>'] = cmp.mapping.complete(),
  ['<Tab>'] = nil,
  ['<S-Tab>'] = nil,
}
cmp.setup({
  mapping = cmp_mappings,
  sources = {
    { name = 'nvim_lsp' },
    { name = 'buffer' },
    { name = 'path' },
  },
})

-- Keymaps on attach
local on_attach = function(_, bufnr)
  local opts = { buffer = bufnr, remap = false }
  vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
  vim.keymap.set("n", "gr", function() require('telescope.builtin').lsp_references() end, opts)
  vim.keymap.set("n", "gI", function() vim.lsp.buf.implementation() end, opts)
  vim.keymap.set("n", "K", function() vim.lsp.buf.hover({ border = "rounded" }) end, opts)
  vim.keymap.set("n", "<leader>K", function() vim.lsp.buf.signature_help({ border = "rounded" }) end, opts)
  vim.keymap.set("n", "<leader>lo", function() require('telescope.builtin').lsp_document_symbols() end, opts)
  vim.keymap.set("n", "<C-w>d", function() vim.diagnostic.open_float(); vim.diagnostic.open_float() end, opts)
  vim.keymap.set("n", "]d", function() vim.diagnostic.jump({count = 1, float = true}) end, opts)
  vim.keymap.set("n", "[d", function() vim.diagnostic.jump({count = -1, float = true}) end, opts)
  vim.keymap.set("n", "<leader>ca", function() vim.lsp.buf.code_action() end, opts)
  vim.keymap.set("n", "<leader>rn", function() vim.lsp.buf.rename() end, opts)
  vim.keymap.set("i", "<C-k>", function() vim.lsp.buf.signature_help() end, opts)
end

-- Diagnostics UI
vim.diagnostic.config({
  virtual_text = {
    severity = {
      min = vim.diagnostic.severity.WARN
    }
  },
  float = {
    border = "rounded",
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.WARN] = '',
      [vim.diagnostic.severity.HINT] = '',
      [vim.diagnostic.severity.INFO] = '󰋼',
    },
  },
})

-- Global defaults for all LSP clients
vim.lsp.config('*', {
  on_attach = on_attach,
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
})

-- Per-server tweaks

-- Lua
vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' }
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
    },
  },
})

-- C/C++
vim.lsp.config('clangd', {
  cmd = {
    "clangd",
    "--log=error",
    "--background-index",
    "--header-insertion=never",
    "--header-insertion-decorators",
    "--offset-encoding=utf-16",
  },
})

-- Mason (installer) + mason-lspconfig (optional QoL)
require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = servers,
  automatic_enable = false, -- we call vim.lsp.enable() ourselves below
})

-- Enable all configured servers
vim.lsp.enable(servers)

-- Logging
vim.lsp.set_log_level("ERROR")
-- vim.lsp.set_log_level("DEBUG")
-- vim.lsp.set_log_level("OFF")

-- null-ls / none-ls (formatters/linters)
local null_ls = require("null-ls")
null_ls.setup({
  sources = {
    -- null_ls.builtins.formatting.isort,
    -- null_ls.builtins.diagnostics.pylint,
    -- null_ls.builtins.formatting.black.with({ filetypes = { "python" } }),
    null_ls.builtins.formatting.prettier.with({
      filetypes = { "yaml", "json", "markdown" },
    }),
    null_ls.builtins.diagnostics.hadolint.with({
      filetypes = { "Dockerfile" },
    }),
  },
})

-- vim.highlight.priorities.semantic_tokens = 90

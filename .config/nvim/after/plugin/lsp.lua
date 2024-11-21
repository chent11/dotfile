local lsp_zero = require("lsp-zero")
local lspconfig = require('lspconfig')

lsp_zero.preset("recommended")

lsp_zero.ensure_installed({
  -- 'tsserver',
  'pyright',
  'lua_ls',
  'clangd',
  'ruff',
})

lspconfig.lua_ls.setup(lsp_zero.nvim_lua_ls())

-- Fix Undefined global 'vim'
lsp_zero.nvim_workspace()

local cmp = require('cmp')
local cmp_select = { behavior = cmp.SelectBehavior.Select }
local cmp_mappings = lsp_zero.defaults.cmp_mappings({
  ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
  ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
  ['<C-y>'] = cmp.mapping.confirm({ select = true }),
  ["<C-Space>"] = cmp.mapping.complete(),
})

cmp_mappings['<Tab>'] = nil
cmp_mappings['<S-Tab>'] = nil

lsp_zero.setup_nvim_cmp({
  mapping = cmp_mappings
})

lsp_zero.set_preferences({
  suggest_lsp_servers = true,
  sign_icons = {
    error = '',
    warn = '',
    hint = '󰞏',
    info = "󰋼"
  }
})

lsp_zero.on_attach(function(_, bufnr)
  local opts = { buffer = bufnr, remap = false }

  vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
  -- vim.keymap.set("n", "gr", function() vim.lsp.buf.references() end, opts)
  vim.keymap.set("n", "gr", function() require('telescope.builtin').lsp_references() end, opts)
  vim.keymap.set("n", "gI", function() vim.lsp.buf.implementation() end, opts)
  vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
  vim.keymap.set("n", "<leader>lo", function() require('telescope.builtin').lsp_document_symbols() end, opts)
  vim.keymap.set("n", "<leader>d", function() vim.diagnostic.open_float() end, opts)
  vim.keymap.set("n", "]d", function() vim.diagnostic.goto_next() end, opts)
  vim.keymap.set("n", "[d", function() vim.diagnostic.goto_prev() end, opts)
  vim.keymap.set("n", "<leader>ca", function() vim.lsp.buf.code_action() end, opts)
  vim.keymap.set("n", "<leader>rn", function() vim.lsp.buf.rename() end, opts)
  vim.keymap.set("i", "<C-k>", function() vim.lsp.buf.signature_help() end, opts)
end)

lspconfig.clangd.setup({
  cmd = {
    "clangd",
    "--log=info",
    "--background-index",
    "--header-insertion=never",
    "--header-insertion-decorators",
    "--offset-encoding=utf-16",
  },
})

vim.lsp.set_log_level("ERROR")
-- vim.lsp.set_log_level("DEBUG")
-- vim.lsp.set_log_level("OFF")

-- require('lspconfig').ruff.setup {
-- }

lspconfig.lua_ls.setup(lsp_zero.nvim_lua_ls())

lsp_zero.setup()

local null_ls = require("null-ls")
null_ls.setup {
  sources = {
    -- null_ls.builtins.formatting.isort,
    -- null_ls.builtins.diagnostics.pylint,
    -- null_ls.builtins.formatting.black.with({
    --   filetypes = { "python" },
    -- }),
    null_ls.builtins.formatting.prettier.with({
      filetypes = { "yaml", "json", "markdown" },
    }),
    null_ls.builtins.diagnostics.hadolint.with({
      filetypes = { "Dockerfile" },
    }),
  },
}

vim.diagnostic.config({
  virtual_text = true
})

-- vim.highlight.priorities.semantic_tokens = 90

local servers = {
  'pyright',
  'clangd',
  'ruff'
}

local lspconfig = require('lspconfig')

-- Reserve a space in the gutter
vim.opt.signcolumn = 'yes'

-- Add cmp_nvim_lsp capabilities settings to lspconfig
-- This should be executed before you configure any language server
local lspconfig_defaults = lspconfig.util.default_config
lspconfig_defaults.capabilities = vim.tbl_deep_extend(
  'force',
  lspconfig_defaults.capabilities,
  require('cmp_nvim_lsp').default_capabilities()
)


require('mason').setup({})
require('mason-lspconfig').setup({ ensure_installed = servers })

local cmp = require('cmp')
local cmp_mappings = {
  ['<C-p>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
  ['<C-n>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
  ['<C-y>'] = cmp.mapping.confirm({ select = true }),
  ["<C-Space>"] = cmp.mapping.complete(),
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

-- Diagnostic signs
local signs = {
  Error = '',
  Warn = '',
  Hint = '',
  Info = '󰋼'
}

for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

local on_attach = function(_, bufnr)
  local opts = { buffer = bufnr, remap = false }

  vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
  -- vim.keymap.set("n", "gr", function() vim.lsp.buf.references() end, opts)
  vim.keymap.set("n", "gr", function() require('telescope.builtin').lsp_references() end, opts)
  vim.keymap.set("n", "gI", function() vim.lsp.buf.implementation() end, opts)
  vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
  vim.keymap.set("n", "<leader>lo", function() require('telescope.builtin').lsp_document_symbols() end, opts)
  vim.keymap.set("n", "<C-w>d", function() vim.diagnostic.open_float(); vim.diagnostic.open_float() end, opts)
  vim.keymap.set("n", "]d", function() vim.diagnostic.goto_next() end, opts)
  vim.keymap.set("n", "[d", function() vim.diagnostic.goto_prev() end, opts)
  vim.keymap.set("n", "<leader>ca", function() vim.lsp.buf.code_action() end, opts)
  vim.keymap.set("n", "<leader>rn", function() vim.lsp.buf.rename() end, opts)
  vim.keymap.set("i", "<C-k>", function() vim.lsp.buf.signature_help() end, opts)
end

-- Configure diagnostic floating window
vim.diagnostic.config({
  virtual_text = {
    severity = {
      min = vim.diagnostic.severity.WARN
    }
  },
  float = {
    border = "rounded",
  },
})

-- LSP handlers with rounded borders
local handlers = {
  ["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" }),
  ["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" }),
}

local capabilities = require('cmp_nvim_lsp').default_capabilities()
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup({
    handlers = handlers,
    on_attach = on_attach,
    capabilities = capabilities,
  })
end

-- Lua LSP
lspconfig.lua_ls.setup({
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

-- C LSP
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

-- vim.highlight.priorities.semantic_tokens = 90

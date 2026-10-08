-- Single source of truth for everything that has to be downloaded for the
-- Neovim setup to work. Consumed by plugins/lsp.lua, plugins/treesitter.lua
-- and bin/nvim-bootstrap.lua (headless install on a fresh machine).
return {
  -- LSP servers: lspconfig names, enabled via vim.lsp.enable() and installed
  -- through mason-lspconfig (which maps them to Mason package names).
  servers = {
    "pyright",
    "clangd",
    "lua_ls",
    "kotlin_lsp",
  },

  -- Non-LSP tools installed through mason-tool-installer (Mason package names).
  tools = {
    "prettier",
    "hadolint",
  },

  -- Treesitter parsers installed into stdpath("data")/site.
  parsers = {
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
    "regex",
    "kotlin",
    "json",
    "yaml",
    "bash",
    "markdown",
    "markdown_inline",
  },
}

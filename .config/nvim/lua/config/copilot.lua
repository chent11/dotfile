local M = {}

M.filetypes = {
  gitcommit = true,
  markdown = true,
  c = true,
  cpp = true,
  lua = true,
  vim = true,
  xml = true,
  python = true,
  javascript = true,
  java = true,
  typescript = true,
  rust = true,
  go = true,
  gdscript = true,
  make = true,
}

function M.setup()
  vim.lsp.config("copilot", {
    cmd = { "copilot-language-server", "--stdio" },
    filetypes = vim.tbl_keys(M.filetypes),
    init_options = {
      editorInfo = {
        name = "Neovim",
        version = tostring(vim.version()),
      },
      editorPluginInfo = {
        name = "Neovim",
        version = tostring(vim.version()),
      },
    },
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("UserCopilotAutoStart", { clear = true }),
    callback = function(args)
      if M.filetypes[vim.bo[args.buf].filetype] then
        vim.lsp.start(vim.lsp.config.copilot, { bufnr = args.buf })
        vim.lsp.inline_completion.enable(true)
      end
    end,
  })

  vim.keymap.set("n", "<leader>cp", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({ name = "copilot", bufnr = bufnr })

    if #clients > 0 then
      for _, client in ipairs(clients) do
        client:stop()
      end
      vim.lsp.inline_completion.enable(false)
      print("Copilot LSP disabled for this buffer")
    else
      vim.lsp.start(vim.tbl_extend("force", vim.lsp.config.copilot, {
        filetypes = nil,
      }), { bufnr = bufnr })

      vim.lsp.inline_completion.enable(true)
      print("Copilot LSP manually enabled for this buffer")
    end
  end, { desc = "Toggle Copilot LSP for this buffer" })
end

return M

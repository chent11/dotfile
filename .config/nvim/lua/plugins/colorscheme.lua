local function set_custom_highlights()
  vim.api.nvim_set_hl(0, "IblIndent", { fg = "#444444", nocombine = true })
end

return {
  {
    "morhetz/gruvbox",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("gruvbox")
      set_custom_highlights()

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("UserColorHighlights", { clear = true }),
        callback = set_custom_highlights,
      })
    end,
  },
  { "rose-pine/neovim", name = "rose-pine", lazy = true },
  { "navarasu/onedark.nvim", lazy = true },
  { "sainnhe/everforest", lazy = true },
  { "sainnhe/gruvbox-material", lazy = true },
}

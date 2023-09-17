-- vim.opt.listchars:append "space:⋅"
require('indent_blankline').setup {
    show_trailing_blankline_indent = true,
    char_highlight_list = {
        "IndentBlanklineIndent1",
    },
}
vim.opt.list = true

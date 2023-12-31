local mark = require("harpoon.mark")
local ui = require("harpoon.ui")

vim.keymap.set("n", "<leader>fa", mark.add_file)
vim.keymap.set("n", "<C-q>", ui.toggle_quick_menu)

vim.keymap.set("n", "L", function() ui.nav_next() end)
vim.keymap.set("n", "H", function() ui.nav_prev() end)

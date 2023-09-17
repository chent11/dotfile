if true then
    return
end

local myprint = function(msg)
    if msg then
        os.execute('echo "' .. msg .. '" > /tmp/debug-feedback-vim &')
    else
        os.execute('echo "' .. 'nil' .. '" > /tmp/debug-feedback-vim &')
    end
end

local bufferline = require("bufferline")
local harpoon_mark = require("harpoon.mark")

local marked_files = {}
local num_marked_files = harpoon_mark.get_length()

for i = 1, num_marked_files do
    local marked_file = harpoon_mark.get_marked_file(i)
    if marked_file then
        table.insert(marked_files, marked_file.filename)
    end
end

for _, filename in ipairs(marked_files) do
    local bufnr = vim.fn.bufnr(filename)
    if bufnr == -1 then -- Buffer is not opened
        vim.api.nvim_command('badd ' .. filename)
    end
end

local first_marked_file = harpoon_mark.get_marked_file(1)
if first_marked_file and first_marked_file.filename then
    vim.api.nvim_command('edit ' .. first_marked_file.filename)
end

bufferline.setup {
    options = {
        numbers = function(opts)
            return string.format('#%s', opts.id)
        end,
        -- custom_filter = function(buf_number, buf_numbers)
        --     local buf_name = vim.api.nvim_buf_get_name(buf_number)
        --     local is_marked = harpoon_mark.get_index_of(buf_name)
        --
        --     if is_marked then
        --         return true
        --     end
        --
        --     return false
        -- end,
    }
}

-- Set up the autocmd using vim.api.nvim_create_autocmd
-- vim.api.nvim_create_autocmd({ "BufDelete" }, {
--     pattern = "*",
--     callback = function(bufnr)
--         -- local buf_name = vim.fn.expand('<afile>')
--         --
--         -- if not buf_name or buf_name == "" then
--         --     return
--         -- end
--         --
--         local id = harpoon_mark.get_index_of(bufnr.buf)
--
--         if id then
--             harpoon_mark.rm_file(id)
--         end
--     end
-- })

vim.keymap.set('n', 'H', ':BufferLineCyclePrev<CR>', { desc = '[H] Move Buffer to the Previous One' })
vim.keymap.set('n', 'L', ':BufferLineCycleNext<CR>', { desc = '[L] Move Buffer to the Next One' })
vim.keymap.set('n', '<leader>H', ':BufferLineMovePrev<CR>', { desc = '' })
vim.keymap.set('n', '<leader>L', ':BufferLineMoveNext<CR>', { desc = '' })
vim.keymap.set('n', '<leader>qH', ':BufferLineCloseLeft<CR>', { desc = '' })
vim.keymap.set('n', '<leader>qL', ':BufferLineCloseRight<CR>', { desc = '' })
vim.keymap.set('n', '<leader>qo', '<C-O> :bdelete #<CR> :<CR>', { desc = '' }) -- The last command ":<CR>" is for updating the UI
vim.keymap.set('n', '<leader>qq', ':BufferLineCyclePrev <CR> :bdelete #<CR> :<CR>', { desc = '' })
vim.keymap.set('n', '<leader>qp', ':BufferLinePickClose<CR>', { desc = '[q] Pick a Buffer to Close' })
vim.keymap.set('n', '<leader>p', ':BufferLinePick<CR>', { desc = 'Pick a Buffer' })

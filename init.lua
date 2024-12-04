vim.g.mapleader = " "

require("telescope").setup({})
require("telescope").load_extension('file_browser')
require("telescope").load_extension('project')
require("hop").setup({})

function IsChadTreeOpen()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.api.nvim_buf_get_option(buf, "filetype") == "CHADTree" then
            return true
        end
    end
    return false
end

function ToggleChadTree()
    local current_buf = vim.api.nvim_get_current_buf()
    if IsChadTreeOpen() then
        if vim.api.nvim_buf_get_option(current_buf, "filetype") == "CHADTree" then
            vim.cmd("CHADopen")
        else
            for _, win in ipairs(vim.api.nvim_list_wins()) do
                local buf = vim.api.nvim_win_get_buf(win)
                if vim.api.nvim_buf_get_option(buf, "filetype") == "CHADTree" then
                    vim.api.nvim_set_current_win(win)
                    return
                end
            end
        end
    else
        vim.cmd("CHADopen")
    end
end
do
    local keybindings = {
        { action = "<cmd>Telescope find_files<cr>", key = "<leader> ", mode = "n" },
        { action = "<cmd>Telescope buffers<cr>", key = "<leader>b", mode = "n" },
        { action = "<cmd>Telescope live_grep<cr>", key = "<leader>g", mode = "n" },
        { action = "<cmd>Telescope jumplist<cr>", key = "<leader>o", mode = "n" },
        { action = "<cmd>Telescope oldfiles<cr>", key = "<leader>p", mode = "n" },
        { action = "<NOP>", key = " ", mode = "n" },
        { action = ":Telescope file_browser<CR>", key = "<leader>ft", mode = "n" },
        { action = ":Telescope project<CR>", key = "<leader>fp", mode = "n" },
        { action = ":lua ToggleChadTree()<CR>", key = "<C-e>", mode = "n", options = { remap = true } },
        {
            action = function()
                require("hop").hint_char2({
                    direction = require("hop.hint").HintDirection.AFTER_CURSOR,
                })
            end,
            key = "<leader>j",
            mode = "",
        },
        {
            action = function()
                require("hop").hint_char2({
                    direction = require("hop.hint").HintDirection.BEFORE_CURSOR,
                })
            end,
            key = "<leader>k",
            mode = "",
        },
    }
    for i, map in ipairs(keybindings) do
        vim.keymap.set(map.mode, map.key, map.action, map.options)
    end
end

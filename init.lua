vim.g.mapleader = " "
vim.g.vsnip_snippet_dir = vim.fn.stdpath("config") .. "/vsnip"
vim.cmd("colorscheme catppuccin-mocha")
vim.api.nvim_set_option_value("termguicolors", true, {})
require("telescope").setup({})
require("telescope").load_extension('file_browser')
require("telescope").load_extension('project')
require("hop").setup({})
require("dapui").setup()
require("trouble").setup()
require("Comment").setup()
local cmp = require("cmp")

function IsChadTreeOpen()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.api.nvim_get_option_value("filetype", {buf = buf}) == "CHADTree" then
            return true
        end
    end
    return false
end

function ToggleChadTree()
    local current_buf = vim.api.nvim_get_current_buf()
    if IsChadTreeOpen() then
        if vim.api.nvim_get_option_value("filetype", {buf = current_buf}) == "CHADTree" then
            vim.cmd("CHADopen")
        else
            for _, win in ipairs(vim.api.nvim_list_wins()) do
                local buf = vim.api.nvim_win_get_buf(win)
                if vim.api.nvim_get_option_value("filetype", {buf = buf}) == "CHADTree" then
                    vim.api.nvim_set_current_win(win)
                    return
                end
            end
        end
    else
        vim.cmd("CHADopen")
    end
end

local has_words_before = function()
  unpack = unpack or table.unpack
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local feedkey = function(key, mode)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
end

local lspServers = {
    { name = "pyright" },
    { name = "bashls" },
    { name = "lua_ls", extraOptions = {
      settings = {
        Lua = {
          runtime = {
            version = "LuaJIT",
            path = vim.split(package.path, ";"),
          },
          diagnostics = {
            globals = { "vim" },
          },
          workspace = {
            library = vim.api.nvim_get_runtime_file("", true),
            checkThirdParty = false,
          },
          telemetry = {
            enable = false,
          },
        },
      },
    }},
}

cmp.setup({
    snippet = {
        expand = function(args)
            vim.fn["vsnip#anonymous"](args.body)
        end,
    },
    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
    mapping = {
        ['<C-u>'] = cmp.mapping.scroll_docs(-4),
        ['<C-d>'] = cmp.mapping.scroll_docs(4),
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                if #cmp.get_entries() == 1 then
                    cmp.confirm({ select = true })
                else
                    cmp.select_next_item()
                end
            elseif vim.fn["vsnip#available"](1) then
                feedkey("<Plug>(vsnip-expand-or-jump)", "")
            elseif has_words_before() then
                cmp.complete()
                if #cmp.get_entries() == 1 then
                    cmp.confirm({ select = true })
                end
            else
                fallback()
            end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function()
            if cmp.visible() then
                cmp.select_prev_item()
            elseif vim.fn["vsnip#jumpable"](-1) == 1 then
                feedkey("<Plug>(vsnip-jump-prev)", "")
            end
        end, { "i", "s" }),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
    },
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'vsnip' },
        { name = 'nvim_lsp_signature_help' },
    }, {
        { name = 'buffer' },
    })
})
local cmdlineMapping = {
    ['<Tab>'] = {
        c = function(_)
            if cmp.visible() then
                if #cmp.get_entries() == 1 then
                    cmp.confirm({ select = true })
                else
                    cmp.select_next_item()
                end
            else
                cmp.complete()
                if #cmp.get_entries() == 1 then
                    cmp.confirm({ select = true })
                end
            end
        end,
    },
    ['<S-Tab>'] = {
        c = function()
            if cmp.visible() then
                cmp.select_prev_item()
            else
                cmp.complete()
            end
        end,
    },
    ['<CR>'] = cmp.mapping.complete(),
}
cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmdlineMapping,
    sources = {
        { name = 'buffer' }
    }
})

cmp.setup.cmdline(':', {
    mapping = cmdlineMapping,
    sources = cmp.config.sources({
        { name = 'path' }
    }, {
        { name = 'cmdline' }
    }),
    matching = { disallow_symbol_nonprefix_matching = false }
})

local capabilities = require('cmp_nvim_lsp').default_capabilities()
for _, lspServer in ipairs(lspServers) do
    require('lspconfig')[lspServer.name].setup(
        vim.tbl_deep_extend(
            "force",
            lspServer.extraOptions or vim.empty_dict(),
            { capabilities = capabilities }
        )
    )
end

local dap = require('dap')
dap.adapters.python = function(cb, config)
    if config.request == 'attach' then
        ---@diagnostic disable-next-line: undefined-field
        local port = (config.connect or config).port or 5678
        ---@diagnostic disable-next-line: undefined-field
        local host = (config.connect or config).host or '127.0.0.1'
        cb({
            type = 'server',
            port = assert(port, '`connect.port` is required for a python `attach` configuration'),
            host = host,
            options = {
                source_filetype = 'python',
            },
        })
    end
end
dap.configurations.python = {
    {
        type = 'python';
        request = 'attach';
        name = "Default attach";
    }
}
-- dap.adapters.bashdb = {
--   type = 'executable';
--   command = '/home/z/bash-debug-adapter';
--   name = 'bashdb';
-- }
-- dap.configurations.sh = {
--   {
--     type = 'bashdb';
--     request = 'launch';
--     name = "Launch file";
--     showDebugOutput = true;
--     pathBashdb = '/home/z/Downloads/bashdb/bashdb-5.0-1.1.2/bashdb';
--     pathBashdbLib = '/home/z/Downloads/bashdb/bashdb-5.0-1.1.2';
--     trace = true;
--     file = "${file}";
--     program = "${file}";
--     cwd = '${workspaceFolder}';
--     pathCat = "cat";
--     pathBash = "/bin/bash";
--     pathMkfifo = "mkfifo";
--     pathPkill = "pkill";
--     args = {};
--     env = {};
--     terminalKind = "integrated";
--   }
-- }
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
        { action = function() vim.lsp.buf.hover() end, key = "<C-p>", mode = {"n", "i"}, options = { remap = true } },
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
    for _, map in ipairs(keybindings) do
        vim.keymap.set(map.mode, map.key, map.action, map.options)
    end
end

vim.diagnostic.config({ signs = false })

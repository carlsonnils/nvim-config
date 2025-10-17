

-- options
vim.opt.packpath:prepend("~/.config/nvim/site")
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.tabstop = 4
vim.o.autoindent = true
vim.o.number = true
vim.o.relativenumber = true
-- vim.o.wrap = false
-- vim.o.sidescrolloff = 10
-- vim.o.scrolloff = 5
vim.o.signcolumn = "yes:1"
vim.o.undofile = true
vim.opt.clipboard:append("unnamedplus")


-- set color scheme
vim.pack.add({'https://github.com/rebelot/kanagawa.nvim.git'})
vim.cmd.colorscheme("kanagawa")
vim.api.nvim_set_hl(0, 'Normal', { bg = 'NONE' })
local normal_bg = vim.api.nvim_get_hl(0, {name = 'Normal'}).bg
local linenr_fg = vim.api.nvim_get_hl(0, {name = 'LineNr'}).fg
vim.api.nvim_set_hl(0, 'LineNr', { bg = normal_bg, fg = linenr_fg })


-- global floating window borders
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
    opts = opts or {}
    opts.border = opts.border or "rounded"
    return orig_util_open_floating_preview(contents, syntax, opts, ...)
end


-- treesitter
vim.pack.add({'https://github.com/nvim-treesitter/nvim-treesitter.git'})
require('nvim-treesitter.configs').setup({
    ensure_installed = { "c", "lua", "vim", "vimdoc", "javascript", "markdown", "python", "html", "css", "go", "csv" },
    sync_install = false,
    auto_install = true,
    highlight = {
        enable = true,
        disable = function(lang, buf)
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
                return true
            end
        end,
        additional_vim_regex_highlighting = false,
    },
})


-- mason: manage lsp server
vim.pack.add({'https://github.com/mason-org/mason.nvim.git'})
require('mason').setup()


-- lspconfig
vim.pack.add({'https://github.com/neovim/nvim-lspconfig'})
-- pyright
vim.lsp.config('pyright', {
    settings = {
        python = {
            analysis = {
                diagnosticMode = 'workspace',
            },
        },
    }
})
vim.lsp.enable('pyright')
-- lua language server
vim.lsp.enable('lua_ls')
-- gopls language server
vim.lsp.enable('gopls')


-- lsp keymaps
local on_attach = function(client, bufnr)
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', '<leader>d', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', '<leader>i', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', '<leader>r', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, bufopts)
end


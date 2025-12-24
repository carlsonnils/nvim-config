-- options
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.tabstop = 4
vim.o.autoindent = true
vim.o.number = true
vim.o.relativenumber = true
-- vim.o.wrap = false
-- vim.o.sidescrolloff = 10
vim.o.scrolloff = 3
vim.o.signcolumn = "yes:1"
vim.o.undofile = true
vim.opt.clipboard:append("unnamedplus")
vim.g.mapleader = " "
vim.g.localmapleader = " "


-- set color scheme
vim.pack.add({'https://github.com/rebelot/kanagawa.nvim.git'})
vim.cmd.colorscheme("kanagawa-lotus")
-- vim.api.nvim_set_hl(0, 'Normal', { bg = 'NONE' })
-- local normal_bg = vim.api.nvim_get_hl(0, {name = 'Normal'}).bg
-- local linenr_fg = vim.api.nvim_get_hl(0, {name = 'LineNr'}).fg
-- vim.api.nvim_set_hl(0, 'LineNr', { bg = normal_bg, fg = linenr_fg })


-- global floating window borders
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
    opts = opts or {}
    opts.border = opts.border or "rounded"
    return orig_util_open_floating_preview(contents, syntax, opts, ...)
end


-- treesitter
vim.pack.add({'https://github.com/nvim-treesitter/nvim-treesitter.git'})
require('nvim-treesitter').setup(require('nvim-treesitter-setup'))


-- mason: manage lsp server
vim.pack.add({'https://github.com/mason-org/mason.nvim.git'})
require('mason').setup()


-- lspconfig
-- vim.pack.add({'https://github.com/neovim/nvim-lspconfig'})
-- pyright
vim.lsp.config('pyright', require('lsp.pyright'))
vim.lsp.enable('pyright')
-- lua language server
vim.lsp.enable('lua_ls')
-- gopls language server
vim.lsp.enable('gopls')
-- ruff for python
vim.lsp.config('ruff', require('lsp.ruff'))
vim.lsp.enable('ruff')
-- superhtml
vim.lsp.enable('superhtml')
-- clangd
vim.lsp.config('clangd', require('lsp.clangd'))
vim.lsp.enable('clangd')


-- lsp keymaps
local lsp_keymap_on_attach = function(client, bufnr)
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', '<Leader>d', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', '<Leader>i', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<Leader>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<Leader>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', '<Leader>r', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<Leader>f', function() vim.lsp.buf.format { async = true } end, bufopts)
end
vim.api.nvim_create_autocmd("LspAttach", {
  pattern = { "*.py", "*.go", ".lua", ".html", ".css", ".c", ".js" },
  callback = lsp_keymap_on_attach,
})


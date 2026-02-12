-- OS NAME
--
--
local uname = vim.loop.os_uname()
local function is_windows() return uname.sysname == "Windows_NT" end
local function is_linux() return uname.sysname == "Linux" end
local function is_macos() return uname.sysname == "Darwin" end



-- OPTIONS
--
--
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.tabstop = 4
vim.o.autoindent = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.wrap = false
vim.o.sidescrolloff = 2
vim.o.scrolloff = 2
vim.o.signcolumn = "yes:1"
vim.o.undofile = true
vim.opt.clipboard:append("unnamedplus")
vim.g.mapleader = " "
vim.g.localmapleader = " "
if is_windows() then
    vim.opt.shell = "powershell"
    vim.opt.shellcmdflag = "-NoLogo -Command"
    vim.opt.shellquote = ""
    vim.opt.shellxquote = ""
end
if is_linux() then
    vim.opt.shell = "bash"
    vim.opt.shellcmdflag = ""
    vim.opt.shellquote = ""
    vim.opt.shellxquote = ""
end



-- CUSTOM KEYMAPS
--
--
vim.keymap.set('n', '<Leader>tj', ':below sp term://powershell<CR>i', { desc = 'Open terminal below' })
vim.keymap.set('n', '<Leader>tl', ':rightbelow vsp term://powershell<CR>i', { desc = 'Open terminal right' })
vim.keymap.set('n', '<Leader>h', '<C-w>h', { desc = 'Move to right window' })
vim.keymap.set('n', '<Leader>j', '<C-w>j', { desc = 'Move to below window' })
vim.keymap.set('n', '<Leader>k', '<C-w>k', { desc = 'Move to above window' })
vim.keymap.set('n', '<Leader>l', '<C-w>l', { desc = 'Move to left window' })
vim.keymap.set('n', '<Leader>u', ':resize +2<CR>', { desc = 'Move to right window' })
vim.keymap.set('n', '<Leader>p', ':resize -2<CR>', { desc = 'Move to right window' })
vim.keymap.set('n', '<Leader>i', ':vertical resize +2<CR>', { desc = 'Move to right window' })
vim.keymap.set('n', '<Leader>o', ':vertical resize -2<CR>', { desc = 'Move to right window' })



-- COLOR SCHEME
--
--
vim.pack.add({'https://github.com/rebelot/kanagawa.nvim.git'})
vim.cmd.colorscheme("kanagawa-lotus")
-- vim.api.nvim_set_hl(0, 'Normal', { bg = 'NONE' })
-- local normal_bg = vim.api.nvim_get_hl(0, {name = 'Normal'}).bg
-- local linenr_fg = vim.api.nvim_get_hl(0, {name = 'LineNr'}).fg
-- vim.api.nvim_set_hl(0, 'LineNr', { bg = normal_bg, fg = linenr_fg })



-- TREESITTER
--
--
vim.pack.add({'https://github.com/nvim-treesitter/nvim-treesitter.git'})
require('nvim-treesitter').setup(require('nvim-treesitter-setup'))



-- TELESCOPE
--
--
vim.pack.add({
    { src = 'https://github.com/nvim-lua/plenary.nvim.git' },
    { src = 'https://github.com/sharkdp/fd.git' },
    { src = 'https://github.com/nvim-telescope/telescope.nvim.git' },
})
local actions = require('telescope.actions')
require('telescope').setup({
  defaults = {
    mappings = {
      n = {  -- normal mode mappings
        ["<C-b>"] = "delete_buffer",
      },
      i = {  -- insert mode mappings
        -- ["<C-b>"] = "delete_buffer",
      },
    },
  },
})
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })



-- GLOBAL FLOATING WINDOW BORDERS
--
--
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
    opts = opts or {}
    opts.border = opts.border or "rounded"
    return orig_util_open_floating_preview(contents, syntax, opts, ...)
end



-- LSP
--
--
-- mason: manage lsp servers
vim.pack.add({'https://github.com/mason-org/mason.nvim.git'})
require('mason').setup()

-- lspconfig
vim.pack.add({'https://github.com/neovim/nvim-lspconfig'})

-- pyright
vim.lsp.config('pyright', require('lsp.pyright'))
vim.lsp.enable('pyright')
require('pyright-setup')

-- lua language server
vim.lsp.enable('lua_ls')

-- gopls language server
vim.lsp.enable('gopls')

-- ruff for python
-- vim.lsp.config('ruff', require('lsp.ruff'))
-- vim.lsp.enable('ruff')

-- superhtml
vim.lsp.enable('superhtml')

-- clangd
vim.lsp.config('clangd', require('lsp.clangd'))
vim.lsp.enable('clangd')

-- marksman
vim.lsp.config('marksman', require('lsp.marksman'))
vim.lsp.enable('marksman')

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



-- MARKDOWN RENDERING
--
--
-- vim.pack.add({
--     -- { src = 'https://github.com/nvim-treesitter/nvim-treesitter' },    -- already added
--     { src = 'https://github.com/nvim-mini/mini.nvim' },            -- if you use the mini.nvim suite
--     { src = 'https://github.com/nvim-mini/mini.icons' },        -- if you use standalone mini plugins
--     { src = 'https://github.com/nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
--     { src = 'https://github.com/MeanderingProgrammer/render-markdown.nvim' },
-- })



-- Git Help
-- 
--
vim.pack.add({
    { src = 'https://github.com/lewis6991/gitsigns.nvim.git' }
})
require('gitsigns').setup {
  signs = {
    add          = { text = '+' },
    change       = { text = '┃' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
    untracked    = { text = '┆' },
  },
  signs_staged = {
    add          = { text = '+' },
    change       = { text = '┃' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
    untracked    = { text = '┆' },
  },
  signs_staged_enable = true,
  signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
  numhl      = false, -- Toggle with `:Gitsigns toggle_numhl`
  linehl     = true, -- Toggle with `:Gitsigns toggle_linehl`
  word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
  watch_gitdir = {
    follow_files = true
  },
  auto_attach = true,
  attach_to_untracked = false,
  current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
    delay = 1000,
    ignore_whitespace = false,
    virt_text_priority = 100,
    use_focus = true,
  },
  current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
  sign_priority = 6,
  update_debounce = 100,
  status_formatter = nil, -- Use default
  max_file_length = 40000, -- Disable if file is longer than this (in lines)
  preview_config = {
    -- Options passed to nvim_open_win
    style = 'minimal',
    relative = 'cursor',
    row = 0,
    col = 1
  },
}



-- CSV Viewer
--
--
vim.pack.add({
    { src = "https://github.com/hat0uma/csvview.nvim.git" }
})
require('csvview').setup({
    view = {
        display_mode = "border",
    }
})

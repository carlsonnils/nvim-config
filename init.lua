-- OS DETECTION
local init_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local uname = vim.uv.os_uname()
local function is_windows() return uname.sysname == 'Windows_NT' end
local function is_linux() return uname.sysname == 'Linux' end
local function is_macos() return uname.sysname == 'Darwin' end

-- Ensure XDG_RUNTIME_DIR is valid so Neovim RPC sockets (used by fzf-lua) work
if vim.env.XDG_RUNTIME_DIR and vim.fn.filewritable(vim.env.XDG_RUNTIME_DIR) ~= 2 then
    vim.env.XDG_RUNTIME_DIR = nil
end


-- DISABLE NETRW & BUILT-IN SQL OMNICOMPLETION (must happen before plugins/ftplugins load)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.omni_sql_no_default_maps = 1


-- LEADER KEYS
vim.g.mapleader = ' '
vim.g.localmapleader = ' '


-- OPTIONS
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
vim.o.signcolumn = 'yes:1'
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.updatetime = 250
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.winborder = 'rounded'
vim.o.completeopt = 'menuone,noselect,popup'
vim.opt.clipboard:append('unnamedplus')

if is_windows() then
    vim.opt.shell = 'powershell'
    vim.opt.shellcmdflag = '-NoLogo -Command'
    vim.opt.shellquote = ''
    vim.opt.shellxquote = ''
    vim.opt.shellpipe = '2>&1 | Out-File -FilePath %s -Encoding ascii -Force'
end
if is_linux() then
    vim.opt.shell = 'bash'
    vim.opt.shellcmdflag = '-c'
    vim.opt.shellquote = ''
    vim.opt.shellxquote = ''
end


-- GENERAL, WINDOW & TERMINAL KEYMAPS
vim.keymap.set('n', '<Esc>', '<Cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('t', '<M-Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode (fast double-Esc)' })
vim.keymap.set('i', '<C-x><C-o>', '<Nop>', { desc = 'Disable omnicompletion' })

vim.api.nvim_create_autocmd({ 'FileType', 'BufEnter' }, {
    desc = 'Keep omnifunc disabled across all filetypes (overrides built-in ftplugins)',
    callback = function(ev)
        vim.bo[ev.buf].omnifunc = ''
        vim.schedule(function()
            if vim.api.nvim_buf_is_valid(ev.buf) then
                vim.bo[ev.buf].omnifunc = ''
            end
        end)
    end,
})

local float_term_buf = nil
local float_term_win = nil
local float_term_origin_win = nil

local function hide_float_term()
    if float_term_win and vim.api.nvim_win_is_valid(float_term_win) then
        pcall(vim.api.nvim_win_close, float_term_win, true)
        float_term_win = nil
    end
    if float_term_origin_win and vim.api.nvim_win_is_valid(float_term_origin_win) then
        vim.api.nvim_set_current_win(float_term_origin_win)
    end
end

local function toggle_float_term()
    if float_term_win and vim.api.nvim_win_is_valid(float_term_win) then
        hide_float_term()
        return
    end

    local cur_win = vim.api.nvim_get_current_win()
    float_term_origin_win = cur_win

    local need_spawn = false
    if not (float_term_buf and vim.api.nvim_buf_is_valid(float_term_buf)) then
        float_term_buf = vim.api.nvim_create_buf(false, true)
        vim.bo[float_term_buf].bufhidden = 'hide'
        vim.bo[float_term_buf].swapfile = false
        vim.keymap.set('n', 'q', hide_float_term, { buffer = float_term_buf, nowait = true, desc = 'Hide floating terminal' })
        vim.keymap.set('n', '<Esc>', hide_float_term, { buffer = float_term_buf, nowait = true, desc = 'Hide floating terminal' })
        need_spawn = true
    end

    local width = math.min(math.max(60, math.floor(vim.o.columns * 0.85)), math.max(20, vim.o.columns - 4))
    local height = math.min(math.max(14, math.floor(vim.o.lines * 0.8)), math.max(6, vim.o.lines - 4))

    float_term_win = vim.api.nvim_open_win(float_term_buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
        col = math.max(0, math.floor((vim.o.columns - width) / 2)),
        style = 'minimal',
        border = 'rounded',
        title = ' Terminal (<Esc><Esc> normal | q/<Esc> hide | exit quit) ',
        title_pos = 'center',
    })

    if need_spawn then
        local term_buf = float_term_buf
        vim.api.nvim_buf_call(term_buf, function()
            vim.fn.jobstart(vim.o.shell, {
                term = true,
                on_exit = function()
                    vim.schedule(function()
                        if
                            float_term_win
                            and vim.api.nvim_win_is_valid(float_term_win)
                            and vim.api.nvim_win_get_buf(float_term_win) == term_buf
                        then
                            hide_float_term()
                        end
                        if vim.api.nvim_buf_is_valid(term_buf) then
                            pcall(vim.api.nvim_buf_delete, term_buf, { force = true })
                        end
                        if float_term_buf == term_buf then
                            float_term_buf = nil
                        end
                    end)
                end,
            })
        end)
    end

    vim.cmd.startinsert()
end

vim.keymap.set('n', '<Leader>tf', toggle_float_term, { desc = 'Toggle floating terminal' })
vim.keymap.set('n', '<Leader>tj', ':below sp | terminal<CR>i', { desc = 'Open terminal below' })
vim.keymap.set('n', '<Leader>tk', ':above sp | terminal<CR>i', { desc = 'Open terminal above' })
vim.keymap.set('n', '<Leader>tl', ':rightbelow vsp | terminal<CR>i', { desc = 'Open terminal right' })
vim.keymap.set('n', '<Leader>th', ':leftabove vsp | terminal<CR>i', { desc = 'Open terminal left' })
vim.keymap.set('n', '<Leader>h', '<C-w>h', { desc = 'Move to left window' })
vim.keymap.set('n', '<Leader>j', '<C-w>j', { desc = 'Move to below window' })
vim.keymap.set('n', '<Leader>k', '<C-w>k', { desc = 'Move to above window' })
vim.keymap.set('n', '<Leader>l', '<C-w>l', { desc = 'Move to right window' })
vim.keymap.set('n', '<Leader>u', ':resize +4<CR>', { desc = 'Increase window height' })
vim.keymap.set('n', '<Leader>p', ':resize -4<CR>', { desc = 'Decrease window height' })
vim.keymap.set('n', '<Leader>i', ':vertical resize +4<CR>', { desc = 'Increase window width' })
vim.keymap.set('n', '<Leader>o', ':vertical resize -4<CR>', { desc = 'Decrease window width' })


-- PLUGINS (built-in vim.pack)
vim.api.nvim_create_autocmd('PackChanged', {
    desc = 'Update Treesitter parsers when nvim-treesitter updates',
    callback = function(ev)
        if ev.data.spec.name == 'nvim-treesitter' and ev.data.kind == 'update' then
            if not ev.data.active then
                vim.cmd.packadd('nvim-treesitter')
            end
            if vim.fn.executable('tree-sitter') == 1 then
                vim.cmd('TSUpdate')
            end
        end
    end,
})

vim.pack.add({
    'https://github.com/rebelot/kanagawa.nvim.git',
    'https://github.com/nvim-mini/mini.icons.git',
    'https://github.com/stevearc/oil.nvim.git',
    'https://github.com/ibhagwan/fzf-lua.git',
    'https://github.com/lewis6991/gitsigns.nvim.git',
    'https://github.com/nvim-treesitter/nvim-treesitter.git',
    'https://github.com/neovim/nvim-lspconfig.git',
    'https://github.com/stevearc/conform.nvim.git',
    'https://github.com/Kurren123/mssql.nvim.git',
})

vim.api.nvim_create_user_command('PackUpdate', function()
    vim.pack.update()
end, { desc = 'Update plugins managed by vim.pack' })


-- COLOR SCHEME (Kanagawa: wave, dragon, lotus)
require('kanagawa').setup({})
vim.cmd.colorscheme('kanagawa-wave')

vim.keymap.set('n', '<Leader>cw', '<Cmd>colorscheme kanagawa-wave<CR>', { desc = 'Theme: Kanagawa Wave' })
vim.keymap.set('n', '<Leader>cd', '<Cmd>colorscheme kanagawa-dragon<CR>', { desc = 'Theme: Kanagawa Dragon' })
vim.keymap.set('n', '<Leader>cl', '<Cmd>colorscheme kanagawa-lotus<CR>', { desc = 'Theme: Kanagawa Lotus' })


-- ICONS
require('mini.icons').setup()
MiniIcons.mock_nvim_web_devicons()


-- OIL FILE BROWSER
require('oil').setup({
    default_file_explorer = true,
    columns = {
        "permissions",
        "size",
        "mtime",
        "icon",
    },
    view_options = {
        show_hidden = true,
    },
})
vim.keymap.set('n', '-', '<Cmd>Oil<CR>', { desc = 'Open parent directory (Oil)' })
vim.keymap.set('n', '<Leader>ee', '<Cmd>Oil<CR>', { desc = 'Open Oil in current window' })
vim.keymap.set('n', '<Leader>ed', function()
    local ok, input = pcall(vim.fn.input, { prompt = 'Oil path: ', completion = 'dir', cancelreturn = '' })
    if not ok then
        return
    end
    local trimmed = vim.trim(input or '')
    if trimmed == '' then
        return
    end
    local target = vim.fn.expand(trimmed)
    if vim.fn.filereadable(target) == 1 and vim.fn.isdirectory(target) == 0 then
        target = vim.fn.fnamemodify(target, ':p:h')
    end
    require('oil').open(target)
end, { desc = 'Prompt for path and open in Oil' })
vim.keymap.set('n', '<Leader>ek', '<Cmd>aboveleft Oil<CR>', { desc = 'Open Oil split above' })
vim.keymap.set('n', '<Leader>ej', '<Cmd>belowright Oil<CR>', { desc = 'Open Oil split below' })
vim.keymap.set('n', '<Leader>eh', '<Cmd>aboveleft vertical Oil<CR>', { desc = 'Open Oil split left' })
vim.keymap.set('n', '<Leader>el', '<Cmd>belowright vertical Oil<CR>', { desc = 'Open Oil split right' })
vim.keymap.set('n', '<Leader>ef', '<Cmd>Oil --float<CR>', { desc = 'Open Oil in floating window' })


-- GIT SIGNS (sign column indicators + hunk/line diff popup)
local gitsigns = require('gitsigns')

local function show_range_hunks(start_line, end_line)
    local hunks = gitsigns.get_hunks(0) or {}
    local lines = {}
    for _, h in ipairs(hunks) do
        local h_start = math.max(1, h.added.start)
        local h_end = math.max(h_start, h.added.start + math.max(0, h.added.count - 1))
        if h_start <= end_line and h_end >= start_line then
            if #lines > 0 then
                lines[#lines + 1] = ''
            end
            if h.head then
                lines[#lines + 1] = h.head
            end
            vim.list_extend(lines, h.lines or {})
        end
    end

    if #lines == 0 then
        gitsigns.preview_hunk()
        return
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].swapfile = false
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = 'diff'

    local max_w = 40
    for _, l in ipairs(lines) do
        max_w = math.max(max_w, vim.fn.strdisplaywidth(l) + 4)
    end
    local width = math.min(max_w, math.floor(vim.o.columns * 0.85))
    local height = math.min(#lines, math.floor(vim.o.lines * 0.75))

    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
        col = math.max(0, math.floor((vim.o.columns - width) / 2)),
        style = 'minimal',
        border = 'rounded',
        title = string.format(' Diff lines %d-%d (q / <Esc> to close) ', start_line, end_line),
        title_pos = 'center',
    })

    local function close_diff()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end
    vim.keymap.set('n', 'q', close_diff, { buffer = buf, nowait = true, desc = 'Close diff popup' })
    vim.keymap.set('n', '<Esc>', close_diff, { buffer = buf, nowait = true, desc = 'Close diff popup' })
end

gitsigns.setup({
    signs = {
        add = { text = '┃' },
        change = { text = '┃' },
        delete = { text = '▁' },
        topdelete = { text = '▔' },
        changedelete = { text = '~' },
        untracked = { text = '' },
    },
    signs_staged = {
        add = { text = '┃' },
        change = { text = '┃' },
        delete = { text = '▁' },
        topdelete = { text = '▔' },
        changedelete = { text = '~' },
        untracked = { text = '' },
    },
    signs_staged_enable = true,
    signcolumn = true,
    numhl = false,
    linehl = false,
    culhl = false,
    word_diff = false,
    current_line_blame = false,
    attach_to_untracked = false,
    preview_config = {
        border = 'rounded',
        style = 'minimal',
        relative = 'cursor',
        row = 0,
        col = 1,
    },
    on_attach = function(bufnr)
        local opts = function(desc)
            return { buffer = bufnr, desc = desc }
        end

        vim.keymap.set('n', ']c', function()
            if vim.wo.diff then
                vim.cmd.normal({ ']c', bang = true })
            else
                gitsigns.nav_hunk('next', { target = 'all' })
            end
        end, opts('Next git hunk'))

        vim.keymap.set('n', '[c', function()
            if vim.wo.diff then
                vim.cmd.normal({ '[c', bang = true })
            else
                gitsigns.nav_hunk('prev', { target = 'all' })
            end
        end, opts('Previous git hunk'))

        vim.keymap.set('n', '<Leader>gp', gitsigns.preview_hunk, opts('Preview git hunk diff'))
        vim.keymap.set('x', '<Leader>gp', function()
            local l1 = vim.fn.line('v')
            local l2 = vim.fn.line('.')
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
            show_range_hunks(math.min(l1, l2), math.max(l1, l2))
        end, opts('Preview git diff for selected lines'))
    end,
})

vim.api.nvim_create_user_command('GitDiffHunk', function(cmd)
    if cmd.range > 0 then
        show_range_hunks(cmd.line1, cmd.line2)
    else
        gitsigns.preview_hunk()
    end
end, { range = true, desc = 'Show git diff popup for current hunk or line range' })


-- FZF-LUA
local fzf = require('fzf-lua')
fzf.setup({})

local function make_mssql_find_split_action(split_cmd)
    return function(selected, o)
        local ui_select = require('fzf-lua.providers.ui_select')
        if not selected or #selected == 0 then
            return
        end

        local orig_buf = vim.api.nvim_get_current_buf()
        local orig_lines = vim.api.nvim_buf_get_lines(orig_buf, 0, -1, false)
        local was_empty = vim.trim(table.concat(orig_lines, '\n')) == ''
        local was_modified = vim.bo[orig_buf].modified
        local restored = false

        local function restore_orig_buf()
            if restored or not vim.api.nvim_buf_is_valid(orig_buf) then
                return
            end
            restored = true
            local cur = vim.api.nvim_buf_get_lines(orig_buf, 0, -1, false)
            if #cur == 1 and cur[1] == '--' then
                vim.api.nvim_buf_set_lines(orig_buf, 0, -1, false, orig_lines)
                vim.bo[orig_buf].modified = was_modified
            end
        end

        if was_empty and vim.bo[orig_buf].modifiable then
            vim.api.nvim_buf_set_lines(orig_buf, 0, -1, false, { '--' })
            vim.bo[orig_buf].modified = was_modified
        end

        vim.cmd(split_cmd)

        if was_empty then
            vim.api.nvim_create_autocmd('BufLeave', {
                buffer = orig_buf,
                once = true,
                callback = function()
                    vim.schedule(restore_orig_buf)
                end,
            })
            vim.defer_fn(restore_orig_buf, 5000)
        end

        return ui_select.accept_item(selected, o)
    end
end

fzf.register_ui_select(function(_, items)
    local first = items and items[1]
    if type(first) == 'table' and first.objectType and first.picker_path and first.metadata then
        return {
            headers = { 'actions' },
            actions = {
                ['ctrl-s'] = { fn = make_mssql_find_split_action('belowright split'), desc = 'split' },
                ['ctrl-v'] = { fn = make_mssql_find_split_action('belowright vsplit'), desc = 'vsplit' },
                ['ctrl-t'] = { fn = make_mssql_find_split_action('tab split'), desc = 'tabedit' },
            },
        }
    end
    return {}
end)

vim.keymap.set('n', '<Leader>ff', fzf.files, { desc = 'Find files' })
vim.keymap.set('x', '<Leader>ff', function()
    local selection = vim.trim(require('fzf-lua.utils').get_visual_selection())
    fzf.files({ query = selection })
end, { desc = 'Find files from visual selection' })
vim.keymap.set('n', '<Leader>fg', fzf.live_grep, { desc = 'Live grep' })
vim.keymap.set('x', '<Leader>fg', function()
    local selection = require('fzf-lua.utils').get_visual_selection()
    fzf.live_grep({ search = selection })
end, { desc = 'Live grep visual selection' })
vim.keymap.set('n', '<Leader>fb', fzf.buffers, { desc = 'Find buffers' })
vim.keymap.set('n', '<Leader>fh', fzf.helptags, { desc = 'Find help' })
vim.keymap.set('n', '<Leader>fr', fzf.oldfiles, { desc = 'Recent files' })
vim.keymap.set('n', '<Leader>fd', fzf.diagnostics_workspace, { desc = 'Workspace diagnostics' })
vim.keymap.set('n', '<Leader>fs', fzf.lsp_document_symbols, { desc = 'Document symbols' })
vim.keymap.set('n', '<Leader>fk', fzf.keymaps, { desc = 'Find keymaps' })
vim.keymap.set('n', '<Leader>gh', function()
    gitsigns.setqflist('all', { open = false }, function()
        if #vim.fn.getqflist() == 0 then
            vim.notify('No git hunks found', vim.log.levels.INFO)
            return
        end
        fzf.quickfix({ prompt = 'Git Hunks> ', winopts = { title = ' Git Hunks ' } })
    end)
end, { desc = 'Search git hunks' })
vim.keymap.set('n', '<Leader>cs', fzf.colorschemes, { desc = 'Pick colorscheme' })
vim.keymap.set('n', '<Leader>/', fzf.blines, { desc = 'Search current buffer' })


-- SYNTAX HIGHLIGHTING (Treesitter: JS/TS, Svelte, HTML/CSS, SQL, Python, Rust, Go, C/C++)
local ts_parsers = { 'javascript', 'typescript', 'tsx', 'svelte', 'html', 'css', 'sql', 'python', 'rust', 'go', 'c', 'cpp' }
if vim.fn.executable('tree-sitter') == 1 then
    require('nvim-treesitter').install(ts_parsers)
end

vim.api.nvim_create_autocmd('FileType', {
    desc = 'Enable Treesitter syntax highlighting',
    pattern = {
        'javascript',
        'javascriptreact',
        'typescript',
        'typescriptreact',
        'svelte',
        'html',
        'css',
        'sql',
        'python',
        'rust',
        'go',
        'c',
        'cpp',
    },
    callback = function(ev)
        pcall(vim.treesitter.start, ev.buf)
    end,
})


-- LSP (completions disabled everywhere except manual <C-Space> in mssql_ls)
local no_cmp_capabilities = vim.lsp.protocol.make_client_capabilities()
no_cmp_capabilities.textDocument.completion = nil

local lsp_servers = {
    'biome',         -- JavaScript / TypeScript (linting & formatting)
    'ts_ls',         -- JavaScript / TypeScript (types & navigation)
    'svelte',        -- Svelte (LSP & formatting)
    'ty',            -- Python (Astral ty: types & navigation)
    'ruff',          -- Python (linting)
    'rust_analyzer', -- Rust
    'gopls',         -- Go
    'clangd',        -- C / C++
}
for _, server in ipairs(lsp_servers) do
    vim.lsp.config(server, { capabilities = no_cmp_capabilities })
end
vim.lsp.enable(lsp_servers)

local function open_in_float(item, origin_win)
    local buf = item.bufnr or vim.fn.bufadd(item.filename)
    vim.fn.bufload(buf)
    vim.bo[buf].buflisted = true

    local width = math.max(40, math.floor(vim.o.columns * 0.8))
    local height = math.max(10, math.floor(vim.o.lines * 0.75))
    local title = vim.fn.fnamemodify(item.filename or vim.api.nvim_buf_get_name(buf), ':~:.')

    local float_win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
        col = math.max(0, math.floor((vim.o.columns - width) / 2)),
        style = 'minimal',
        border = 'rounded',
        title = ' ' .. title .. ' ',
        title_pos = 'center',
    })

    vim.wo[float_win].number = true
    vim.wo[float_win].relativenumber = true
    vim.wo[float_win].signcolumn = 'yes:1'
    vim.wo[float_win].cursorline = true

    local lnum = math.max(1, math.min(item.lnum or 1, vim.api.nvim_buf_line_count(buf)))
    local col = math.max(0, (item.col or 1) - 1)
    vim.api.nvim_win_set_cursor(float_win, { lnum, col })
    vim.cmd('normal! zz')

    local function close_float()
        if vim.api.nvim_win_is_valid(float_win) then
            vim.api.nvim_win_close(float_win, true)
        end
    end

    vim.keymap.set('n', 'q', close_float, { buffer = buf, nowait = true, desc = 'Close floating preview' })
    vim.keymap.set('n', '<Esc>', close_float, { buffer = buf, nowait = true, desc = 'Close floating preview' })
    vim.keymap.set('n', '<CR>', function()
        local pos = vim.api.nvim_win_get_cursor(float_win)
        close_float()
        if vim.api.nvim_win_is_valid(origin_win) then
            vim.api.nvim_set_current_win(origin_win)
            vim.cmd("normal! m'")
            vim.api.nvim_win_set_buf(origin_win, buf)
            vim.api.nvim_win_set_cursor(origin_win, pos)
            vim.cmd('normal! zv')
        end
    end, { buffer = buf, nowait = true, desc = 'Open preview in current buffer' })

    vim.api.nvim_create_autocmd('WinClosed', {
        pattern = tostring(float_win),
        once = true,
        callback = function()
            if vim.api.nvim_buf_is_valid(buf) then
                pcall(vim.keymap.del, 'n', 'q', { buffer = buf })
                pcall(vim.keymap.del, 'n', '<Esc>', { buffer = buf })
                pcall(vim.keymap.del, 'n', '<CR>', { buffer = buf })
            end
        end,
    })

    return float_win
end

local function lsp_float(request_fn)
    return function()
        local cur_win = vim.api.nvim_get_current_win()
        local origin_win = cur_win
        if vim.api.nvim_win_get_config(cur_win).relative ~= '' then
            origin_win = vim.w[cur_win].lsp_origin_win or vim.fn.win_getid(vim.fn.winnr('#'))
        end

        request_fn({
            on_list = function(list)
                local function show(item)
                    if cur_win ~= origin_win and vim.api.nvim_win_is_valid(cur_win) then
                        vim.api.nvim_win_close(cur_win, true)
                    end
                    local w = open_in_float(item, origin_win)
                    vim.w[w].lsp_origin_win = origin_win
                end

                if #list.items == 1 then
                    show(list.items[1])
                else
                    vim.ui.select(list.items, {
                        prompt = list.title or 'Select location:',
                        format_item = function(item)
                            local file = vim.fn.fnamemodify(item.filename or '', ':~:.')
                            local text = vim.trim(item.text or '')
                            return string.format('%s:%d: %s', file, item.lnum or 1, text)
                        end,
                    }, function(choice)
                        if choice then
                            show(choice)
                        end
                    end)
                end
            end,
        })
    end
end

local function strip_vim_nil(val)
    if val == vim.NIL then
        return nil
    end
    if type(val) == 'table' then
        for k, v in pairs(val) do
            if v == vim.NIL then
                val[k] = nil
            elseif type(v) == 'table' then
                strip_vim_nil(v)
            end
        end
    end
    return val
end

vim.api.nvim_create_autocmd('LspAttach', {
    desc = 'Configure buffer LSP keymaps (manual <C-Space> completion for mssql_ls only)',
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        local opts = function(desc)
            return { buffer = ev.buf, desc = desc }
        end

        if client and client.name == 'mssql_ls' then
            -- MicrosoftSqlToolsServiceLayer serializes null fields (sortText, documentation, etc.)
            -- as JSON null (vim.NIL), which crashes Neovim 0.12's vim.lsp.completion sorter.
            if not client._mssql_nil_patched then
                client._mssql_nil_patched = true
                local orig_rpc_request = client.rpc.request
                client.rpc.request = function(method, params, cb, ...)
                    if method == 'textDocument/completion' or method == 'completionItem/resolve' then
                        local orig_cb = cb
                        cb = function(err, result, ...)
                            return orig_cb(err, strip_vim_nil(result), ...)
                        end
                    end
                    return orig_rpc_request(method, params, cb, ...)
                end
            end

            vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = false })
            local function trigger_mssql_completion()
                if vim.fn.pumvisible() ~= 0 then
                    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-e>', true, false, true), 'n', false)
                    vim.schedule(function()
                        vim.lsp.completion.get()
                    end)
                else
                    vim.lsp.completion.get()
                end
            end
            vim.keymap.set('i', '<C-Space>', trigger_mssql_completion, opts('MSSQL object suggestions'))
            vim.keymap.set('i', '<C-@>', trigger_mssql_completion, opts('MSSQL object suggestions'))
            vim.keymap.set('i', '<C-l>', trigger_mssql_completion, opts('MSSQL object suggestions'))
        elseif client then
            client.server_capabilities.completionProvider = nil
            vim.lsp.completion.enable(false, client.id, ev.buf)
        end
        vim.bo[ev.buf].omnifunc = ''

        -- Open in current buffer (full screen)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts('Go to definition'))
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts('Go to declaration'))

        -- Open in floating window (q/<Esc> to close, <CR> to open in current buffer)
        vim.keymap.set('n', 'gpd', lsp_float(vim.lsp.buf.definition), opts('Preview definition in float'))
        vim.keymap.set('n', 'gpD', lsp_float(vim.lsp.buf.declaration), opts('Preview declaration in float'))
        vim.keymap.set('n', 'gpi', lsp_float(vim.lsp.buf.implementation), opts('Preview implementation in float'))
        vim.keymap.set('n', 'gpt', lsp_float(vim.lsp.buf.type_definition), opts('Preview type definition in float'))
        vim.keymap.set('n', 'gpr', lsp_float(function(o) vim.lsp.buf.references(nil, o) end), opts('Preview references in float'))

        vim.keymap.set('n', '<Leader>rn', vim.lsp.buf.rename, opts('Rename symbol'))
        vim.keymap.set({ 'n', 'x' }, '<Leader>ca', vim.lsp.buf.code_action, opts('Code action'))
        vim.keymap.set('n', '<Leader>d', vim.diagnostic.open_float, opts('Line diagnostics'))
    end,
})

vim.api.nvim_create_autocmd('LspDetach', {
    desc = 'Remove MSSQL <C-Space> completion keymap when mssql_ls detaches',
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client and client.name == 'mssql_ls' then
            pcall(vim.keymap.del, 'i', '<C-Space>', { buffer = ev.buf })
            pcall(vim.keymap.del, 'i', '<C-@>', { buffer = ev.buf })
            pcall(vim.keymap.del, 'i', '<C-l>', { buffer = ev.buf })
        end
    end,
})


-- FORMATTING (Conform: manual trigger)
local conform = require('conform')
conform.setup({
    formatters_by_ft = {
        javascript = { 'biome' },
        javascriptreact = { 'biome' },
        typescript = { 'biome' },
        typescriptreact = { 'biome' },
        svelte = { lsp_format = 'fallback' },
        python = { 'ruff_organize_imports', 'ruff_format' },
        rust = { 'rustfmt' },
        go = { 'gofmt' },
        c = { 'clang-format' },
        cpp = { 'clang-format' },
    },
    default_format_opts = {
        lsp_format = 'fallback',
    },
})

vim.keymap.set({ 'n', 'x' }, '<Leader>fm', function()
    conform.format({ async = true, lsp_format = 'fallback' })
end, { desc = 'Format buffer or selection' })


-- MSSQL (dormant by default; activate via :MssqlStart, <Leader>mm, or a .mssql root file)
local mssql_initialized = false
local mssql_active = false
local mssql_results_layout = 'float' -- default 'float'; toggle to 'split' with <Leader>mv / :MssqlResultsLayout
local mssql_results_win = nil
local mssql_origin_win = nil
local mssql_dv_buf = nil
local mssql_msg_buf = nil
local mssql_msg_ns = vim.api.nvim_create_namespace('mssql_result_messages')
local mssql_run_dir = nil
local mssql_csv_items = {}
local mssql_table_fallbacks = {}
local mssql_messages = {}
local mssql_has_error = false
local mssql_error_notified = false
local mssql_last_elapsed = nil
local mssql_has_completed_run = false
local mssql_old_runs = {}
local mssql_run_id = 0
local mssql_expected_results = nil
local mssql_received_results = 0
local mssql_pending_exports = 0
local mssql_cancelled = false
local mssql_ignoring_internal = false
local mssql_launch_timer = nil

local function find_dv_bin()
    local bin = vim.fn.exepath('dv')
    if bin ~= '' then
        return bin
    end
    local fallback = vim.fn.expand('~/.local/bin/dv')
    if vim.fn.executable(fallback) == 1 then
        return fallback
    end
    return nil
end

local function is_internal_mssql_query(query)
    if type(query) ~= 'string' then
        return false
    end
    return query:find("^RESTORE FILELISTONLY FROM DISK = '", 1, false) ~= nil
        or query:find("^RESTORE HEADERONLY FROM DISK = '", 1, false) ~= nil
        or query == "SELECT SERVERPROPERTY('InstanceDefaultDataPath') AS DefaultDataPath"
end

local function cleanup_mssql_runs(runs)
    for _, run in ipairs(runs) do
        if run.buf and vim.api.nvim_buf_is_valid(run.buf) then
            pcall(vim.api.nvim_buf_delete, run.buf, { force = true })
        end
        if run.dir and vim.fn.isdirectory(run.dir) == 1 then
            pcall(vim.fn.delete, run.dir, 'rf')
        end
    end
end

vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function()
        cleanup_mssql_runs(mssql_old_runs)
        cleanup_mssql_runs({
            { buf = mssql_dv_buf, dir = mssql_run_dir },
            { buf = mssql_msg_buf },
        })
    end,
})

local function close_mssql_results_win()
    if mssql_results_win and vim.api.nvim_win_is_valid(mssql_results_win) then
        pcall(vim.api.nvim_win_close, mssql_results_win, true)
        mssql_results_win = nil
    end
    if mssql_origin_win and vim.api.nvim_win_is_valid(mssql_origin_win) then
        vim.api.nvim_set_current_win(mssql_origin_win)
    end
end

local function render_mssql_msg_buf()
    table.sort(mssql_table_fallbacks, function(a, b)
        return a.order < b.order
    end)

    local lines = {}
    local line_hls = {}
    local has_md_table = #mssql_table_fallbacks > 0

    for _, tbl in ipairs(mssql_table_fallbacks) do
        if #lines > 0 and lines[#lines] ~= '' then
            lines[#lines + 1] = ''
        end
        for _, l in ipairs(tbl.lines) do
            lines[#lines + 1] = l
        end
        if tbl.row_count == 0 then
            lines[#lines + 1] = '*(0 rows)*'
            line_hls[#lines] = 'Comment'
        end
    end

    if #lines > 0 and #mssql_messages > 0 and lines[#lines] ~= '' then
        lines[#lines + 1] = ''
    end

    for _, msg in ipairs(mssql_messages) do
        local is_exec_time = msg.lines[1] and msg.lines[1]:match('^Total execution time:') ~= nil
        if is_exec_time and #lines > 0 and lines[#lines] ~= '' then
            lines[#lines + 1] = ''
        end
        for _, l in ipairs(msg.lines) do
            lines[#lines + 1] = l
            if msg.is_error then
                line_hls[#lines] = 'DiagnosticError'
            elseif is_exec_time then
                line_hls[#lines] = 'Comment'
            end
        end
    end

    if #lines == 0 then
        if mssql_has_error then
            lines[#lines + 1] = 'Query execution failed.'
            line_hls[#lines] = 'DiagnosticError'
        else
            lines[#lines + 1] = 'Commands completed successfully.'
        end
        if mssql_last_elapsed and mssql_last_elapsed ~= '' then
            lines[#lines + 1] = ''
            lines[#lines + 1] = 'Total execution time: ' .. mssql_last_elapsed
            line_hls[#lines] = 'Comment'
        end
    end

    if not (mssql_msg_buf and vim.api.nvim_buf_is_valid(mssql_msg_buf)) then
        mssql_msg_buf = vim.api.nvim_create_buf(false, true)
        vim.bo[mssql_msg_buf].buftype = 'nofile'
        vim.bo[mssql_msg_buf].bufhidden = 'hide'
        vim.bo[mssql_msg_buf].swapfile = false
        vim.keymap.set('n', 'q', close_mssql_results_win, { buffer = mssql_msg_buf, nowait = true, desc = 'Close MSSQL results' })
        vim.keymap.set('n', '<Esc>', close_mssql_results_win, { buffer = mssql_msg_buf, nowait = true, desc = 'Close MSSQL results' })
    end

    vim.bo[mssql_msg_buf].readonly = false
    vim.bo[mssql_msg_buf].modifiable = true
    vim.api.nvim_buf_set_lines(mssql_msg_buf, 0, -1, false, lines)
    vim.api.nvim_buf_clear_namespace(mssql_msg_buf, mssql_msg_ns, 0, -1)

    for idx, hl_group in pairs(line_hls) do
        local row = idx - 1
        local text = lines[idx] or ''
        vim.api.nvim_buf_set_extmark(mssql_msg_buf, mssql_msg_ns, row, 0, {
            end_row = row,
            end_col = #text,
            hl_group = hl_group,
        })
    end

    vim.b[mssql_msg_buf].query_result_info = mssql_table_fallbacks[1] and mssql_table_fallbacks[1].info or nil
    if has_md_table then
        vim.bo[mssql_msg_buf].filetype = 'markdown'
        pcall(vim.treesitter.start, mssql_msg_buf, 'markdown')
    else
        pcall(vim.treesitter.stop, mssql_msg_buf)
        vim.bo[mssql_msg_buf].filetype = ''
    end

    vim.bo[mssql_msg_buf].modifiable = false
    vim.bo[mssql_msg_buf].readonly = true

    return mssql_msg_buf, lines, has_md_table
end

local function compute_mssql_float_config(use_dv, lines, has_md_table)
    local width, height, title
    if use_dv then
        width = math.min(math.max(60, math.floor(vim.o.columns * 0.9)), math.max(20, vim.o.columns - 4))
        height = math.min(math.max(15, math.floor(vim.o.lines * 0.82)), math.max(6, vim.o.lines - 4))
        title = ' MSSQL Query Results (dataframe-textual) '
    else
        if mssql_has_error then
            title = ' MSSQL Error (q / <Esc> to close) '
        elseif has_md_table then
            title = ' MSSQL Query Results (q / <Esc> to close) '
        else
            title = ' MSSQL Result (q / <Esc> to close) '
        end

        local max_w = 58
        for _, l in ipairs(lines or {}) do
            max_w = math.max(max_w, vim.fn.strdisplaywidth(l) + 4)
        end
        local max_allowed_w = math.max(30, math.min(vim.o.columns - 4, math.floor(vim.o.columns * 0.85)))
        width = math.min(max_w, max_allowed_w)

        local visual_lines = 0
        if not has_md_table then
            local inner_w = math.max(1, width - 2)
            for _, l in ipairs(lines or {}) do
                visual_lines = visual_lines + math.max(1, math.ceil(vim.fn.strdisplaywidth(l) / inner_w))
            end
        else
            visual_lines = #(lines or {})
        end
        local max_allowed_h = math.max(6, math.min(vim.o.lines - 4, math.floor(vim.o.lines * 0.8)))
        height = math.min(math.max(6, visual_lines + 2), max_allowed_h)
    end

    return {
        relative = 'editor',
        width = width,
        height = height,
        row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
        col = math.max(0, math.floor((vim.o.columns - width) / 2)),
        style = 'minimal',
        border = 'rounded',
        title = title,
        title_pos = 'center',
    }
end

local function update_mssql_winbar(use_dv)
    if not (mssql_results_win and vim.api.nvim_win_is_valid(mssql_results_win)) then
        return
    end
    if use_dv then
        local err_prefix = mssql_has_error and '%#DiagnosticError# [SQL Error in batch — :messages] %*' or ''
        local count = #mssql_csv_items
        if count > 1 then
            vim.wo[mssql_results_win].winbar = err_prefix .. string.format(
                '%%#Comment# MSSQL (%s) — %d tables  (b/B tabs | Enter row | Ctrl+T save | <Leader>mv float/split | gq/Ctrl+Q quit)%%*',
                mssql_results_layout,
                count
            )
        else
            vim.wo[mssql_results_win].winbar = err_prefix .. string.format(
                '%%#Comment# MSSQL (%s)  (Enter row | Ctrl+T save | <Leader>mv float/split | q quit)%%*',
                mssql_results_layout
            )
        end
    else
        vim.wo[mssql_results_win].winbar = string.format(
            '%%#Comment# MSSQL (%s)  (<Leader>mv float/split | q/<Esc> close)%%*',
            mssql_results_layout
        )
    end
end

local function open_mssql_results(focus_results)
    local dv_bin = find_dv_bin()
    local use_dv = dv_bin ~= nil and #mssql_csv_items > 0
    local has_non_dv = mssql_has_completed_run or #mssql_table_fallbacks > 0 or #mssql_messages > 0

    if not use_dv and not has_non_dv then
        vim.notify('No MSSQL query results available', vim.log.levels.INFO)
        return
    end

    local cur_win = vim.api.nvim_get_current_win()
    if cur_win ~= mssql_results_win then
        mssql_origin_win = cur_win
    end

    local target_buf
    local need_spawn = false
    local msg_lines, has_md_table = nil, false

    if use_dv then
        if mssql_dv_buf and vim.api.nvim_buf_is_valid(mssql_dv_buf) then
            target_buf = mssql_dv_buf
        else
            target_buf = vim.api.nvim_create_buf(false, true)
            vim.bo[target_buf].bufhidden = 'hide'
            vim.bo[target_buf].swapfile = false
            if mssql_csv_items[1] and mssql_csv_items[1].info then
                vim.b[target_buf].query_result_info = mssql_csv_items[1].info
            end
            mssql_dv_buf = target_buf
            need_spawn = true
        end
        if mssql_has_error and not mssql_error_notified then
            mssql_error_notified = true
            local err_chunks = {}
            for _, msg in ipairs(mssql_messages) do
                if msg.is_error then
                    err_chunks[#err_chunks + 1] = table.concat(msg.lines, '\n')
                end
            end
            if #err_chunks > 0 then
                vim.notify(table.concat(err_chunks, '\n\n'), vim.log.levels.ERROR, { title = 'MSSQL' })
            end
        end
    else
        target_buf, msg_lines, has_md_table = render_mssql_msg_buf()
    end

    local float_cfg = (mssql_results_layout == 'float') and compute_mssql_float_config(use_dv, msg_lines, has_md_table) or nil

    if mssql_results_win and vim.api.nvim_win_is_valid(mssql_results_win) then
        local win_is_float = vim.api.nvim_win_get_config(mssql_results_win).relative ~= ''
        if (mssql_results_layout == 'float') == win_is_float then
            vim.api.nvim_win_set_buf(mssql_results_win, target_buf)
            if float_cfg then
                vim.api.nvim_win_set_config(mssql_results_win, float_cfg)
            end
        else
            pcall(vim.api.nvim_win_close, mssql_results_win, true)
            mssql_results_win = nil
        end
    end

    if not (mssql_results_win and vim.api.nvim_win_is_valid(mssql_results_win)) then
        if mssql_results_layout == 'float' then
            mssql_results_win = vim.api.nvim_open_win(target_buf, true, float_cfg)
        else
            local split_h = math.max(12, math.floor(vim.o.lines * 0.4))
            vim.cmd('botright ' .. split_h .. 'split')
            mssql_results_win = vim.api.nvim_get_current_win()
            vim.api.nvim_win_set_buf(mssql_results_win, target_buf)
        end
    end

    if not use_dv and vim.api.nvim_win_is_valid(mssql_results_win) then
        vim.wo[mssql_results_win].wrap = not has_md_table
        vim.wo[mssql_results_win].linebreak = not has_md_table
        vim.wo[mssql_results_win].number = false
        vim.wo[mssql_results_win].relativenumber = false
        vim.wo[mssql_results_win].signcolumn = 'no'
        vim.wo[mssql_results_win].cursorline = false
        pcall(vim.api.nvim_win_set_cursor, mssql_results_win, { 1, 0 })
    end

    if #mssql_old_runs > 0 then
        cleanup_mssql_runs(mssql_old_runs)
        mssql_old_runs = {}
    end

    if need_spawn then
        local cmd = { dv_bin }
        for _, item in ipairs(mssql_csv_items) do
            cmd[#cmd + 1] = item.csv_path
        end
        local term_buf = target_buf
        vim.api.nvim_buf_call(term_buf, function()
            vim.fn.jobstart(cmd, {
                term = true,
                on_exit = function()
                    vim.schedule(function()
                        if
                            mssql_results_win
                            and vim.api.nvim_win_is_valid(mssql_results_win)
                            and vim.api.nvim_win_get_buf(mssql_results_win) == term_buf
                        then
                            pcall(vim.api.nvim_win_close, mssql_results_win, true)
                            mssql_results_win = nil
                            if mssql_origin_win and vim.api.nvim_win_is_valid(mssql_origin_win) then
                                vim.api.nvim_set_current_win(mssql_origin_win)
                            end
                        end
                        if vim.api.nvim_buf_is_valid(term_buf) then
                            pcall(vim.api.nvim_buf_delete, term_buf, { force = true })
                        end
                        if mssql_dv_buf == term_buf then
                            mssql_dv_buf = nil
                        end
                    end)
                end,
            })
        end)
    end

    update_mssql_winbar(use_dv)

    if mssql_results_layout == 'float' or focus_results then
        if vim.api.nvim_win_is_valid(mssql_results_win) then
            vim.api.nvim_set_current_win(mssql_results_win)
            if use_dv and vim.bo[target_buf].buftype == 'terminal' then
                vim.cmd.startinsert()
            else
                vim.cmd.stopinsert()
            end
        end
    elseif cur_win ~= mssql_results_win and vim.api.nvim_win_is_valid(cur_win) then
        vim.api.nvim_set_current_win(cur_win)
    end
end

local function begin_mssql_run()
    if mssql_launch_timer then
        mssql_launch_timer:stop()
    end
    if mssql_dv_buf or mssql_run_dir then
        mssql_old_runs[#mssql_old_runs + 1] = { buf = mssql_dv_buf, dir = mssql_run_dir }
    end
    mssql_run_id = mssql_run_id + 1
    local cur_win = vim.api.nvim_get_current_win()
    if cur_win ~= mssql_results_win then
        mssql_origin_win = cur_win
    end
    mssql_dv_buf = nil
    mssql_run_dir = vim.fn.tempname()
    vim.fn.mkdir(mssql_run_dir, 'p')
    mssql_csv_items = {}
    mssql_table_fallbacks = {}
    mssql_messages = {}
    mssql_has_error = false
    mssql_error_notified = false
    mssql_last_elapsed = nil
    mssql_has_completed_run = false
    mssql_expected_results = nil
    mssql_received_results = 0
    mssql_pending_exports = 0
    mssql_cancelled = false
    return mssql_run_id
end

local function maybe_finish_mssql_run(run_id)
    if run_id ~= mssql_run_id or mssql_cancelled or mssql_ignoring_internal then
        return
    end
    if mssql_expected_results == nil then
        return
    end
    if mssql_received_results < mssql_expected_results or mssql_pending_exports > 0 then
        return
    end

    if not mssql_launch_timer then
        mssql_launch_timer = vim.uv.new_timer()
    else
        mssql_launch_timer:stop()
    end

    mssql_launch_timer:start(35, 0, vim.schedule_wrap(function()
        if run_id ~= mssql_run_id or mssql_cancelled or mssql_pending_exports > 0 then
            return
        end
        mssql_has_completed_run = true
        table.sort(mssql_csv_items, function(a, b)
            return a.order < b.order
        end)
        if mssql_dv_buf and vim.api.nvim_buf_is_valid(mssql_dv_buf) then
            mssql_old_runs[#mssql_old_runs + 1] = { buf = mssql_dv_buf }
            mssql_dv_buf = nil
        end
        open_mssql_results(false)
    end))
end

local function handle_mssql_message(message, is_error)
    if mssql_ignoring_internal or type(message) ~= 'string' then
        return
    end
    local cleaned = message:gsub('\r', ''):gsub('\n+$', '')
    if cleaned == '' then
        return
    end
    local msg_lines = vim.split(cleaned, '\n', { plain = true })
    mssql_messages[#mssql_messages + 1] = {
        lines = msg_lines,
        is_error = is_error == true,
    }
    if is_error then
        mssql_has_error = true
    end

    if
        mssql_has_completed_run
        and mssql_msg_buf
        and vim.api.nvim_buf_is_valid(mssql_msg_buf)
        and mssql_results_win
        and vim.api.nvim_win_is_valid(mssql_results_win)
        and vim.api.nvim_win_get_buf(mssql_results_win) == mssql_msg_buf
    then
        local _, lines, has_md_table = render_mssql_msg_buf()
        if vim.api.nvim_win_get_config(mssql_results_win).relative ~= '' then
            vim.api.nvim_win_set_config(mssql_results_win, compute_mssql_float_config(false, lines, has_md_table))
        end
    end
end

local function handle_mssql_query_complete(_, result)
    if mssql_ignoring_internal or mssql_cancelled then
        return
    end
    local run_id = mssql_run_id
    local expected = 0
    if type(result) == 'table' and type(result.batchSummaries) == 'table' then
        for _, bs in ipairs(result.batchSummaries) do
            if type(bs.executionElapsed) == 'string' and bs.executionElapsed ~= '' then
                mssql_last_elapsed = bs.executionElapsed
            end
            if bs.hasError then
                mssql_has_error = true
            elseif type(bs.resultSetSummaries) == 'table' then
                expected = expected + #bs.resultSetSummaries
            end
        end
    end
    mssql_expected_results = expected
    vim.schedule(function()
        maybe_finish_mssql_run(run_id)
    end)
end

local function handle_mssql_result_buf(md_buf)
    if mssql_ignoring_internal then
        return
    end
    if mssql_run_id == 0 then
        begin_mssql_run()
        mssql_expected_results = 1
    end

    local run_id = mssql_run_id
    mssql_received_results = mssql_received_results + 1

    local info = vim.b[md_buf].query_result_info
    local sp = info and info.subset_params or nil
    local order = sp and (sp.batchIndex * 1000 + sp.resultSetIndex) or mssql_received_results
    local row_count = sp and sp.rowsCount or nil
    local md_lines = vim.api.nvim_buf_is_valid(md_buf) and vim.api.nvim_buf_get_lines(md_buf, 0, -1, false) or {}

    if not sp or not find_dv_bin() then
        mssql_table_fallbacks[#mssql_table_fallbacks + 1] = {
            lines = md_lines,
            row_count = row_count,
            order = order,
            info = info,
        }
        maybe_finish_mssql_run(run_id)
        return
    end

    local ok, client = pcall(require('mssql.utils').get_lsp_client, sp.ownerUri)
    if not ok or not client then
        mssql_table_fallbacks[#mssql_table_fallbacks + 1] = {
            lines = md_lines,
            row_count = row_count,
            order = order,
            info = info,
        }
        maybe_finish_mssql_run(run_id)
        return
    end

    local csv_path = vim.fs.joinpath(mssql_run_dir, string.format('table_%d-%d.csv', sp.batchIndex + 1, sp.resultSetIndex + 1))
    mssql_pending_exports = mssql_pending_exports + 1
    client:request('query/saveCsv', {
        FilePath = csv_path,
        BatchIndex = sp.batchIndex,
        ResultSetIndex = sp.resultSetIndex,
        OwnerUri = sp.ownerUri,
        IncludeHeaders = true,
        Formatted = true,
    }, vim.schedule_wrap(function(err)
        if run_id ~= mssql_run_id then
            return
        end
        mssql_pending_exports = math.max(0, mssql_pending_exports - 1)
        if not err and vim.fn.filereadable(csv_path) == 1 and #vim.fn.readfile(csv_path, '', 2) >= 2 then
            mssql_csv_items[#mssql_csv_items + 1] = {
                csv_path = csv_path,
                order = order,
                info = info,
            }
        else
            pcall(vim.fn.delete, csv_path)
            mssql_table_fallbacks[#mssql_table_fallbacks + 1] = {
                lines = md_lines,
                row_count = row_count or 0,
                order = order,
                info = info,
            }
        end
        maybe_finish_mssql_run(run_id)
    end))
end

vim.api.nvim_create_autocmd('LspAttach', {
    desc = 'Track mssql_ls query start, cancel, and completion for floating results',
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not (client and client.name == 'mssql_ls') or client._mssql_query_patched then
            return
        end
        client._mssql_query_patched = true

        local orig_rpc_request = client.rpc.request
        client.rpc.request = function(method, params, cb, ...)
            if method == 'query/executeString' then
                if is_internal_mssql_query(params and params.query) then
                    mssql_ignoring_internal = true
                else
                    mssql_ignoring_internal = false
                    local run_id = begin_mssql_run()
                    local orig_cb = cb
                    cb = function(err, result, ...)
                        if err and run_id == mssql_run_id then
                            local err_msg = (type(err) == 'table' and err.message) and err.message or tostring(err)
                            vim.schedule(function()
                                handle_mssql_message('Error executing query: ' .. err_msg, true)
                                mssql_expected_results = 0
                                maybe_finish_mssql_run(run_id)
                            end)
                        end
                        if orig_cb then
                            return orig_cb(err, result, ...)
                        end
                    end
                end
            elseif method == 'query/cancel' then
                mssql_cancelled = true
            end
            return orig_rpc_request(method, params, cb, ...)
        end

        local ok, mssql_utils = pcall(require, 'mssql.utils')
        if ok and mssql_utils.register_lsp_handler then
            mssql_utils.register_lsp_handler(client, 'query/complete', handle_mssql_query_complete)
        end
    end,
})

local function save_mssql_csv_cmd(dest_arg)
    local item = mssql_csv_items[1]
    if not item or not item.csv_path or vim.fn.filereadable(item.csv_path) ~= 1 then
        vim.notify('No exported MSSQL CSV available (inside dv, press Ctrl+T to save)', vim.log.levels.WARN)
        return
    end
    local default_file = vim.fs.joinpath(vim.fn.getcwd(), vim.fn.fnamemodify(item.csv_path, ':t'))
    local dest = dest_arg and dest_arg ~= '' and dest_arg or vim.fn.input('Save CSV to: ', default_file, 'file')
    if not dest or vim.trim(dest) == '' then
        return
    end
    dest = vim.fn.expand(vim.trim(dest))
    if not dest:lower():match('%.csv$') then
        dest = dest .. '.csv'
    end
    vim.fn.mkdir(vim.fn.fnamemodify(dest, ':p:h'), 'p')
    local ok, err = vim.uv.fs_copyfile(item.csv_path, dest)
    if ok then
        vim.notify('Saved CSV to ' .. dest, vim.log.levels.INFO)
    else
        vim.notify('Failed to save CSV: ' .. tostring(err), vim.log.levels.ERROR)
    end
end

local function toggle_mssql_results_layout()
    mssql_results_layout = (mssql_results_layout == 'split') and 'float' or 'split'
    if mssql_results_win and vim.api.nvim_win_is_valid(mssql_results_win) then
        pcall(vim.api.nvim_win_close, mssql_results_win, true)
        mssql_results_win = nil
        open_mssql_results(mssql_results_layout == 'float')
    else
        vim.notify('MSSQL results layout set to: ' .. mssql_results_layout, vim.log.levels.INFO)
    end
end

local function attach_mssql_to_open_sql_buffers()
    local cfg = vim.lsp.config['mssql_ls']
    if not cfg then
        return
    end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if
            vim.api.nvim_buf_is_loaded(buf)
            and vim.bo[buf].buftype == ''
            and vim.bo[buf].filetype == 'sql'
            and #vim.lsp.get_clients({ name = 'mssql_ls', bufnr = buf }) == 0
        then
            vim.lsp.start(cfg, { bufnr = buf })
        end
    end
end

local function activate_mssql()
    if mssql_active then
        vim.notify('mssql.nvim is already active', vim.log.levels.INFO)
        return
    end
    mssql_active = true
    if not mssql_initialized then
        mssql_initialized = true
        require('mssql').setup({
            keymap_prefix = '<Leader>m',
            open_results_in = handle_mssql_result_buf,
            view_messages_in = handle_mssql_message,
        }, function()
            attach_mssql_to_open_sql_buffers()
            vim.notify('mssql.nvim activated (<Leader>m / :MSSQL)', vim.log.levels.INFO)
        end)
    else
        vim.lsp.enable('mssql_ls', true)
        attach_mssql_to_open_sql_buffers()
        vim.notify('mssql.nvim re-enabled', vim.log.levels.INFO)
    end
end

local function deactivate_mssql()
    if not mssql_active then
        vim.notify('mssql.nvim is not active', vim.log.levels.INFO)
        return
    end
    mssql_active = false
    vim.lsp.enable('mssql_ls', false)
    vim.notify('mssql.nvim stopped for .sql buffers', vim.log.levels.INFO)
end

vim.api.nvim_create_user_command('MssqlStart', activate_mssql, { desc = 'Activate mssql.nvim for this session' })
vim.api.nvim_create_user_command('MssqlStop', deactivate_mssql, { desc = 'Deactivate mssql.nvim LSP for .sql buffers' })
vim.api.nvim_create_user_command('MssqlResultsLayout', toggle_mssql_results_layout, { desc = 'Toggle MSSQL results between float and split' })
vim.api.nvim_create_user_command('MssqlResults', function()
    open_mssql_results(true)
end, { desc = 'Reopen last MSSQL query results or messages' })
vim.api.nvim_create_user_command('MssqlSaveCsv', function(cmd)
    save_mssql_csv_cmd(cmd.args)
end, { nargs = '?', complete = 'file', desc = 'Save exported MSSQL result table as CSV' })

vim.keymap.set('n', '<Leader>mm', function()
    if mssql_active then
        deactivate_mssql()
    else
        activate_mssql()
    end
end, { desc = 'Toggle mssql.nvim activation' })
vim.keymap.set('n', '<Leader>mv', toggle_mssql_results_layout, { desc = 'Toggle MSSQL results layout (float/split)' })
vim.keymap.set('n', '<Leader>mo', function()
    open_mssql_results(true)
end, { desc = 'Reopen last MSSQL query results' })

vim.api.nvim_create_autocmd('FileType', {
    desc = 'Auto-activate mssql.nvim in projects containing a .mssql marker file',
    pattern = 'sql',
    callback = function(ev)
        if not mssql_active and vim.fs.root(ev.buf, { '.mssql' }) then
            activate_mssql()
        end
    end,
})


-- FILE RUNNER (<Leader>rr / :RunFile, <Leader>rv / :RunLayout)
local runner_layout = 'float' -- default 'float'; toggle to 'split' with <Leader>rv / :RunLayout
local runner_win = nil
local runner_buf = nil
local runner_title = ' Runner '

local function open_runner_win(buf, title)
    runner_title = title or runner_title
    if runner_win and vim.api.nvim_win_is_valid(runner_win) then
        vim.api.nvim_win_set_buf(runner_win, buf)
        vim.api.nvim_set_current_win(runner_win)
    elseif runner_layout == 'float' then
        local width = math.max(60, math.floor(vim.o.columns * 0.85))
        local height = math.max(14, math.floor(vim.o.lines * 0.75))
        runner_win = vim.api.nvim_open_win(buf, true, {
            relative = 'editor',
            width = width,
            height = height,
            row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
            col = math.max(0, math.floor((vim.o.columns - width) / 2)),
            style = 'minimal',
            border = 'rounded',
            title = runner_title,
            title_pos = 'center',
        })
    else
        local split_h = math.max(12, math.floor(vim.o.lines * 0.35))
        vim.cmd('botright ' .. split_h .. 'split')
        runner_win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(runner_win, buf)
    end
    vim.wo[runner_win].winbar = '%#Comment#' .. runner_title .. '(<Leader>rv float/split | q/<Esc> close)%*'
end

local function build_run_spec(bufnr)
    local file = vim.api.nvim_buf_get_name(bufnr)
    local dir = vim.fn.fnamemodify(file, ':p:h')
    local ft = vim.bo[bufnr].filetype

    if ft == 'python' then
        local cwd = vim.fs.root(bufnr, { 'pyproject.toml', 'uv.lock' }) or dir
        return { cmd = { 'uv', 'run', file }, cwd = cwd, label = 'uv run ' .. vim.fn.fnamemodify(file, ':t') }
    elseif ft == 'javascript' or ft == 'typescript' then
        local cwd = vim.fs.root(bufnr, { 'package.json' }) or dir
        return { cmd = { 'node', file }, cwd = cwd, label = 'node ' .. vim.fn.fnamemodify(file, ':t') }
    elseif ft == 'go' then
        local cwd = vim.fs.root(bufnr, { 'go.mod' }) or dir
        return { cmd = { 'go', 'run', file }, cwd = cwd, label = 'go run ' .. vim.fn.fnamemodify(file, ':t') }
    elseif ft == 'rust' then
        local cargo_root = vim.fs.root(bufnr, { 'Cargo.toml' })
        if cargo_root then
            return { cmd = { 'cargo', 'run' }, cwd = cargo_root, label = 'cargo run' }
        end
        local bin = vim.fn.tempname()
        local sh_cmd = string.format('rustc %s -o %s && %s; code=$?; rm -f %s; exit $code', vim.fn.shellescape(file), vim.fn.shellescape(bin), vim.fn.shellescape(bin), vim.fn.shellescape(bin))
        return { cmd = { 'sh', '-c', sh_cmd }, cwd = dir, label = 'rustc ' .. vim.fn.fnamemodify(file, ':t') }
    elseif ft == 'c' or ft == 'cpp' then
        local cc = (ft == 'cpp') and 'g++' or 'gcc'
        local bin = vim.fn.tempname()
        local sh_cmd = string.format('%s %s -o %s && %s; code=$?; rm -f %s; exit $code', cc, vim.fn.shellescape(file), vim.fn.shellescape(bin), vim.fn.shellescape(bin), vim.fn.shellescape(bin))
        return { cmd = { 'sh', '-c', sh_cmd }, cwd = dir, label = cc .. ' ' .. vim.fn.fnamemodify(file, ':t') }
    elseif ft == 'sh' or ft == 'bash' then
        return { cmd = { 'bash', file }, cwd = dir, label = 'bash ' .. vim.fn.fnamemodify(file, ':t') }
    end
    return nil
end

local function run_current_file()
    local src_buf = vim.api.nvim_get_current_buf()
    local file = vim.api.nvim_buf_get_name(src_buf)
    if vim.bo[src_buf].buftype ~= '' or file == '' then
        vim.notify('Current buffer is not a file on disk', vim.log.levels.WARN)
        return
    end

    local spec = build_run_spec(src_buf)
    if not spec then
        vim.notify('No runner configured for filetype: ' .. (vim.bo[src_buf].filetype or 'none'), vim.log.levels.WARN)
        return
    end

    if vim.bo[src_buf].modified then
        vim.cmd('silent update')
    end

    local prev_buf = runner_buf
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = 'hide'
    vim.bo[buf].swapfile = false
    runner_buf = buf

    local function close_runner()
        if runner_win and vim.api.nvim_win_is_valid(runner_win) then
            pcall(vim.api.nvim_win_close, runner_win, true)
            runner_win = nil
        end
    end

    vim.keymap.set('n', 'q', close_runner, { buffer = buf, nowait = true, desc = 'Close runner window' })
    vim.keymap.set('n', '<Esc>', close_runner, { buffer = buf, nowait = true, desc = 'Close runner window' })

    open_runner_win(buf, ' ' .. spec.label .. ' ')

    if prev_buf and prev_buf ~= buf and vim.api.nvim_buf_is_valid(prev_buf) then
        pcall(vim.api.nvim_buf_delete, prev_buf, { force = true })
    end

    vim.api.nvim_create_autocmd('TermClose', {
        buffer = buf,
        once = true,
        callback = function()
            vim.schedule(function()
                if runner_win and vim.api.nvim_get_current_win() == runner_win then
                    vim.cmd.stopinsert()
                end
            end)
        end,
    })

    vim.api.nvim_buf_call(buf, function()
        vim.fn.jobstart(spec.cmd, {
            term = true,
            cwd = spec.cwd,
        })
    end)
    vim.cmd.startinsert()
end

local function toggle_runner_layout()
    runner_layout = (runner_layout == 'float') and 'split' or 'float'
    if runner_win and vim.api.nvim_win_is_valid(runner_win) and runner_buf and vim.api.nvim_buf_is_valid(runner_buf) then
        pcall(vim.api.nvim_win_close, runner_win, true)
        runner_win = nil
        open_runner_win(runner_buf, runner_title)
    else
        vim.notify('Runner layout set to: ' .. runner_layout, vim.log.levels.INFO)
    end
end

vim.api.nvim_create_user_command('RunFile', run_current_file, { desc = 'Save and run current file' })
vim.api.nvim_create_user_command('RunLayout', toggle_runner_layout, { desc = 'Toggle file runner between float and split' })
vim.keymap.set('n', '<Leader>rr', run_current_file, { desc = 'Run current file' })
vim.keymap.set('n', '<Leader>rv', toggle_runner_layout, { desc = 'Toggle runner layout (float/split)' })


-- KEYBINDINGS HELP (:Keybinds / <Leader>?)
local help_win = nil
local help_buf = nil

local function find_leaf_bin()
    local bin = vim.fn.exepath('leaf')
    if bin ~= '' then
        return bin
    end
    for _, candidate in ipairs({ '~/.local/bin/leaf', '~/.cargo/bin/leaf' }) do
        local expanded = vim.fn.expand(candidate)
        if vim.fn.executable(expanded) == 1 then
            return expanded
        end
    end
    return nil
end

local function find_keybinds_toc_index(lines)
    local in_fence = false
    local h2_idx = 0
    for _, line in ipairs(lines) do
        if line:match('^%s*```') then
            in_fence = not in_fence
        elseif not in_fence and line:match('^##%s+') then
            h2_idx = h2_idx + 1
            if line:match('^##%s+.*Keybindings') then
                return h2_idx
            end
        end
    end
    return nil
end

local function open_keybinds_help()
    if help_win and vim.api.nvim_win_is_valid(help_win) and help_buf and vim.api.nvim_buf_is_valid(help_buf) then
        vim.api.nvim_set_current_win(help_win)
        if vim.bo[help_buf].buftype == 'terminal' then
            vim.cmd.startinsert()
        end
        return
    end

    local guide_path = init_dir .. '/USER_GUIDE.md'
    if vim.fn.filereadable(guide_path) ~= 1 then
        guide_path = vim.fn.stdpath('config') .. '/USER_GUIDE.md'
    end
    if vim.fn.filereadable(guide_path) ~= 1 then
        vim.notify('USER_GUIDE.md not found next to init.lua or in ' .. vim.fn.stdpath('config'), vim.log.levels.WARN)
        return
    end

    local all_lines = vim.fn.readfile(guide_path)
    local leaf_bin = find_leaf_bin()

    if leaf_bin then
        local toc_idx = find_keybinds_toc_index(all_lines)
        local buf = vim.api.nvim_create_buf(false, true)
        vim.bo[buf].bufhidden = 'wipe'
        vim.bo[buf].swapfile = false

        local width = math.max(60, math.min(130, math.floor(vim.o.columns * 0.88)))
        local height = math.max(15, math.floor(vim.o.lines * 0.85))
        local win = vim.api.nvim_open_win(buf, true, {
            relative = 'editor',
            width = width,
            height = height,
            row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
            col = math.max(0, math.floor((vim.o.columns - width) / 2)),
            style = 'minimal',
            border = 'rounded',
            title = ' User Guide — Keybindings (q close | t TOC | / search | ? leaf help) ',
            title_pos = 'center',
        })
        help_win = win
        help_buf = buf

        local job_id = nil
        local jumped = false

        local function close_help()
            if job_id and job_id > 0 then
                pcall(vim.fn.jobstop, job_id)
                job_id = nil
            end
            if vim.api.nvim_win_is_valid(win) then
                pcall(vim.api.nvim_win_close, win, true)
            end
            if vim.api.nvim_buf_is_valid(buf) then
                pcall(vim.api.nvim_buf_delete, buf, { force = true })
            end
            if help_win == win then
                help_win = nil
            end
            if help_buf == buf then
                help_buf = nil
            end
        end

        vim.keymap.set('n', 'q', close_help, { buffer = buf, nowait = true, desc = 'Close keybindings help' })
        vim.keymap.set('n', '<Esc>', close_help, { buffer = buf, nowait = true, desc = 'Close keybindings help' })

        vim.api.nvim_buf_call(buf, function()
            job_id = vim.fn.jobstart({ leaf_bin, guide_path }, {
                term = true,
                on_stdout = function(_, data)
                    if not jumped and toc_idx and toc_idx >= 1 and toc_idx <= 9 and data and #table.concat(data, '') > 0 then
                        jumped = true
                        vim.defer_fn(function()
                            if job_id and job_id > 0 and vim.api.nvim_buf_is_valid(buf) then
                                pcall(vim.api.nvim_chan_send, job_id, tostring(toc_idx))
                            end
                        end, 20)
                    end
                end,
                on_exit = function()
                    job_id = nil
                    vim.schedule(close_help)
                end,
            })
        end)

        vim.cmd.startinsert()
        return
    end

    -- Fallback when `leaf` is not installed: native read-only Markdown float
    local section = {}
    local in_section = false
    for _, line in ipairs(all_lines) do
        if line:match('^##%s+.*Keybindings') then
            in_section = true
        elseif in_section and line:match('^##%s+') then
            break
        end
        if in_section then
            section[#section + 1] = line
        end
    end

    while #section > 0 and (section[#section]:match('^%s*$') or section[#section]:match('^%-%-%-+%s*$')) do
        table.remove(section)
    end

    if #section == 0 then
        section = all_lines
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, section)
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].swapfile = false
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = 'markdown'

    local width = math.max(50, math.min(110, math.floor(vim.o.columns * 0.85)))
    local height = math.max(12, math.min(#section + 2, math.floor(vim.o.lines * 0.8)))

    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
        col = math.max(0, math.floor((vim.o.columns - width) / 2)),
        style = 'minimal',
        border = 'rounded',
        title = ' Keybindings (q / <Esc> to close) ',
        title_pos = 'center',
    })
    help_win = win
    help_buf = buf

    vim.wo[win].wrap = true
    vim.wo[win].linebreak = true
    vim.wo[win].cursorline = true
    pcall(vim.treesitter.start, buf, 'markdown')

    local function close_help()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
        if help_win == win then
            help_win = nil
        end
        if help_buf == buf then
            help_buf = nil
        end
    end
    vim.keymap.set('n', 'q', close_help, { buffer = buf, nowait = true, desc = 'Close keybindings help' })
    vim.keymap.set('n', '<Esc>', close_help, { buffer = buf, nowait = true, desc = 'Close keybindings help' })
end

vim.api.nvim_create_user_command('Keybinds', open_keybinds_help, { desc = 'Show USER_GUIDE.md keybindings in leaf' })
vim.keymap.set('n', '<Leader>?', open_keybinds_help, { desc = 'Show keybindings help (leaf)' })

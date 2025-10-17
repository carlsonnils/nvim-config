

-- Function to find .venv in current or parent directories
local function find_venv(start_path)
    local path = start_path
    while path ~= '/' do
        local venv_path = path .. '/.venv'
        if vim.fn.isdirectory(venv_path) == 1 then
            return venv_path
        end
        -- Move to parent directory
        path = vim.fn.fnamemodify(path, ':h')
    end
    return nil
end
-- Function to add python path and venv path to pyright conifg
local function config_pyright_path(venv_path)
    local did_configure = false

    local py_pth = ''
    if vim.fn.has('win32') == 1 then
        py_pth = venv_path .. '/Scripts/python.exe'
    else
        py_pth = venv_path .. '/bin/python'
    end

    if vim.fn.executable(py_pth) == 1 then
        local clients = vim.lsp.get_clients({bufnr = bufnr, name = 'pyright'})
        if #clients > 0 then
            for _, client in ipairs(clients) do
                client.config.settings.python = client.config.settings.python or {}
                client.config.settings.python.pythonPath = py_pth
                client.config.settings.python.analysis = client.config.settings.python.analysis or {}
                client.config.settings.python.analysis.include = venv_path
                client:notify('workspace/didChangeConfiguration', {
                    settings = client.config.settings
                })

                did_configure = true
            end
        end
    end

    return did_configure
end
-- Async function to configure Pyright with found venv
local function setup_pyright_with_venv(bufnr)
    local current_file = vim.api.nvim_buf_get_name(bufnr)
    if current_file == '' then
        return
    end
    local start_dir = vim.fn.fnamemodify(current_file, ':p:h')
    -- Run in async context
    vim.schedule(function()
        local venv_path = find_venv(start_dir)

        if venv_path then
            config_pyright_path(venv_path)
        end
    end)
end
-- Auto-detect venv when opening Python files
vim.api.nvim_create_autocmd('LspAttach', {
    pattern = '*.py',
    callback = function(args)
        setup_pyright_with_venv(args.buf)
    end,
})
-- Manual command to re-detect venv
vim.api.nvim_create_user_command('PyrightFindVenv', function()
    setup_pyright_with_venv(vim.api.nvim_get_current_buf())
end, {})


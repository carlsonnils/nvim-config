
local function find_venv(start_path)
    local path = start_path
    while path ~= '/' do
        local venv_path = path .. '/.venv'
        if vim.fn.isdirectory(venv_path) == 1 then
            return venv_path
        end
        path = vim.fn.fnamemodify(path, ':h')
    end

    return nil
end


local function config_pyright_path(venv_path)
    if venv_path then
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
                end
            else
                vim.print("Pyright Find Venv: no lsp clients to attach to but found python at " .. py_pth)
            end
        else
            vim.print('Pyright Find Venv: no python executable in venv at ' .. venv_path)
        end
    else
        vim.print('PyrightFindVenv: no venv path found')
    end
end


local function setup_pyright_with_venv(bufnr)
    local current_file = vim.api.nvim_buf_get_name(bufnr)
    if current_file == '' then
        return
    end

    local start_dir = vim.fn.fnamemodify(current_file, ':p:h')
    vim.schedule(function()
        local venv_path = find_venv(start_dir)
        config_pyright_path(venv_path)
    end)
end


vim.api.nvim_create_autocmd('LspAttach', {
    pattern = '*.py',
    callback = function(args)
        setup_pyright_with_venv(args.buf)
    end,
})


vim.api.nvim_create_user_command('PyrightFindVenv', function()
    setup_pyright_with_venv(vim.api.nvim_get_current_buf())
end, {})


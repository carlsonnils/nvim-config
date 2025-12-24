-- vim.api.nvim_create_user_command('PyrightFindVenv', function()
--     setup_pyright_with_venv(vim.api.nvim_get_current_buf())
-- end, {})


local function find_venv(start_path)
    local path = start_path
    local max_depth = 10  -- Prevent infinite traversal
    local depth = 0

    while path ~= '/' and depth < max_depth do
        local venv_path = path .. '/.venv'
        if vim.fn.isdirectory(venv_path) == 1 then
            return venv_path
        end
        path = vim.fn.fnamemodify(path, ':h')
        depth = depth + 1
    end
    return nil
end


local function config_pyright_path(venv_path, bufnr)
    if not venv_path then
        return
    end

    local py_pth = venv_path .. (vim.fn.has('win32') == 1 and '/Scripts/python.exe' or '/bin/python')

    if vim.fn.executable(py_pth) ~= 1 then
        return
    end

    vim.defer_fn(function()
        local clients = vim.lsp.get_clients({bufnr = bufnr, name = 'pyright'})
        if #clients > 0 then
            for _, client in ipairs(clients) do
                client.config.settings.python = client.config.settings.python or {}
                client.config.settings.python.pythonPath = py_pth
                client:notify('workspace/didChangeConfiguration', {
                    settings = client.config.settings
                })
            end
        end
    end, 100)  -- Small delay to ensure LSP is ready

end

vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client.name == 'pyright' then
            local current_file = vim.api.nvim_buf_get_name(args.buf)
            if current_file ~= '' then
                local start_dir = vim.fn.fnamemodify(current_file, ':p:h')
                vim.schedule(function()
                    local venv_path = find_venv(start_dir)
                    config_pyright_path(venv_path, args.buf)
                end)
            end
        end
    end,
})



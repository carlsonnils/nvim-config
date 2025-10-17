

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
            local python_path = venv_path .. '/bin/python'
            -- Check if python exists in venv
            if vim.fn.executable(python_path) == 1 then
                -- Get or create LSP client for this buffer
                local clients = vim.lsp.get_clients({bufnr = bufnr, name = 'pyright'})
                if #clients > 0 then
                    -- Update existing client settings
                    for _, client in ipairs(clients) do
                        client.config.settings.python = client.config.settings.python or {}
                        client.config.settings.python.pythonPath = python_path
                        client.notify('workspace/didChangeConfiguration', {
                            settings = client.config.settings
                        })
                    end
                    print('Pyright: Using venv at ' .. venv_path)
                -- else
                --     -- Start new client with venv
                --     vim.lsp.start({
                --         name = 'pyright',
                --         cmd = {'pyright-langserver', '--stdio'},
                --         root_dir = vim.fs.dirname(vim.fs.find({'pyproject.toml', 'setup.py', '.git'}, {upward = true})[1]),
                --         settings = {
                --             python = {
                --                 pythonPath = python_path
                --             }
                --         }
                --     })
                --     print('Pyright: Started with venv at ' .. venv_path)
                end
            else
                print('Pyright: Found .venv but no python binary at ' .. python_path)
            end
        else
            print('Pyright: No .venv found in current or parent directories')
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


return {
    cmd = { 'ruff', 'server' },
    filetypes = { 'python' },
    root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git', 'main.py', '.venv' },
    settings = {
        indent_width = 4,
        line_length = 90,
        format = {
            docstring_code_format = true,
            indent_style = "space",
            quote_style = "double",
        },
    },
}

-- lua/user/quickfix-build.lua
-- Per-filetype build/run commands that populate the quickfix list.

local M = {}

local configs = {
  go = {
    makeprg = "go build ./...",
    errorformat = "%f:%l:%c: %m",
  },
  c = {
    makeprg = "gcc -Wall -Wextra -c %:p -o /tmp/%:t:r.o",
    errorformat = "%f:%l:%c: %trror: %m,%f:%l:%c: %tarning: %m",
  },
  rust = {
    makeprg = "cargo build --message-format=short",
    errorformat = "%f:%l:%c: %t%*[a-z]: %m",
  },
  zig = {
    makeprg = "zig build",
    errorformat = "%f:%l:%c: error: %m",
  },
  python = {
    makeprg = "uv run %",
    errorformat = '%*[ ]File "%f"\\, line %l%.%#',
  },
  lua = {
    makeprg = "lua %",
    errorformat = "%f:%l: %m",
  },
  sql = {
    makeprg = 'sqlcmd -W -s "," -i %',
    errorformat = ' Msg %n\\, Level %*\\d\\, State %*\\d\\, Server %.%#\\, Line %l',
  },
}

function M.setup()
  local group = vim.api.nvim_create_augroup("QuickfixBuild", { clear = true })

  for ft, cfg in pairs(configs) do
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = ft,
      callback = function(args)
        vim.bo[args.buf].makeprg = cfg.makeprg
        vim.bo[args.buf].errorformat = cfg.errorformat
      end,
    })
  end

  -- <leader>m: build/run current file's language, open quickfix on results
  vim.keymap.set("n", "<leader>m", function()
    vim.cmd("make")
    local qf = vim.fn.getqflist()
    if #qf > 0 then
      vim.cmd("copen")
    else
      vim.notify("No errors", vim.log.levels.INFO)
    end
  end, { desc = "Build/run and show quickfix" })

  -- quality-of-life navigation
  vim.keymap.set("n", "]q", "<cmd>cnext<cr>zz", { desc = "Next quickfix item" })
  vim.keymap.set("n", "[q", "<cmd>cprev<cr>zz", { desc = "Prev quickfix item" })
  vim.keymap.set("n", "<leader>qq", "<cmd>copen<cr>G", { desc = "Open quickfix" })
  vim.keymap.set("n", "<leader>qc", "<cmd>cclose<cr>", { desc = "Close quickfix" })
end

return M

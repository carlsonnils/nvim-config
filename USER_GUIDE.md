# Neovim Configuration User Guide

A minimal, single-file (`init.lua`) Neovim 0.12+ configuration using the built-in `vim.pack` package manager, Kanagawa themes, `oil.nvim`, `fzf-lua`, Treesitter, native LSP (with completions disabled), and `conform.nvim`.

---

## 1. Setup & Plugin Management

### Installing the Config
Place `init.lua` and `USER_GUIDE.md` inside your Neovim config directory (`USER_GUIDE.md` is read by `:Keybinds` / `<Leader>?`):
- **Linux / macOS:** `~/.config/nvim/`
- **Windows:** `%LOCALAPPDATA%\nvim\`

On first launch, `vim.pack` will prompt to clone and install the configured plugins automatically.

### Included Plugins
| Plugin | Purpose |
|---|---|
| `rebelot/kanagawa.nvim` | Colorschemes (`wave`, `dragon`, `lotus`) |
| `nvim-mini/mini.icons` | Filetype icons for Oil, nvim-tree, and fzf-lua (requires a Nerd Font) |
| `stevearc/oil.nvim` | Buffer-based file explorer (default for directories; replaces `netrw`) |
| `nvim-tree/nvim-tree.lua` | Project file tree explorer (left sidebar by default; switchable to float) |
| `ibhagwan/fzf-lua` | Fuzzy finder for files, grep, buffers, symbols, and diagnostics |
| `lewis6991/gitsigns.nvim` | Git sign-column change indicators & hunk diff popups |
| `nvim-treesitter/nvim-treesitter` | Syntax highlighting parsers & queries |
| `neovim/nvim-lspconfig` | Default server configurations for Neovim's built-in LSP client |
| `stevearc/conform.nvim` | Code formatting with external formatters and LSP fallback |
| `Kurren123/mssql.nvim` | Microsoft SQL Server client, LSP, & query runner (on-demand) |

### Managing Plugins (`vim.pack`)
- **Update plugins:** Run `:PackUpdate` (opens a review buffer; `:w` to confirm updates or `:q` to cancel, then `:restart`).
- **Lockfile:** `vim.pack` tracks exact plugin revisions in `nvim-pack-lock.json` in your config directory.

---

## 2. System Dependencies

Because external tools are managed outside Neovim (no Mason), install the binaries you need via your OS or language package managers and ensure they are on your `PATH`.

On Arch Linux with `yay`, you can install everything at once using the included script:
```bash
./install-deps.sh
```

### Core Tools
- `git` — Required by `vim.pack` to install/update plugins
- `fzf` — Required by `fzf-lua`
- `rg` (`ripgrep`) — Required for live grep (`<Leader>fg`)
- `fd` — Optional, speeds up file finding in `fzf-lua`
- `tree-sitter` (`tree-sitter-cli`) + a C compiler (`gcc` or `clang`) — Required by `nvim-treesitter` to compile syntax parsers
- `leaf` (`leaf-markdown-viewer`) — Rich terminal Markdown viewer used by `<Leader>?` / `:Keybinds` (falls back to a native floating Markdown buffer if not installed)

### Language Servers & Formatters
| Language | Treesitter Parser | LSP Server Binary | Formatter Binary | Notes |
|---|---|---|---|---|
| **JavaScript / TypeScript** | `javascript`, `typescript`, `tsx` | `typescript-language-server`, `biome` | `biome` | `ts_ls` handles types & navigation; `biome` handles linting & formatting (`biome` LSP activates when `biome.json`/`biome.jsonc` or `biomejs` in `package.json` is present). |
| **Svelte** | `svelte`, `html`, `css` | `svelteserver` (`svelte-language-server`) | `svelteserver` *(built-in LSP)* | Formats `.svelte` files via the Svelte LSP fallback. For cross-file `.js`/`.ts` ↔ `.svelte` references, install `typescript-svelte-plugin` in the project. |
| **Python** | `python` | `ty`, `ruff` | `ruff` | Astral's `ty` (`ty server`) for types/navigation; `ruff` for linting, formatting, and import sorting. |
| **Rust** | `rust` | `rust-analyzer` | `rustfmt` | Standard Rust toolchain (`rustup`). |
| **Go** | `go` | `gopls` | `gofmt` | `gofmt` ships with the Go toolchain. |
| **C / C++** | `c`, `cpp` | `clangd` | `clang-format` | Provided by `clang` on Arch Linux. |
| **SQL / MSSQL** | `sql` | `MicrosoftSqlToolsServiceLayer` *(auto-downloaded by `mssql.nvim`)* | `mssql_ls` *(when active)* | Dormant by default; query results open in **`dataframe-textual` (`dv`)** (`uv tool install dataframe-textual`), with native multi-table tabs (`b`/`B`) and `<Leader>mv` to toggle float vs. split. |

> Once `tree-sitter` CLI is installed, launching Neovim will automatically install the configured Treesitter parsers in the background. You can also run `:TSUpdate` manually at any time.

---

## 3. Keybindings

`<Leader>` and `<LocalLeader>` are both mapped to **`Space`**.

### General
| Keybind | Mode | Action |
|---|---|---|
| `<Leader>?` | Normal | Open `USER_GUIDE.md` in `leaf` inside a floating window at the Keybindings section (`:Keybinds`; `t` TOC, `/` search, `?` `leaf` help, `q` close) |
| `<Esc>` | Normal | Clear search highlight (`:nohlsearch`) |
| `<Esc><Esc>` | Terminal | Exit terminal mode back to Normal mode |

### Windows, Tabs & Terminals
| Keybind | Mode | Action |
|---|---|---|
| `<Leader>h` | Normal | Move to left window |
| `<Leader>j` | Normal | Move to below window |
| `<Leader>k` | Normal | Move to above window |
| `<Leader>l` | Normal | Move to right window |
| `<Leader>u` | Normal | Increase window height (`:resize +4`) |
| `<Leader>p` | Normal | Decrease window height (`:resize -4`) |
| `<Leader>i` | Normal | Increase window width (`:vertical resize +4`) |
| `<Leader>o` | Normal | Decrease window width (`:vertical resize -4`) |
| `gt` / `gT` | Normal | Next / previous tab *(Neovim default)* |
| `{N}gt` | Normal | Jump to tab `N`, e.g. `1gt`, `2gt` *(Neovim default)* |
| `g<Tab>` | Normal | Switch to last accessed tab *(Neovim default)* |
| `<C-w>T` | Normal | Move current split window into its own new tab *(Neovim default)* |
| `:tabnew` / `:tabclose` / `:tabonly` | Command | Open new tab / close current tab / close all other tabs *(Neovim default)* |
| `<Leader>tf` | Normal | Toggle persistent **floating terminal** (`<Esc><Esc>` then `q`/`<Esc>` hides; `exit`/`<C-d>` quits) |
| `<Leader>tj` | Normal | Open terminal split below |
| `<Leader>tk` | Normal | Open terminal split above |
| `<Leader>tl` | Normal | Open vertical terminal split right |
| `<Leader>th` | Normal | Open vertical terminal split left |

### File Browser (`oil.nvim`)
`netrw` is completely disabled; opening a directory (`nvim .` or `:e path/to/dir`) opens Oil automatically, and hidden/dot files are shown by default.

| Keybind | Context | Action |
|---|---|---|
| `-` | Normal (anywhere) | Open parent directory of current file in Oil |
| `<Leader>ee` | Normal (anywhere) | Open Oil in current window |
| `<Leader>ed` | Normal (anywhere) | Prompt for a directory path (`<Tab>` completion) and open it in Oil |
| `<Leader>ek` | Normal (anywhere) | Open Oil in horizontal split **above** |
| `<Leader>ej` | Normal (anywhere) | Open Oil in horizontal split **below** |
| `<Leader>eh` | Normal (anywhere) | Open Oil in vertical split **left** |
| `<Leader>el` | Normal (anywhere) | Open Oil in vertical split **right** |
| `<Leader>ef` | Normal (anywhere) | Open Oil in a **floating window** (`<C-c>` inside float to close) |
| `<CR>` | Inside Oil buffer | Open file or enter directory under cursor |
| `<C-h>` | Inside Oil buffer | Open entry under cursor in a **horizontal split** *(built-in)* |
| `<C-s>` | Inside Oil buffer | Open entry under cursor in a **vertical split** *(built-in)* |
| `<C-t>` | Inside Oil buffer | Open entry under cursor in a **new tab** *(built-in)* |
| `-` | Inside Oil buffer | Go up to parent directory |
| `_` | Inside Oil buffer | Open Neovim's current working directory |
| `g.` | Inside Oil buffer | Toggle hidden files |
| `g?` | Inside Oil buffer | Show all Oil buffer keymaps |
| `:w` | Inside Oil buffer | Apply filesystem edits (create, rename, move, delete) |

### File Tree (`nvim-tree.lua`)
Defaults to a **left sidebar** (`width = 35`) and can be switched to a **centered floating window** and back via `<Leader>nv` (`:NvimTreeLayout`). `hijack_directories` is disabled so opening directories (`nvim .` / `:e dir/`) still opens Oil.

| Keybind | Context | Action |
|---|---|---|
| `<Leader>nt` | Normal (anywhere) | Toggle `nvim-tree` open/closed (`:NvimTreeToggle`) |
| `<Leader>nf` | Normal (anywhere) | Reveal and focus the current file in `nvim-tree` (`:NvimTreeFindFile`) |
| `<Leader>nv` | Normal (anywhere) | Switch `nvim-tree` between **left sidebar** and **floating window** (`:NvimTreeLayout`) |
| `<CR>` / `o` | Inside `nvim-tree` | Open file or expand/collapse directory *(built-in)* |
| `<C-x>` | Inside `nvim-tree` | Open file in a **horizontal split** *(built-in)* |
| `<C-v>` | Inside `nvim-tree` | Open file in a **vertical split** *(built-in)* |
| `<C-t>` | Inside `nvim-tree` | Open file in a **new tab** *(built-in)* |
| `a` | Inside `nvim-tree` | Create file or directory (end with `/` for directory) *(built-in)* |
| `r` | Inside `nvim-tree` | Rename file or directory *(built-in)* |
| `d` | Inside `nvim-tree` | Delete file or directory *(built-in)* |
| `c` / `x` / `p` | Inside `nvim-tree` | Copy / cut / paste file or directory *(built-in)* |
| `H` | Inside `nvim-tree` | Toggle hidden/dotfiles *(built-in)* |
| `R` | Inside `nvim-tree` | Refresh tree *(built-in)* |
| `g?` | Inside `nvim-tree` | Show all `nvim-tree` keymaps *(built-in)* |
| `q` | Inside `nvim-tree` | Close `nvim-tree` window *(built-in)* |

### Fuzzy Finding (`fzf-lua`)
| Keybind | Mode | Action |
|---|---|---|
| `<Leader>ff` | Normal | Find files |
| `<Leader>ff` | Visual | Find files using current visual selection as initial query |
| `<Leader>fg` | Normal | Live grep across project |
| `<Leader>fg` | Visual | Live grep across project using current visual selection as initial query |
| `<Leader>fb` | Normal | Switch open buffers |
| `<Leader>fr` | Normal | Recent files (`oldfiles`) |
| `<Leader>fh` | Normal | Search Neovim help tags |
| `<Leader>fk` | Normal | Search all configured keymaps |
| `<Leader>fd` | Normal | Workspace diagnostics |
| `<Leader>fs` | Normal | LSP document symbols |
| `<Leader>/` | Normal | Fuzzy search lines in current buffer |
| `<C-s>` | Inside `fzf-lua` | Open selected result in a **horizontal split** *(built-in)* |
| `<C-v>` | Inside `fzf-lua` | Open selected result in a **vertical split** *(built-in)* |
| `<C-t>` | Inside `fzf-lua` | Open selected result in a **new tab** *(built-in)* |

### Themes (`kanagawa.nvim`)
Defaults to `kanagawa-wave` on startup.

| Keybind | Mode | Action |
|---|---|---|
| `<Leader>cw` | Normal | Switch to **Kanagawa Wave** (default dark) |
| `<Leader>cd` | Normal | Switch to **Kanagawa Dragon** (warmer/darker) |
| `<Leader>cl` | Normal | Switch to **Kanagawa Lotus** (light) |
| `<Leader>cs` | Normal | Open interactive colorscheme picker (`fzf-lua`) |

### LSP & Diagnostics
All LSP completion popups and `omnifunc` completions are disabled.

#### Jump in Current Buffer (Full Screen)
| Keybind | Mode | Action |
|---|---|---|
| `gd` | Normal | Go to definition in current buffer |
| `gD` | Normal | Go to declaration in current buffer |
| `gri` | Normal | Go to implementation in current buffer *(Neovim default)* |
| `grt` | Normal | Go to type definition in current buffer *(Neovim default)* |
| `grr` | Normal | Find references *(Neovim default)* |

#### Preview in Floating Window
If multiple locations match, `fzf-lua` opens a selector first and then displays the chosen location in the floating window.

| Keybind | Context | Action |
|---|---|---|
| `gpd` | Normal | Preview **definition** in floating window |
| `gpD` | Normal | Preview **declaration** in floating window |
| `gpi` | Normal | Preview **implementation** in floating window |
| `gpt` | Normal | Preview **type definition** in floating window |
| `gpr` | Normal | Preview **references** in floating window |
| `q` / `<Esc>` | Inside float | Close the floating preview window |
| `<CR>` | Inside float | Open the previewed file/cursor position full screen in the current buffer |

#### Other LSP Actions
| Keybind | Mode | Action |
|---|---|---|
| `K` | Normal | Show hover documentation *(Neovim default)* |
| `<Leader>rn` / `grn` | Normal | Rename symbol |
| `<Leader>ca` / `gra` | Normal, Visual | Code action (uses `fzf-lua` UI picker) |
| `gO` | Normal | Document symbols *(Neovim default)* |
| `<C-s>` | Insert | Signature help *(Neovim default)* |
| `<Leader>d` / `<C-w>d` | Normal | Show line diagnostics in floating window |
| `]d` / `[d` | Normal | Jump to next / previous diagnostic *(Neovim default)* |

### Git (`gitsigns.nvim`)
Shows only sign-column indicators for added, modified, and deleted lines (unstaged and staged).

| Keybind | Mode | Action |
|---|---|---|
| `<Leader>gp` | Normal | Preview diff for current hunk in floating popup (`:GitDiffHunk`) |
| `<Leader>gp` | Visual | Preview diff for all hunks in selected lines (`:'<,'>GitDiffHunk`) |
| `<Leader>gh` | Normal | Fuzzy search git hunks (1 entry per hunk via `gitsigns`, with full file preview in `fzf-lua`) |
| `]c` / `[c` | Normal | Jump to next / previous git hunk |

### Formatting (`conform.nvim`)
Formatting is manual only (no format-on-save).

| Keybind | Mode | Action |
|---|---|---|
| `<Leader>fm` | Normal, Visual | Format entire buffer or selected range |

### Code Runner (`<Leader>rr`)
Auto-saves (`:update`) and runs the current file in a **floating terminal** by default (or a **bottom split** via `<Leader>rv` / `:RunLayout`). Supports `python` (`uv run`), `javascript`/`typescript` (`node`), `go` (`go run`), `rust` (`cargo run` or `rustc`), `c`/`cpp` (`gcc`/`g++`), and `sh`/`bash` (`bash`).

| Keybind | Context | Action |
|---|---|---|
| `<Leader>rr` | Normal | Save and run current file (`:RunFile`) |
| `<Leader>rv` | Normal | Toggle runner output between **floating window** and **bottom split** (`:RunLayout`) |
| `q` / `<Esc>` | Runner (Normal) | Close the runner output window (auto-enters Normal mode when process exits) |

### SQL Server (`mssql.nvim` — On-Demand)
`mssql.nvim` is **off by default** so non-MSSQL `.sql` files/projects (Postgres, SQLite, MySQL, etc.) are unaffected.
Activate it either:
- **Per project:** Create an empty `.mssql` file in your project root (`touch .mssql`); opening any `.sql` file in that repo auto-activates `mssql.nvim`.
- **Manually anytime:** Press `<Leader>mm` (toggles on/off) or run `:MssqlStart` (`:MssqlStop` to turn off).

Once activated, `:MSSQL <Command>` and the `<Leader>m` keymaps become available. Every SQL execution opens in a **floating window** by default (or a **bottom split** via `<Leader>mv` / `:MssqlResultsLayout`):
- **Tabular data & stored procedure messages:** Exported as full untruncated CSVs and opened in **`dataframe-textual` (`dv`)** (`1: Results`), with a companion **`2: Messages`** tab in the same window (`<M-m>` / `<F2>` or `<Leader>mg` to flip between tables and `PRINT` output, row counts, execution time, and SQL errors without closing `dv`). Multiple result sets open as native tabs inside `dv` (`b`/`B`), including completed `SELECT` tables from stored procedures/batches that error partway through.
- **Non-data statements, 0-row queries, & errors:** DDL (`DROP TABLE`, `CREATE TABLE`, `ALTER`), DML row counts (`DELETE`, `INSERT`, `UPDATE`), `PRINT` output, 0-row `SELECT` headers, and SQL errors open directly in the message/result view (`q` / `<Esc>` to close).

| Keybind | Mode | Action |
|---|---|---|
| `<Leader>mm` | Normal | Toggle `mssql.nvim` on/off (`:MssqlStart` / `:MssqlStop`) |
| `<Leader>mv` | Normal | Toggle MSSQL results window between **floating window** and **bottom split** (`:MssqlResultsLayout`) |
| `<Leader>mo` | Normal | Reopen the last query's results (or messages if no tables) (`:MssqlResults`) |
| `<Leader>mg` | Normal | Open or toggle the last query's **Messages** tab (`PRINT` output, row counts, errors) (`:MssqlMessages`) |
| `<M-m>` / `<F2>` | Inside `dv` or Messages | Switch between **`1: Results` (`dv`)** and **`2: Messages`** tabs (`m` or `<Tab>` in Messages also returns to Results) |
| `q` / `<Esc>` | Messages / 0-row view | Close the SQL message/error/0-row result window |
| `b` / `B` | Inside `dv` | Next / previous result table tab (`S` opens the Sheets overview modal) |
| `Enter` / `Tab` | Inside `dv` | Row detail modal (key-value pairs) / Cell detail modal (`Shift+Tab` cycles cursor mode) |
| `[` / `]` | Inside `dv` | Sort current column ascending / descending (`I` stats, `F` frequency counts, `Q` SQL filter) |
| `<C-t>` | Inside `dv` | Save current tab/view to `.csv`, `.parquet`, `.xlsx`, or `.tsv` |
| `q` / `gq` / `<C-q>` | Inside `dv` | Close current tab (`q`), quit all tabs (`gq`), or force-quit viewer (`<C-q>`) |
| `<Leader>mn` | Normal | Open new SQL query buffer (`:MSSQL NewQuery`) |
| `<Leader>md` | Normal | Open new query on `default` connection (`:MSSQL NewDefaultQuery`) |
| `<Leader>mc` | Normal | Connect current buffer (`:MSSQL Connect`) |
| `<C-l>` / `<C-Space>` | Insert (MSSQL buffer) | Trigger SQL Server object/table/column suggestions (`<C-n>`/`<C-p>` select, `<C-y>` accept; no auto-popup) |
| `<Leader>mq` | Normal | Disconnect current buffer (`:MSSQL Disconnect`) |
| `<Leader>mx` | Normal, Visual | Execute buffer or visual selection (`:MSSQL ExecuteQuery`) |
| `<Leader>ml` | Normal | Cancel running query (`:MSSQL CancelQuery`) |
| `<Leader>ms` | Normal | Switch database (in query buffer) or save results (`.csv`/`.json`/`.xlsx`/`.xml` in results buffer) |
| `<Leader>mf` | Normal | Find table/view/proc/function & generate script (`:MSSQL Find`) |
| `<C-s>` / `<C-v>` / `<C-t>` | Inside `<Leader>mf` | Open generated SQL script in a **horizontal split** (`<C-s>`), **vertical split** (`<C-v>`), or **new tab** (`<C-t>`) |
| `<Leader>me` | Normal | Edit `connections.json` (`:MSSQL EditConnections`) |
| `<Leader>mr` | Normal | Refresh object cache (`:MSSQL RefreshCache`) |

---

## 4. Useful Troubleshooting Commands

- `:Keybinds` — Open `USER_GUIDE.md` in `leaf` inside a floating window at the Keybindings section (falls back to native Markdown float if `leaf` is not installed)
- `:NvimTreeLayout` — Switch `nvim-tree` between left sidebar and floating window (`<Leader>nv`)
- `:RunFile` / `:RunLayout` — Run the current file or toggle runner output between floating window and bottom split
- `:GitDiffHunk` — Show floating git diff for the current hunk or a `<line1>,<line2>` range
- `:MssqlStart` / `:MssqlStop` — Manually start or stop `mssql.nvim` for the current session
- `:MssqlResultsLayout` — Toggle `dv` query results between floating window and bottom split
- `:MssqlResults` — Reopen the most recent query results (`1: Results` in `dv`, or `Messages` if no tables)
- `:MssqlMessages` — Open or toggle the most recent query's `2: Messages` tab (`PRINT` logs, row counts, errors)
- `:MssqlSaveCsv [path]` — Copy the first exported result CSV directly to a `.csv` file (or press `<C-t>` inside `dv`)
- `:checkhealth` — Check overall Neovim, Treesitter, and LSP health
- `:checkhealth vim.lsp` — Inspect active LSP clients attached to buffers
- `:ConformInfo` — Check detected formatters and availability for the current buffer
- `:TSUpdate` — Update installed Treesitter parsers
- `:PackUpdate` — Update all plugins managed by `vim.pack`

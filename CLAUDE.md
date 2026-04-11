# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`conflict.nvim` is a Neovim plugin for resolving Git merge conflicts, styled after VSCode's conflict UI. It provides automatic highlighting, VSCode-style action bars, 2-way/3-way diff views, and AI-assisted merge suggestions (via Avante.nvim).

## Development Commands

There is no build step. This is a pure Lua Neovim plugin. Development workflow:

- **Manual testing**: Load the plugin in Neovim using Lazy.nvim pointing to the local path
- **No automated tests exist**: The project has no test runner or test files configured

To test locally with Lazy.nvim, point the plugin spec to the local directory:
```lua
{ dir = "/path/to/conflict.nvim", config = function() require("conflict").setup() end }
```

## Architecture

### Module Structure

```
lua/conflict/
├── init.lua     -- Entry point: setup(), guards against double-init, registers autocmds + keymaps
├── config.lua   -- Options merging, highlight group definitions, hex color blending algorithm
├── detect.lua   -- Buffer scanning for conflict markers, extmark-based highlighting, navigation
├── resolve.lua  -- Resolution actions (accept/reject), 2-way/3-way scratch diff views
└── ai.lua       -- AI suggestion via Avante.nvim provider
```

### Data Flow

1. User calls `require("conflict").setup(opts)` — merges opts into defaults, applies highlights
2. Autocmds on `BufReadPost`, `BufWritePost`, `InsertLeave` trigger `detect.detect_and_highlight()`
3. `detect_conflicts()` scans the buffer for `<<<<<<<`, `|||||||`, `=======`, `>>>>>>>` markers and returns a list of conflict tables: `{ start, middle, base, end_ }` (line numbers)
4. `highlight()` renders extmarks: virtual text action bar above each conflict, line highlight groups per section. LSP diagnostics and TreeSitter are disabled when conflicts are present.
5. Resolution functions in `resolve.lua` call `detect_conflicts()` fresh each time, manipulate lines via `nvim_buf_set_lines`, then re-run detection.

### Key Design Decisions

- **Extmarks for UI**: All highlights use `nvim_buf_set_extmark` with `line_hl_group` and `virt_lines` (not signs or decorations that pollute gutter)
- **LSP/TS suppression**: When conflicts are detected, LSP diagnostics are cleared and TreeSitter is stopped to avoid noisy errors on invalid syntax
- **Color blending**: `config.lua` blends configured hex colors with the current background color at 40% opacity so highlights work across colorschemes
- **Scratch diff buffers**: `resolve.lua` creates `nofile` scratch buffers for diff views, each pane gets custom `winhighlight` matching the conflict color scheme

### Conflict Table Shape

```lua
{
  start  = number,   -- line of <<<<<<<
  middle = number,   -- line of =======
  base   = number,   -- line of ||||||| (nil for 2-way conflicts)
  end_   = number,   -- line of >>>>>>>
}
```

### Default Keymaps (prefix: `<leader>c`)

| Suffix | Action |
|--------|--------|
| `a` | Accept Current (ours) |
| `i` | Accept Incoming (theirs) |
| `b` | Accept Both |
| `0` | Accept None |
| `n` | Next conflict |
| `p` | Previous conflict |
| `2` | Open 2-way diff tab |
| `3` | Open 3-way diff tab |
| `s` | AI suggest merge |

## Dependencies

- **Required**: none (core features are self-contained)
- **Optional**: `tpope/vim-fugitive`, `yetone/avante.nvim` (for AI), `sindrets/diffview.nvim`

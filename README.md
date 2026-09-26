# conflict.nvim

Resolve merge conflicts directly inside Neovim, with inline actions, project-wide detection, and optional 2-way/3-way comparison. Works on Git merge conflicts as well as manually pasted conflict markers.

## Features

- **Color-blended highlighting** — adapts to your colorscheme
- **Works everywhere** — git merge, manually pasted markers
- **Project listing** — `<leader>cl` lists all conflicts across project
- **User events** — `ConflictDetected`, `ConflictResolved` for automation
- **2-way/3-way diffs** — with diffview.nvim integration
- **Mouse-clickable actions** — optional action bar on markers
- **LSP auto-disabled** — suppressed during merge, re-enabled after


## Demo

### Markers like VSCode
<img src="./images/have-markers.png" >

### No markers
<img src="./images/no-markers.png" >

### 2-way
<img src="./images/2-way.png" >

### 3-way
<img src="./images/3-way.png" >


## Install

```lua
{
  "nxhung2304/conflict.nvim",
  config = function()
    require("conflict").setup()
  end,
}
```

Optional: `diffview.nvim`

## Workflow

```text
1. Open a conflicted file
2. Jump between conflicts with <leader>cn / <leader>cp
3. Inspect with <leader>c2 (2-way) or <leader>c3 (3-way) if unsure
4. Resolve with <leader>ca / ci / cb / c0
5. Run git diff / tests to confirm correctness
```

`Current`/`Incoming`/`Base` map to standard Git merge terms:

- **Current** = ours / current branch
- **Incoming** = theirs / branch being merged
- **Base** = common ancestor (diff3 conflicts only)

Accepting a section resolves the *conflict marker*, not necessarily the *logic* — always review the result before committing.

## Config

```lua
require("conflict").setup({
  keymaps = { leader = "<leader>" },
  ui = { markers = false },           -- clickable action buttons
  detect = { anywhere = true },       -- detect outside git merge
  colors = {
    current  = "#56CC7A",
    incoming = "#40A6FF",
    base     = "#FFCC66",
  },
})
```

## Keymaps

| Key | Action |
|-----|--------|
| `<leader>ca` | Accept Current |
| `<leader>ci` | Accept Incoming |
| `<leader>cb` | Accept Both |
| `<leader>c0` | Accept None |
| `<leader>cn` | Next conflict |
| `<leader>cp` | Previous conflict |
| `<leader>c2` | 2-way diff |
| `<leader>c3` | 3-way diff |
| `<leader>cl` | List conflicts |

## Commands

```vim
:Conflict list     " List all project conflicts
:Conflict next     " Jump to next
:Conflict prev     " Jump to previous
```

## Events

```lua
vim.api.nvim_create_autocmd("User", {
  pattern = "ConflictDetected",
  callback = function(data) print("Conflict in buffer " .. data.bufnr) end,
})
```

## Statusline Integration

```lua
-- Get conflict count in current buffer
require("conflict").get_conflict_count()

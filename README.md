# conflict.nvim

Plugin resolve Git conflict đơn giản, nhanh, có hỗ trợ AI (gần giống VSCode).

## Tính năng
- Tự động highlight conflict
- Keymaps `<leader>ca`, `ci`, `cb`, `c0`, `cn`, `cs`...
- 2-way & 3-way diff
- AI gợi ý merge (Avante.nvim)

## Cài đặt (Lazy.nvim)

```lua
{
  "nxhung2304/conflict.nvim",
  dependencies = { "tpope/vim-fugitive", "yetone/avante.nvim", "sindrets/diffview.nvim" },
  config = function()
    require("conflict").setup({
      ai = { enabled = true, provider = "avante" }
    })
  end
}

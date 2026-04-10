# conflict.nvim

Plugin resolve Git conflict đơn giản, nhanh, có hỗ trợ AI (gần giống VSCode).

## Tính năng

- Tự động highlight từng section (current / base / incoming) với màu nền riêng biệt
- Marker lines (`<<<<<<<`, `|||||||`, `=======`, `>>>>>>>`) không có nền — chỉ hiển thị label màu
- Tự động tắt LSP diagnostics khi file có conflict, bật lại khi đã resolve xong
- Action bar (VSCode-style) phía trên mỗi conflict block
- Keymaps đầy đủ để accept/navigate conflict
- 2-way & 3-way diff
- AI gợi ý merge (Avante.nvim)

## Cài đặt (Lazy.nvim)

```lua
{
  "nxhung2304/conflict.nvim",
  dependencies = { "tpope/vim-fugitive", "yetone/avante.nvim", "sindrets/diffview.nvim" },
  config = function()
    require("conflict").setup()
  end
}
```

## Cấu hình

Tất cả options đều có giá trị mặc định, chỉ override những gì cần:

```lua
require("conflict").setup({
  keymaps = {
    leader = "<leader>",  -- prefix cho tất cả keymaps
  },
  -- Màu nền cho từng section (hex string hoặc số nguyên 24-bit)
  colors = {
    current  = "#56CC7A",  -- green  — current / ours
    incoming = "#40A6FF",  -- blue   — incoming / theirs
    base     = "#FFCC66",  -- amber  — base / ancestor (diff3)
    both     = "#88CC44",  -- green  — "accept both" action
    none     = "#808080",  -- gray   — "accept none" action
  },
  ai = {
    enabled  = true,
    provider = "avante",
  },
})
```

## Keymaps

| Keymap | Hành động |
|--------|-----------|
| `<leader>ca` | Accept Current (ours) |
| `<leader>ci` | Accept Incoming (theirs) |
| `<leader>cb` | Accept Both |
| `<leader>c0` | Accept None |
| `<leader>cn` | Next conflict |
| `<leader>cp` | Previous conflict |
| `<leader>c2` | Mở 2-way diff |
| `<leader>c3` | Mở 3-way diff |
| `<leader>cs` | AI gợi ý merge |

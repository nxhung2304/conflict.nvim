local M = {}

local config = require("conflict.config")
local detect = require("conflict.detect")
local resolve = require("conflict.resolve")
local ai = require("conflict.ai")

M.setup = function(opts)
  config.setup(opts or {})

  -- Tự động detect & highlight
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
    group = vim.api.nvim_create_augroup("ConflictAuto", { clear = true }),
    callback = function()
      detect.detect_and_highlight()
    end,
  })

  -- Keymaps
  local leader = config.options.keymaps.leader

  vim.keymap.set("n", leader .. "ca", resolve.accept_current,  { desc = "Accept Current (Ours)" })
  vim.keymap.set("n", leader .. "ci", resolve.accept_incoming, { desc = "Accept Incoming (Theirs)" })
  vim.keymap.set("n", leader .. "cb", resolve.accept_both,     { desc = "Accept Both" })
  vim.keymap.set("n", leader .. "c0", resolve.accept_none,     { desc = "Accept None" })
  vim.keymap.set("n", leader .. "cn", detect.next_conflict,     { desc = "Next Conflict" })
  vim.keymap.set("n", leader .. "cp", detect.prev_conflict,     { desc = "Previous Conflict" })

  -- Diff views
  vim.keymap.set("n", leader .. "c2", resolve.open_2way, { desc = "Open 2-way diff" })
  vim.keymap.set("n", leader .. "c3", resolve.open_3way, { desc = "Open 3-way diff" })

  -- AI Suggest
  vim.keymap.set("n", leader .. "cs", ai.suggest_merge, { desc = "AI Suggest Merge" })
end

return M

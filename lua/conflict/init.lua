local M = {}

local _setup_done = false

M.setup = function(opts)
  -- Guard against calling setup() more than once.
  if _setup_done then
    vim.notify("conflict.nvim: setup() called more than once", vim.log.levels.WARN)
    return
  end
  _setup_done = true

  local config  = require("conflict.config")
  local detect  = require("conflict.detect")
  local resolve = require("conflict.resolve")
  local list    = require("conflict.list")

  config.setup(opts or {})

  -- Only run on normal, modifiable file buffers — not terminals, help, etc.
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
    group = vim.api.nvim_create_augroup("ConflictAuto", { clear = true }),
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      if vim.bo[buf].buftype ~= "" or not vim.bo[buf].modifiable then
        return
      end
      detect.detect_and_highlight()
    end,
  })

  local leader = config.options.keymaps.leader
  local map    = function(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { desc = desc, silent = true })
  end

  map(leader .. "ca", resolve.accept_current,  "Accept Current (Ours)")
  map(leader .. "ci", resolve.accept_incoming, "Accept Incoming (Theirs)")
  map(leader .. "cb", resolve.accept_both,     "Accept Both")
  map(leader .. "c0", resolve.accept_none,     "Accept None")
  map(leader .. "cn", detect.next_conflict,    "Next Conflict")
  map(leader .. "cp", detect.prev_conflict,    "Previous Conflict")
  map(leader .. "c2", resolve.open_2way,       "Open 2-way diff")
  map(leader .. "c3", resolve.open_3way,       "Open 3-way diff")
  map(leader .. "cl", list.list_conflicts,     "List all conflicts")

  -- Mouse click handler for action bar
  vim.keymap.set("n", "<LeftMouse>", detect.on_mouse, { silent = true })

  -- Main user command: :Conflict <action>
  vim.api.nvim_create_user_command("Conflict", function(opts)
    local action = opts.args:lower()
    if action == "list" then
      list.list_conflicts()
    elseif action == "next" then
      detect.next_conflict()
    elseif action == "prev" then
      detect.prev_conflict()
    else
      vim.notify("Unknown Conflict action: " .. action .. ". Use: list, next, prev", vim.log.levels.WARN)
    end
  end, {
    nargs = 1,
    complete = function()
      return { "list", "next", "prev" }
    end,
    desc = "Conflict management command",
  })
end

return M

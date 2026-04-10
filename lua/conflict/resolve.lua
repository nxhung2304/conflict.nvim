local M = {}

local function get_conflict_at_cursor()
	local conflicts = require("conflict.detect").detect_conflicts()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	for _, c in ipairs(conflicts) do
		if row >= c.start and row <= c["end"] then
			return c
		end
	end
	return nil
end

M.accept_current = function()
	local c = get_conflict_at_cursor()
	if not c or not c.middle then
		vim.notify("No conflict found at cursor", vim.log.levels.WARN)
		return
	end
	-- For diff3 (||||||| present), current ends before |||||||; otherwise before =======
	local current_end_0 = c.base and (c.base - 1) or (c.middle - 1)
	vim.api.nvim_buf_set_lines(
		0,
		c.start - 1,
		c["end"],
		false,
		vim.api.nvim_buf_get_lines(0, c.start, current_end_0, false)
	)
	vim.notify("Accepted Current (Ours)", vim.log.levels.INFO)
end

M.accept_incoming = function()
	local c = get_conflict_at_cursor()
	if not c or not c.middle then
		vim.notify("No conflict found at cursor", vim.log.levels.WARN)
		return
	end
	vim.api.nvim_buf_set_lines(
		0,
		c.start - 1,
		c["end"],
		false,
		vim.api.nvim_buf_get_lines(0, c.middle, c["end"] - 1, false)
	)
	vim.notify("Accepted Incoming (Theirs)", vim.log.levels.INFO)
end

M.accept_both = function()
	local c = get_conflict_at_cursor()
	if not c or not c.middle then
		vim.notify("No conflict found at cursor", vim.log.levels.WARN)
		return
	end
	local current_end_0 = c.base and (c.base - 1) or (c.middle - 1)
	local current = vim.api.nvim_buf_get_lines(0, c.start, current_end_0, false)
	local incoming = vim.api.nvim_buf_get_lines(0, c.middle, c["end"] - 1, false)
	vim.api.nvim_buf_set_lines(0, c.start - 1, c["end"], false, vim.list_extend(current, incoming))
	vim.notify("Accepted Both", vim.log.levels.INFO)
end

M.accept_none = function()
	local c = get_conflict_at_cursor()
	if not c then
		return
	end
	vim.api.nvim_buf_set_lines(0, c.start - 1, c["end"], false, {})
	print("✅ Accepted None")
end

-- Per-pane styling config for the diff views.
local pane_style = {
	current = {
		winhighlight = table.concat({
			"Normal:ConflictDiffCurrentNormal",
			"DiffAdd:ConflictDiffCurrentAdd",
			"DiffChange:ConflictDiffCurrentChange",
			"DiffText:ConflictDiffCurrentText",
			"DiffDelete:ConflictDiffCurrentDelete",
		}, ","),
		winbar = "%#ConflictCurrentLabel#  ◀ CURRENT (Ours) %#Normal#",
	},
	incoming = {
		winhighlight = table.concat({
			"Normal:ConflictDiffIncomingNormal",
			"DiffAdd:ConflictDiffIncomingAdd",
			"DiffChange:ConflictDiffIncomingChange",
			"DiffText:ConflictDiffIncomingText",
			"DiffDelete:ConflictDiffIncomingDelete",
		}, ","),
		winbar = "%#ConflictIncomingLabel#  ▶ THEIRS (Incoming) %#Normal#",
	},
	base = {
		winhighlight = table.concat({
			"Normal:ConflictDiffBaseNormal",
			"DiffAdd:ConflictDiffBaseAdd",
			"DiffChange:ConflictDiffBaseChange",
			"DiffText:ConflictDiffBaseText",
			"DiffDelete:ConflictDiffBaseDelete",
		}, ","),
		winbar = "%#ConflictBaseLabel#  ◉ BASE (Ancestor) %#Normal#",
	},
}

-- Creates a scratch buffer and opens it in the current window with diff + styling.
local function open_pane(lines, label, filetype, side)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].buftype   = "nofile"
	vim.bo[buf].swapfile  = false
	vim.bo[buf].buflisted = false
	vim.bo[buf].modifiable = false
	if filetype and filetype ~= "" then
		vim.bo[buf].filetype = filetype
	end
	pcall(vim.api.nvim_buf_set_name, buf, label)
	vim.keymap.set("n", "q", "<cmd>tabclose<cr>", { buffer = buf, silent = true })

	vim.api.nvim_win_set_buf(0, buf)

	local style = pane_style[side]
	if style then
		vim.wo.winhighlight = style.winhighlight
		vim.wo.winbar       = style.winbar
	end

	vim.cmd("diffthis")
end

-- Opens OURS vs THEIRS side-by-side in a new tab using Neovim's built-in diff.
M.open_2way = function()
	local c = get_conflict_at_cursor()
	if not c or not c.middle then
		vim.notify("No conflict found at cursor", vim.log.levels.WARN)
		return
	end

	local ft = vim.bo.filetype
	local current_end_0 = c.base and (c.base - 1) or (c.middle - 1)
	local ours   = vim.api.nvim_buf_get_lines(0, c.start,  current_end_0,  false)
	local theirs = vim.api.nvim_buf_get_lines(0, c.middle, c["end"] - 1,   false)

	vim.cmd("tabnew")
	open_pane(ours,   "OURS (current)",   ft, "current")
	vim.cmd("vsplit")
	open_pane(theirs, "THEIRS (incoming)", ft, "incoming")
end

-- Opens OURS | BASE | THEIRS in a new tab (BASE pane only shown for diff3 conflicts).
M.open_3way = function()
	local c = get_conflict_at_cursor()
	if not c or not c.middle then
		vim.notify("No conflict found at cursor", vim.log.levels.WARN)
		return
	end

	local ft = vim.bo.filetype
	local current_end_0 = c.base and (c.base - 1) or (c.middle - 1)
	local ours   = vim.api.nvim_buf_get_lines(0, c.start,  current_end_0, false)
	local theirs = vim.api.nvim_buf_get_lines(0, c.middle, c["end"] - 1,  false)

	vim.cmd("tabnew")
	open_pane(ours, "OURS (current)", ft, "current")

	if c.base then
		local base = vim.api.nvim_buf_get_lines(0, c.base, c.middle - 1, false)
		vim.cmd("vsplit")
		open_pane(base, "BASE (ancestor)", ft, "base")
	end

	vim.cmd("vsplit")
	open_pane(theirs, "THEIRS (incoming)", ft, "incoming")
end

return M

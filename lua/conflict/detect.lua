local M = {}

local config = require("conflict.config")

local markers = {
	current_start = "^<<<<<<<",
	base_start = "^|||||||",
	middle = "^=======",
	end_conflict = "^>>>>>>>",
}

M.detect_conflicts = function()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local conflicts = {}
	local i = 1

	while i <= #lines do
		if lines[i]:match(markers.current_start) then
			local conflict = { start = i }
			i = i + 1
			while i <= #lines do
				if lines[i]:match(markers.base_start) then
					conflict.base = i
				elseif lines[i]:match(markers.middle) then
					conflict.middle = i
				elseif lines[i]:match(markers.end_conflict) then
					conflict["end"] = i
					break
				end
				i = i + 1
			end
			-- Require both middle and end — skip malformed conflicts.
			if conflict["end"] and conflict.middle then
				table.insert(conflicts, conflict)
			end
		end
		i = i + 1
	end
	return conflicts
end

M.highlight = function(conflicts)
	local ns = vim.api.nvim_create_namespace("ConflictNS")
	vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

	local hl = config.options.highlights

	-- Highlight an entire line with a background colour.
	local function mark(line_0, line_hl)
		vim.api.nvim_buf_set_extmark(0, ns, line_0, 0, { line_hl_group = line_hl })
	end

	-- Virtual-text label only — no line background.
	local function virt_label(line_0, hl_group, text)
		vim.api.nvim_buf_set_extmark(0, ns, line_0, 0, {
			virt_text     = { { text, hl_group } },
			virt_text_pos = "eol",
		})
	end

	for _, c in ipairs(conflicts) do
		if not c.middle then
			goto continue
		end

		-- Action bar with label on the marker line (if enabled in config)
		if config.options.ui.markers then
			vim.api.nvim_buf_set_extmark(0, ns, c.start - 1, 0, {
				virt_text = {
					{ "  " },
					{ "✔ Current", "ConflictActionCurrent" },
					{ " │ ", "ConflictActionSep" },
					{ "✔ Incoming", "ConflictActionIncoming" },
					{ " │ ", "ConflictActionSep" },
					{ "✔ Both", "ConflictActionBoth" },
					{ " │ ", "ConflictActionSep" },
					{ "✘ None", "ConflictActionNone" },
					{ "  ◀ Current", hl.current_text },
				},
				virt_text_pos = "eol",
			})
		else
			-- If markers disabled, still show label without action buttons
			virt_label(c.start - 1, hl.current_text, "  ◀ Current")
		end
		for line = c.start, (c.base or c.middle) - 2 do
			mark(line, hl.current)
		end

		-- ||||||| ancestor (diff3 only) — label only, no line background.
		if c.base then
			virt_label(c.base - 1, hl.base_text, "  ◀ Base ")
			for line = c.base, c.middle - 2 do
				mark(line, hl.base)
			end
		end

		-- Incoming content
		for line = c.middle, c["end"] - 2 do
			mark(line, hl.incoming)
		end

		-- >>>>>>> branch — label only, no line background.
		virt_label(c["end"] - 1, hl.incoming_text, "  ▶ Incoming Change ")

		::continue::
	end
end

M.detect_and_highlight = function()
	local bufnr = vim.api.nvim_get_current_buf()

	-- When anywhere = false, skip detection unless inside a git operation.
	if not config.options.detect.anywhere then
		if not M.is_git_merge_state() then
			vim.diagnostic.enable(true, { bufnr = bufnr })
			pcall(vim.treesitter.start, bufnr)
			return
		end
	end

	local conflicts = M.detect_conflicts()
	if #conflicts > 0 then
		M.highlight(conflicts)
		vim.diagnostic.enable(false, { bufnr = bufnr })
		pcall(vim.treesitter.stop, bufnr)

		-- Disable git blame to make mouse detection reliable
		pcall(function()
			local gitsigns = require("gitsigns")
			-- Try to disable blame line by getting the show_blame status
			if vim.b[bufnr].gitsigns_blame_line then
				vim.b[bufnr]._conflict_blame_was_on = true
				gitsigns.toggle_lineblame()
			else
				vim.b[bufnr]._conflict_blame_was_on = false
			end
			-- Also try to disable via config
			local ok, config = pcall(require, "gitsigns.config")
			if ok and config.config then
				vim.b[bufnr]._conflict_gitsigns_config = vim.b[bufnr]._conflict_gitsigns_config or {}
				vim.b[bufnr]._conflict_gitsigns_config.blame_line = false
			end
		end)

		-- Emit ConflictDetected event
		vim.api.nvim_exec_autocmds("User", {
			pattern = "ConflictDetected",
			data = { bufnr = bufnr, count = #conflicts },
		})
	else
		vim.diagnostic.enable(true, { bufnr = bufnr })
		pcall(vim.treesitter.start, bufnr)

		-- Re-enable git blame if it was on before
		if vim.b[bufnr]._conflict_blame_was_on then
			pcall(function()
				local gitsigns = require("gitsigns")
				if gitsigns.toggle_lineblame then
					gitsigns.toggle_lineblame()
				end
			end)
		end
		vim.b[bufnr]._conflict_blame_was_on = nil
	end
end

M.next_conflict = function()
	local conflicts = M.detect_conflicts()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	for _, c in ipairs(conflicts) do
		if c.start > row then
			vim.api.nvim_win_set_cursor(0, { c.start, 0 })
			return
		end
	end
	print("No more conflicts")
end

M.prev_conflict = function()
	local conflicts = M.detect_conflicts()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	for i = #conflicts, 1, -1 do
		if conflicts[i].start < row then
			vim.api.nvim_win_set_cursor(0, { conflicts[i].start, 0 })
			return
		end
	end
	print("No previous conflicts")
end

-- Returns true if the current directory is inside an active git merge/rebase/cherry-pick.
M.is_git_merge_state = function()
	local gitdir = vim.fn.system("git rev-parse --git-dir 2>/dev/null"):gsub("\n", "")
	if vim.v.shell_error ~= 0 or gitdir == "" then return false end
	return vim.fn.filereadable(gitdir .. "/MERGE_HEAD") == 1
		or vim.fn.filereadable(gitdir .. "/CHERRY_PICK_HEAD") == 1
		or vim.fn.isdirectory(gitdir .. "/rebase-merge") == 1
		or vim.fn.isdirectory(gitdir .. "/rebase-apply") == 1
end

-- Helper: determine action based on click position within text area
-- Maps relative position to action button
local function get_clicked_action_by_distance(click_col, marker_width)
	local rel_pos = click_col - marker_width

	-- Empirically calibrated ranges based on button positions on the action bars
	if rel_pos < 30 then
		return "current"       -- First button area
	elseif rel_pos < 42 then
		return "incoming"      -- Second button area
	elseif rel_pos < 52 then
		return "both"          -- Third button area
	else
		return "none"          -- Fourth button area
	end
end

-- Handle mouse clicks on the action bar (only if markers enabled)
M.on_mouse = function()
	-- Only process clicks if markers are enabled
	if not config.options.ui.markers then
		return
	end

	local mpos = vim.fn.getmousepos()
	if mpos.winid <= 0 then
		return
	end

	-- Move cursor to clicked position first (standard mouse behavior)
	vim.api.nvim_set_current_win(mpos.winid)
	vim.api.nvim_win_set_cursor(mpos.winid, { mpos.line, mpos.column - 1 })

	-- Check if clicked on conflict start marker line
	local conflicts = M.detect_conflicts()
	for _, c in ipairs(conflicts) do
		if mpos.line == c.start then
			-- Get gutter width
			local wininfo = vim.fn.getwininfo(mpos.winid)[1]
			local gutter_width = wininfo.textoff
			local text_col = mpos.wincol - gutter_width

			-- Get the marker line to calculate where virt_text starts
			local lines = vim.api.nvim_buf_get_lines(0, c.start - 1, c.start, false)

			if #lines > 0 then
				local marker_line = lines[1]
				local marker_width = vim.fn.strdisplaywidth(marker_line)

				-- Determine action from click position
				local action = get_clicked_action_by_distance(text_col, marker_width)

				if action then
					local resolve = require("conflict.resolve")
					if action == "current" then
						resolve.accept_current()
					elseif action == "incoming" then
						resolve.accept_incoming()
					elseif action == "both" then
						resolve.accept_both()
					elseif action == "none" then
						resolve.accept_none()
					end
					return
				end
			end
			return
		end
	end
end

return M

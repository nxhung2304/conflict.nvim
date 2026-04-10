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
			if conflict["end"] then
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

	-- The VSCode-style action bar shown above each conflict block.
	local action_bar = {
		{
			{ " ✔ Accept Current Change ",  "ConflictActionCurrent"  },
			{ " │ ", "ConflictActionSep" },
			{ " ✔ Accept Incoming Change ", "ConflictActionIncoming" },
			{ " │ ", "ConflictActionSep" },
			{ " ✔ Accept Both Changes ",    "ConflictActionBoth"     },
			{ " │ ", "ConflictActionSep" },
			{ " ✘ Accept None ",            "ConflictActionNone"     },
		},
	}

	-- Mark a single line: background colour + optional EOL label.
	local function mark(line_0, line_hl, label)
		local opts = { line_hl_group = line_hl }
		if label then
			opts.virt_text     = { { label, line_hl } }
			opts.virt_text_pos = "eol"
		end
		vim.api.nvim_buf_set_extmark(0, ns, line_0, 0, opts)
	end

	for _, c in ipairs(conflicts) do
		if not c.middle then
			goto continue
		end

		-- Action bar floats above <<<<<<< (mimics VSCode codelens)
		vim.api.nvim_buf_set_extmark(0, ns, c.start - 1, 0, {
			line_hl_group    = hl.current_label,
			virt_text        = { { "  ◀ Current Change ", hl.current_label } },
			virt_text_pos    = "eol",
			virt_lines       = action_bar,
			virt_lines_above = true,
		})
		for line = c.start, (c.base or c.middle) - 2 do
			mark(line, hl.current)
		end

		-- ||||||| ancestor (diff3 only)
		if c.base then
			mark(c.base - 1, hl.base_label, "  ◀ Base ")
			for line = c.base, c.middle - 2 do
				mark(line, hl.base)
			end
		end

		-- ======= separator
		mark(c.middle - 1, hl.incoming_label)

		-- Incoming content
		for line = c.middle, c["end"] - 2 do
			mark(line, hl.incoming)
		end

		-- >>>>>>> branch
		mark(c["end"] - 1, hl.incoming_label, "  ▶ Incoming Change ")

		::continue::
	end
end

M.detect_and_highlight = function()
	local conflicts = M.detect_conflicts()
	if #conflicts > 0 then
		M.highlight(conflicts)
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

return M

local M = {}

local detect = require("conflict.detect")

-- Count conflicts in a buffer or file
local function count_conflicts_in_buffer(bufnr)
	if not vim.api.nvim_buf_is_loaded(bufnr) then
		return 0
	end
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local count = 0
	for _, line in ipairs(lines) do
		if line:match("^<<<<<<<") then
			count = count + 1
		end
	end
	return count
end

local function count_conflicts_in_file(filepath)
	local file = io.open(filepath, "r")
	if not file then
		return 0
	end
	local count = 0
	for line in file:lines() do
		if line:match("^<<<<<<<") then
			count = count + 1
		end
	end
	file:close()
	return count
end

-- Get conflict files from git status
local function get_git_conflict_files()
	local result = vim.fn.system("git diff --name-only --diff-filter=U 2>/dev/null")
	if vim.v.shell_error ~= 0 or result == "" then
		return {}
	end
	local files = {}
	for filepath in result:gmatch("[^\n]+") do
		table.insert(files, filepath)
	end
	return files
end

-- Build list of all conflicts in the project
local function collect_all_conflicts()
	local conflicts_by_file = {}
	local git_files = get_git_conflict_files()

	-- Scan git conflict files
	for _, filepath in ipairs(git_files) do
		local count = count_conflicts_in_file(filepath)
		if count > 0 then
			conflicts_by_file[filepath] = { count = count, source = "git" }
		end
	end

	-- Also scan loaded buffers for conflicts (handles non-git conflicts)
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted and vim.bo[bufnr].buftype == "" then
			local filepath = vim.api.nvim_buf_get_name(bufnr)
			if filepath ~= "" then
				local count = count_conflicts_in_buffer(bufnr)
				if count > 0 then
					if not conflicts_by_file[filepath] then
						conflicts_by_file[filepath] = { count = count, source = "buffer" }
					end
				end
			end
		end
	end

	return conflicts_by_file
end

-- Open with Telescope if available, else use quickfix
M.list_conflicts = function()
	local conflicts = collect_all_conflicts()

	if vim.tbl_isempty(conflicts) then
		vim.notify("conflict.nvim: No conflicts found", vim.log.levels.INFO)
		return
	end

	-- Try Telescope first
	local ok, telescope = pcall(require, "telescope")
	if ok then
		return M.list_with_telescope(conflicts)
	end

	-- Fall back to quickfix
	return M.list_with_quickfix(conflicts)
end

-- Use Telescope to list conflicts
M.list_with_telescope = function(conflicts)
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	local entries = {}
	for filepath, info in pairs(conflicts) do
		table.insert(entries, {
			filepath = filepath,
			count = info.count,
		})
	end

	pickers
		.new({}, {
			prompt_title = "Project Conflicts (" .. vim.tbl_count(entries) .. ")",
			finder = finders.new_table({
				results = entries,
				entry_maker = function(entry)
					return {
						value = entry,
						display = string.format("%s (%d conflict%s)", entry.filepath, entry.count, entry.count == 1 and "" or "s"),
						ordinal = entry.filepath,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			previewer = conf.file_previewer({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					vim.cmd("edit " .. vim.fn.fnameescape(selection.value.filepath))
					-- Jump to first conflict
					local conflicts_list = detect.detect_conflicts()
					if #conflicts_list > 0 then
						vim.api.nvim_win_set_cursor(0, { conflicts_list[1].start, 0 })
					end
				end)
				return true
			end,
		})
		:find()
end

-- Use quickfix to list conflicts
M.list_with_quickfix = function(conflicts)
	local qf_items = {}

	for filepath, info in pairs(conflicts) do
		table.insert(qf_items, {
			filename = filepath,
			lnum = 1,
			col = 1,
			text = string.format("%d conflict%s", info.count, info.count == 1 and "" or "s"),
		})
	end

	vim.fn.setqflist(qf_items)
	vim.cmd("copen")
end

return M

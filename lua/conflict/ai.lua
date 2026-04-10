local M = {}

local config = require("conflict.config")

M.suggest_merge = function()
	if not config.options.ai.enabled then
		vim.notify("AI is disabled", vim.log.levels.WARN)
		return
	end

	local buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local conflict_text = table.concat(lines, "\n")

	vim.notify("Đang hỏi AI cách resolve...", vim.log.levels.INFO)

	if config.options.ai.provider == "avante" and package.loaded["avante"] then
		require("avante").ask({
			question = "Resolve git merge conflict sau đây một cách thông minh, giữ logic, clean code và comment nếu cần:\n\n"
				.. conflict_text,
			on_complete = function(result)
				if result then
					vim.notify("AI Suggestion:\n" .. result, vim.log.levels.INFO)
				end
			end,
		})
	else
		vim.notify("Cài avante.nvim để dùng tính năng AI!", vim.log.levels.WARN)
	end
end

return M

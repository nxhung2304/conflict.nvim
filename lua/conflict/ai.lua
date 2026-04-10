local M = {}

local config = require("conflict.config")

M.suggest_merge = function()
  if not config.options.ai.enabled then
    vim.notify("conflict.nvim: AI is disabled", vim.log.levels.WARN)
    return
  end

  local detect = require("conflict.detect")
  local conflicts = detect.detect_conflicts()
  if #conflicts == 0 then
    vim.notify("conflict.nvim: No conflicts found in this buffer", vim.log.levels.WARN)
    return
  end

  -- Send only the conflict blocks, not the whole file.
  local lines = {}
  for _, c in ipairs(conflicts) do
    local block = vim.api.nvim_buf_get_lines(0, c.start - 1, c["end"], false)
    vim.list_extend(lines, block)
    table.insert(lines, "")
  end
  local conflict_text = table.concat(lines, "\n")

  if config.options.ai.provider == "avante" then
    local ok, avante = pcall(require, "avante")
    if not ok then
      vim.notify("conflict.nvim: avante.nvim is not installed", vim.log.levels.WARN)
      return
    end
    vim.notify("conflict.nvim: Asking AI...", vim.log.levels.INFO)
    avante.ask({
      question = "Resolve the following git merge conflict(s). Keep the logic correct and the code clean:\n\n"
        .. conflict_text,
      on_complete = function(result)
        if result and result ~= "" then
          vim.notify("AI suggestion:\n" .. result, vim.log.levels.INFO)
        else
          vim.notify("conflict.nvim: AI returned an empty response", vim.log.levels.WARN)
        end
      end,
    })
  else
    vim.notify(
      "conflict.nvim: Unknown AI provider '" .. tostring(config.options.ai.provider) .. "'",
      vim.log.levels.WARN
    )
  end
end

return M

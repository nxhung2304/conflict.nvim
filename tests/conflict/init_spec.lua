local eq = assert.are.same

local function reset_modules()
	for name, _ in pairs(package.loaded) do
		if name:match("^conflict") then
			package.loaded[name] = nil
		end
	end
end

describe("conflict.setup()", function()
	before_each(function()
		reset_modules()
		pcall(vim.keymap.del, "n", "<leader>ca")
		pcall(vim.api.nvim_del_user_command, "Conflict")
	end)

	it("does not error when called more than once", function()
		local conflict = require("conflict")
		assert.has_no.errors(function()
			conflict.setup()
			conflict.setup()
			conflict.setup()
		end)
	end)

	it("keeps the augroup, keymaps and user command registered after repeat calls", function()
		local conflict = require("conflict")
		conflict.setup()
		conflict.setup()

		assert.has_no.errors(function()
			vim.api.nvim_get_autocmds({ group = "ConflictAuto" })
		end)

		assert.are_not.same("", vim.fn.maparg("<leader>ca", "n"))

		eq(2, vim.fn.exists(":Conflict"))
	end)

	it("re-applies options passed on a later call instead of ignoring them", function()
		local conflict = require("conflict")
		local config = require("conflict.config")

		conflict.setup({ keymaps = { leader = "<leader>c" } })
		conflict.setup({ keymaps = { leader = "<leader>m" } })

		eq("<leader>m", config.options.keymaps.leader)
		assert.are_not.same("", vim.fn.maparg("<leader>mca", "n"))
	end)
end)

describe("conflict.get_conflict_count() buffer lifecycle edge cases", function()
	before_each(function()
		reset_modules()
	end)

	it("counts conflicts correctly after the buffer has been renamed", function()
		local conflict = require("conflict")

		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"<<<<<<< HEAD",
			"ours",
			"=======",
			"theirs",
			">>>>>>> branch",
		})

		vim.api.nvim_buf_set_name(buf, vim.fn.tempname() .. "_renamed.txt")

		eq(1, conflict.get_conflict_count(buf))
	end)

	it("does not silently report a conflict count for a wiped-out buffer", function()
		local conflict = require("conflict")

		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"<<<<<<< HEAD",
			"ours",
			"=======",
			"theirs",
			">>>>>>> branch",
		})

		vim.api.nvim_buf_delete(buf, { force = true })

		local ok = pcall(conflict.get_conflict_count, buf)
		eq(false, ok)
	end)
end)

local eq = assert.are.same

local function reset_modules()
	for name, _ in pairs(package.loaded) do
		if name:match("^conflict") then
			package.loaded[name] = nil
		end
	end
end

local function make_buffer(lines)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_set_current_buf(buf)
	return buf
end

local function place_cursor(row)
	vim.api.nvim_win_set_cursor(0, { row, 0 })
end

local function get_lines()
	return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

describe("conflict.resolve edge cases", function()
	local resolve

	before_each(function()
		reset_modules()
		require("conflict.config").setup()
		resolve = require("conflict.resolve")
	end)

	it("accepts current when the ours section is empty", function()
		make_buffer({
			"before",
			"<<<<<<< HEAD",
			"=======",
			"theirs",
			">>>>>>> branch",
			"after",
		})
		place_cursor(2)

		resolve.accept_current()

		eq({ "before", "after" }, get_lines())
	end)

	it("accepts incoming when the theirs section is empty", function()
		make_buffer({
			"before",
			"<<<<<<< HEAD",
			"ours",
			"=======",
			">>>>>>> branch",
			"after",
		})
		place_cursor(2)

		resolve.accept_incoming()

		eq({ "before", "after" }, get_lines())
	end)

	it("accepts both when ours and theirs are both empty", function()
		make_buffer({
			"before",
			"<<<<<<< HEAD",
			"=======",
			">>>>>>> branch",
			"after",
		})
		place_cursor(2)

		resolve.accept_both()

		eq({ "before", "after" }, get_lines())
	end)

	it("resolves a conflict starting on the first line of the buffer", function()
		make_buffer({
			"<<<<<<< HEAD",
			"ours",
			"=======",
			"theirs",
			">>>>>>> branch",
			"after",
		})
		place_cursor(1)

		resolve.accept_current()

		eq({ "ours", "after" }, get_lines())
	end)

	it("resolves a conflict whose end marker is the last line of the buffer", function()
		make_buffer({
			"before",
			"<<<<<<< HEAD",
			"ours",
			"=======",
			"theirs",
			">>>>>>> branch",
		})
		place_cursor(2)

		resolve.accept_incoming()

		eq({ "before", "theirs" }, get_lines())
	end)

	it("resolves only the targeted conflict when there are several in the buffer, leaving the rest untouched", function()
		make_buffer({
			"<<<<<<< HEAD",
			"ours1",
			"=======",
			"theirs1",
			">>>>>>> branch1",
			"middle",
			"<<<<<<< HEAD",
			"ours2",
			"=======",
			"theirs2",
			">>>>>>> branch2",
			"<<<<<<< HEAD",
			"ours3",
			"=======",
			"theirs3",
			">>>>>>> branch3",
		})
		place_cursor(7)

		resolve.accept_current()

		eq({
			"<<<<<<< HEAD",
			"ours1",
			"=======",
			"theirs1",
			">>>>>>> branch1",
			"middle",
			"ours2",
			"<<<<<<< HEAD",
			"ours3",
			"=======",
			"theirs3",
			">>>>>>> branch3",
		}, get_lines())
	end)

	it("resolves the last remaining conflict in the buffer down to zero conflicts", function()
		local detect = require("conflict.detect")
		make_buffer({
			"before",
			"<<<<<<< HEAD",
			"ours",
			"=======",
			"theirs",
			">>>>>>> branch",
			"after",
		})
		place_cursor(2)

		resolve.accept_incoming()

		eq(0, #detect.detect_conflicts())
		eq({ "before", "theirs", "after" }, get_lines())
	end)

	it("resolving one of two directly adjacent conflicts leaves the other conflict's markers intact", function()
		make_buffer({
			"<<<<<<< HEAD",
			"ours1",
			"=======",
			"theirs1",
			">>>>>>> branch1",
			"<<<<<<< HEAD",
			"ours2",
			"=======",
			"theirs2",
			">>>>>>> branch2",
		})
		place_cursor(1)

		resolve.accept_current()

		eq({
			"ours1",
			"<<<<<<< HEAD",
			"ours2",
			"=======",
			"theirs2",
			">>>>>>> branch2",
		}, get_lines())
	end)

	it("resolves a conflict whose body contains a stray '<<<<<<<'-looking content line", function()
		make_buffer({
			"<<<<<<< HEAD",
			"ours",
			"<<<<<<< looks like a marker but is just content",
			"=======",
			"theirs",
			">>>>>>> branch",
		})
		place_cursor(1)

		resolve.accept_current()

		eq({ "ours", "<<<<<<< looks like a marker but is just content" }, get_lines())
	end)

	it("preserves multi-byte unicode content when accepting both sides", function()
		make_buffer({
			"<<<<<<< HEAD",
			"こんにちは世界 🎉",
			"=======",
			"théirs",
			">>>>>>> branch",
		})
		place_cursor(1)

		resolve.accept_both()

		eq({ "こんにちは世界 🎉", "théirs" }, get_lines())
	end)

	it("preserves a trailing carriage return in surviving lines", function()
		make_buffer({
			"<<<<<<< HEAD\r",
			"ours\r",
			"=======\r",
			"theirs\r",
			">>>>>>> branch\r",
		})
		place_cursor(1)

		resolve.accept_current()

		eq({ "ours\r" }, get_lines())
	end)
end)

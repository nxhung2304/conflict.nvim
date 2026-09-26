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

describe("conflict.detect.detect_conflicts() edge cases", function()
	local detect

	before_each(function()
		reset_modules()
		require("conflict.config").setup()
		detect = require("conflict.detect")
	end)

	it("detects a conflict starting on the first line of the buffer", function()
		make_buffer({
			"<<<<<<< HEAD",
			"ours",
			"=======",
			"theirs",
			">>>>>>> branch",
			"after",
		})

		local conflicts = detect.detect_conflicts()
		eq(1, #conflicts)
		eq(1, conflicts[1].start)
		eq(3, conflicts[1].middle)
		eq(5, conflicts[1]["end"])
	end)

	it("detects a conflict whose end marker is the last line of the buffer", function()
		local lines = {
			"before",
			"<<<<<<< HEAD",
			"ours",
			"=======",
			"theirs",
			">>>>>>> branch",
		}
		make_buffer(lines)

		local conflicts = detect.detect_conflicts()
		eq(1, #conflicts)
		eq(#lines, conflicts[1]["end"])
	end)

	it("detects a conflict with an empty ours (current) section", function()
		make_buffer({
			"<<<<<<< HEAD",
			"=======",
			"theirs",
			">>>>>>> branch",
		})

		local conflicts = detect.detect_conflicts()
		eq(1, #conflicts)
		eq(1, conflicts[1].start)
		eq(2, conflicts[1].middle)
		eq(4, conflicts[1]["end"])
	end)

	it("detects a conflict with an empty theirs (incoming) section", function()
		make_buffer({
			"<<<<<<< HEAD",
			"ours",
			"=======",
			">>>>>>> branch",
		})

		local conflicts = detect.detect_conflicts()
		eq(1, #conflicts)
		eq(3, conflicts[1].middle)
		eq(4, conflicts[1]["end"])
	end)

	it("detects a conflict with both ours and theirs empty", function()
		make_buffer({
			"<<<<<<< HEAD",
			"=======",
			">>>>>>> branch",
		})

		local conflicts = detect.detect_conflicts()
		eq(1, #conflicts)
		eq(1, conflicts[1].start)
		eq(2, conflicts[1].middle)
		eq(3, conflicts[1]["end"])
	end)

	it("detects two conflicts that are directly adjacent (no gap between them)", function()
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

		local conflicts = detect.detect_conflicts()
		eq(2, #conflicts)
		eq({ start = 1, middle = 3, ["end"] = 5 }, conflicts[1])
		eq({ start = 6, middle = 8, ["end"] = 10 }, conflicts[2])
	end)

	it("treats a stray '<<<<<<<'-looking line inside a conflict body as plain content, not a nested conflict", function()
		make_buffer({
			"<<<<<<< HEAD",
			"ours",
			"<<<<<<< looks like a marker but is just content",
			"=======",
			"theirs",
			">>>>>>> branch",
		})

		local conflicts = detect.detect_conflicts()
		eq(1, #conflicts)
		eq(1, conflicts[1].start)
		eq(4, conflicts[1].middle)
		eq(6, conflicts[1]["end"])
	end)

	it("detects conflicts whose marker lines carry a trailing carriage return (CRLF-style content)", function()
		make_buffer({
			"<<<<<<< HEAD\r",
			"ours\r",
			"=======\r",
			"theirs\r",
			">>>>>>> branch\r",
		})

		local conflicts = detect.detect_conflicts()
		eq(1, #conflicts)
		eq(1, conflicts[1].start)
		eq(3, conflicts[1].middle)
		eq(5, conflicts[1]["end"])
	end)

	it("detects conflicts whose sections contain multi-byte unicode content", function()
		make_buffer({
			"<<<<<<< HEAD",
			"こんにちは世界 🎉",
			"=======",
			"théirs",
			">>>>>>> branch",
		})

		local conflicts = detect.detect_conflicts()
		eq(1, #conflicts)
		eq(1, conflicts[1].start)
		eq(3, conflicts[1].middle)
		eq(5, conflicts[1]["end"])
	end)
end)

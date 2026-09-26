local eq = assert.are.same

local function reset_modules()
	for name, _ in pairs(package.loaded) do
		if name:match("^conflict") then
			package.loaded[name] = nil
		end
	end
end

local function run(cmd)
	local result = vim.fn.system(cmd)
	assert(vim.v.shell_error == 0 or cmd:match("^git %-C .- merge"), "command failed: " .. cmd .. "\n" .. result)
end

-- Sets up a throwaway git repo with a real unmerged conflict (file.txt),
-- then returns its root and a nested subdirectory inside it.
local function make_conflict_repo()
	local root = vim.fn.tempname()
	vim.fn.mkdir(root, "p")
	vim.fn.mkdir(root .. "/subdir", "p")

	run(string.format("git -C %s init -q -b main", root))
	run(string.format("git -C %s config user.email test@example.com", root))
	run(string.format("git -C %s config user.name test", root))

	vim.fn.writefile({ "base" }, root .. "/file.txt")
	run(string.format("git -C %s add file.txt", root))
	run(string.format("git -C %s commit -q -m base", root))

	run(string.format("git -C %s checkout -q -b other", root))
	vim.fn.writefile({ "theirs" }, root .. "/file.txt")
	run(string.format("git -C %s commit -q -am other", root))

	run(string.format("git -C %s checkout -q main", root))
	vim.fn.writefile({ "ours" }, root .. "/file.txt")
	run(string.format("git -C %s commit -q -am ours", root))

	-- Merge conflicts on purpose: leaves file.txt with conflict markers and
	-- an unmerged index entry, which is what `git diff --diff-filter=U` needs.
	run(string.format("git -C %s merge other -q", root))

	return root, root .. "/subdir"
end

describe("conflict.list path resolution", function()
	local original_cwd
	local repo_root

	before_each(function()
		reset_modules()
		original_cwd = vim.fn.getcwd()
		repo_root = nil
	end)

	after_each(function()
		vim.fn.chdir(original_cwd)
		if repo_root then
			vim.fn.delete(repo_root, "rf")
		end
	end)

	it("resolves git-relative paths to absolute paths when cwd is not the git root", function()
		local config = require("conflict.config")
		local list = require("conflict.list")

		local subdir
		repo_root, subdir = make_conflict_repo()
		vim.fn.chdir(subdir)

		config.setup({ detect = { anywhere = false } })
		list.list_conflicts()

		local qf = vim.fn.getqflist()
		eq(1, #qf)

		local filename = vim.api.nvim_buf_get_name(qf[1].bufnr)
		eq(true, vim.startswith(filename, "/"))
		eq(1, vim.fn.filereadable(filename))
		-- `git rev-parse --show-toplevel` resolves symlinks (e.g. macOS's
		-- /tmp -> /private/tmp), so compare against the resolved path too.
		eq(vim.fn.resolve(repo_root .. "/file.txt"), filename)
	end)

	it("counts conflicts correctly once paths are resolved", function()
		local config = require("conflict.config")
		local list = require("conflict.list")

		local subdir
		repo_root, subdir = make_conflict_repo()
		vim.fn.chdir(subdir)

		config.setup({ detect = { anywhere = false } })
		list.list_conflicts()

		local qf = vim.fn.getqflist()
		eq(1, #qf)
		eq("1 conflict", qf[1].text)
	end)
end)

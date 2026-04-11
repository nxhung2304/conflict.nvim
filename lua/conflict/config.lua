local M = {}

M.defaults = {
	keymaps = {
		leader = "<leader>",
	},
	ui = {
		-- Enable/disable action bar markers (buttons on conflict markers)
		-- true: show clickable action buttons on conflict markers
		-- false: hide action buttons, use keyboard shortcuts only
		markers = false,
	},
	detect = {
		-- When true (default): detect conflicts in ANY file with <<<<<<< markers,
		-- regardless of git merge state. Works with AI-generated, manually pasted,
		-- or stash-pop conflict markers.
		-- When false: only activate during git merge/rebase/cherry-pick state.
		anywhere = true,
	},
	highlights = {
		current      = "ConflictCurrent",
		current_text = "ConflictCurrentText",
		incoming      = "ConflictIncoming",
		incoming_text = "ConflictIncomingText",
		base          = "ConflictBase",
		base_text     = "ConflictBaseText",
	},
	-- Tint colors for each conflict section (hex strings or 24-bit integers).
	colors = {
		current  = "#56CC7A",  -- green  — current / ours
		incoming = "#40A6FF",  -- blue   — incoming / theirs
		base     = "#FFCC66",  -- amber  — base / ancestor (diff3)
		both     = "#88CC44",  -- green  — "accept both" action
		none     = "#808080",  -- gray   — "accept none" action
	},
}

M.options = {}

-- Blend two 24-bit integer colors. alpha=1 → pure fg, alpha=0 → pure bg.
-- Pure-arithmetic so it works in all Lua / LuaJIT versions.
local function blend(fg, bg, alpha)
	local r1 = math.floor(fg / 65536) % 256
	local g1 = math.floor(fg /   256) % 256
	local b1 = fg % 256
	local r2 = math.floor(bg / 65536) % 256
	local g2 = math.floor(bg /   256) % 256
	local b2 = bg % 256
	return string.format("#%02x%02x%02x",
		math.floor(r1 * alpha + r2 * (1 - alpha) + 0.5),
		math.floor(g1 * alpha + g2 * (1 - alpha) + 0.5),
		math.floor(b1 * alpha + b2 * (1 - alpha) + 0.5)
	)
end

-- Convert a color value to a 24-bit integer.
-- Accepts "#RRGGBB" hex strings or integers directly.
local function to_int(c)
	if type(c) == "number" then return c end
	-- strip leading "#"
	local hex = c:match("^#?(%x%x%x%x%x%x)$")
	assert(hex, "conflict.nvim: invalid color value: " .. tostring(c))
	return tonumber(hex, 16)
end

local function set_highlights()
	-- Read the current theme's background; fall back to a neutral dark value.
	local normal_bg = vim.api.nvim_get_hl(0, { name = "Normal" }).bg or 0x1e1e2e

	-- User-overridable tint colors.
	local c       = M.options.colors
	local current  = to_int(c.current)
	local incoming = to_int(c.incoming)
	local base     = to_int(c.base)
	local both     = to_int(c.both)
	local none     = to_int(c.none)

	-- ── conflict block highlights ────────────────────────────────────────────
	vim.api.nvim_set_hl(0, "ConflictCurrent",
		{ bg = blend(current,  normal_bg, 0.25) })
	vim.api.nvim_set_hl(0, "ConflictCurrentText",
		{ fg = blend(current,  0xFFFFFF, 0.80), bold = true })

	vim.api.nvim_set_hl(0, "ConflictIncoming",
		{ bg = blend(incoming, normal_bg, 0.25) })
	vim.api.nvim_set_hl(0, "ConflictIncomingText",
		{ fg = blend(incoming, 0xFFFFFF, 0.80), bold = true })

	vim.api.nvim_set_hl(0, "ConflictBase",
		{ bg = blend(base,     normal_bg, 0.25) })
	vim.api.nvim_set_hl(0, "ConflictBaseText",
		{ fg = blend(base,     0xFFFFFF, 0.80), bold = true })

	-- ── action-bar highlights ────────────────────────────────────────────────
	vim.api.nvim_set_hl(0, "ConflictActionCurrent",
		{ bg = blend(current,  normal_bg, 0.28), fg = blend(current,  0xFFFFFF, 0.85), italic = true })
	vim.api.nvim_set_hl(0, "ConflictActionIncoming",
		{ bg = blend(incoming, normal_bg, 0.28), fg = blend(incoming, 0xFFFFFF, 0.85), italic = true })
	vim.api.nvim_set_hl(0, "ConflictActionBoth",
		{ bg = blend(both,     normal_bg, 0.15), fg = blend(both,     0xFFFFFF, 0.85), italic = true })
	vim.api.nvim_set_hl(0, "ConflictActionNone",
		{ bg = blend(none,     normal_bg, 0.12), fg = blend(none,     0xFFFFFF, 0.60), italic = true })
	vim.api.nvim_set_hl(0, "ConflictActionSep",
		{ bg = blend(none,     normal_bg, 0.10), fg = blend(none,     normal_bg, 0.40) })

	-- ── 2-way / 3-way diff pane overrides ───────────────────────────────────
	local function diff_panes(color, prefix)
		vim.api.nvim_set_hl(0, prefix .. "Normal",
			{ bg = blend(color, normal_bg, 0.10) })
		vim.api.nvim_set_hl(0, prefix .. "Add",
			{ bg = blend(color, normal_bg, 0.22) })
		vim.api.nvim_set_hl(0, prefix .. "Change",
			{ bg = blend(color, normal_bg, 0.18) })
		vim.api.nvim_set_hl(0, prefix .. "Text",
			{ bg = blend(color, normal_bg, 0.38), bold = true })
		vim.api.nvim_set_hl(0, prefix .. "Delete",
			{ bg = blend(color, normal_bg, 0.06), fg = blend(color, normal_bg, 0.30) })
	end

	diff_panes(current,  "ConflictDiffCurrent")
	diff_panes(incoming, "ConflictDiffIncoming")
	diff_panes(base,     "ConflictDiffBase")
end

M.setup = function(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
	set_highlights()
	-- Re-derive colors whenever the user switches colorscheme.
	vim.api.nvim_create_autocmd("ColorScheme", {
		group    = vim.api.nvim_create_augroup("ConflictHighlights", { clear = true }),
		callback = set_highlights,
	})
end

return M

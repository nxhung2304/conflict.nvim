local M = {}

M.defaults = {
	keymaps = {
		leader = "<leader>",
	},
	highlights = {
		current        = "ConflictCurrent",
		current_label  = "ConflictCurrentLabel",
		incoming       = "ConflictIncoming",
		incoming_label = "ConflictIncomingLabel",
		base           = "ConflictBase",
		base_label     = "ConflictBaseLabel",
	},
	ai = {
		enabled  = true,
		provider = "avante",
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

local function set_highlights()
	-- Read the current theme's background; fall back to a neutral dark value.
	local normal_bg = vim.api.nvim_get_hl(0, { name = "Normal" }).bg or 0x1e1e2e

	-- Base tint colors (VSCode-inspired palette).
	local teal  = 0x40C8AE  -- current / ours
	local blue  = 0x40A6FF  -- incoming / theirs
	local amber = 0xFFCC66  -- base / ancestor
	local green = 0x88CC44  -- "accept both"
	local gray  = 0x808080  -- "accept none"

	-- ── conflict block highlights ────────────────────────────────────────────
	vim.api.nvim_set_hl(0, "ConflictCurrentLabel",
		{ bg = blend(teal,  normal_bg, 0.30), fg = blend(teal,  0xFFFFFF, 0.85), bold  = true })
	vim.api.nvim_set_hl(0, "ConflictCurrent",
		{ bg = blend(teal,  normal_bg, 0.15) })

	vim.api.nvim_set_hl(0, "ConflictIncomingLabel",
		{ bg = blend(blue,  normal_bg, 0.30), fg = blend(blue,  0xFFFFFF, 0.85), bold  = true })
	vim.api.nvim_set_hl(0, "ConflictIncoming",
		{ bg = blend(blue,  normal_bg, 0.15) })

	vim.api.nvim_set_hl(0, "ConflictBaseLabel",
		{ bg = blend(amber, normal_bg, 0.30), fg = blend(amber, 0xFFFFFF, 0.85), bold  = true })
	vim.api.nvim_set_hl(0, "ConflictBase",
		{ bg = blend(amber, normal_bg, 0.15) })

	-- ── action-bar highlights ────────────────────────────────────────────────
	vim.api.nvim_set_hl(0, "ConflictActionCurrent",
		{ bg = blend(teal,  normal_bg, 0.15), fg = blend(teal,  0xFFFFFF, 0.85), italic = true })
	vim.api.nvim_set_hl(0, "ConflictActionIncoming",
		{ bg = blend(blue,  normal_bg, 0.15), fg = blend(blue,  0xFFFFFF, 0.85), italic = true })
	vim.api.nvim_set_hl(0, "ConflictActionBoth",
		{ bg = blend(green, normal_bg, 0.15), fg = blend(green, 0xFFFFFF, 0.85), italic = true })
	vim.api.nvim_set_hl(0, "ConflictActionNone",
		{ bg = blend(gray,  normal_bg, 0.12), fg = blend(gray,  0xFFFFFF, 0.60), italic = true })
	vim.api.nvim_set_hl(0, "ConflictActionSep",
		{ bg = blend(gray,  normal_bg, 0.10), fg = blend(gray,  normal_bg, 0.40) })

	-- ── 2-way / 3-way diff pane overrides ───────────────────────────────────
	-- Each pane gets its own Normal + DiffAdd/Change/Text/Delete tinted with
	-- its section color, so the whole window "belongs" to that side.
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

	diff_panes(teal,  "ConflictDiffCurrent")
	diff_panes(blue,  "ConflictDiffIncoming")
	diff_panes(amber, "ConflictDiffBase")
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

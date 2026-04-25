local M = {}

M.defaults = {
	signs = {
		add = { text = "│", hl = "ChezmoiSignAdd" },
		change = { text = "│", hl = "ChezmoiSignChange" },
		delete = { text = "▁", hl = "ChezmoiSignDelete" },
	},

	highlights = {
		ChezmoiSignAdd = { fg = "#2da043", bg = "none" },
		ChezmoiSignChange = { fg = "#d9a404", bg = "none" },
		ChezmoiSignDelete = { fg = "#d72e3d", bg = "none" },
	},

	auto_refresh = true,
	debounce_ms = 300,
	chezmoi_bin = "chezmoi",
	debug = false,
}

M.user_config = {}

function M.setup(opts)
	M.user_config = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

function M.get(key)
	local keys = vim.split(key, ".", { plain = true })
	local val = M.user_config
	for _, k in ipairs(keys) do
		if val == nil then
			return nil
		end
		val = val[k]
	end
	return val
end

return M

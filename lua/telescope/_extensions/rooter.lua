local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
	vim.notify("This extension requires telescope.nvim", vim.log.levels.ERROR, { title = "Plugin error" })
	return
end

local toggle = function(_)
	vim.g["Telescope#rooter#enabled"] = not vim.g["Telescope#rooter#enabled"]
	local state = vim.g["Telescope#rooter#enabled"] and "enabled" or "disabled"
	vim.notify("Telescope#rooter " .. state)
end

local setup = function(ext_config, _)
	local config = vim.F.if_nil(ext_config, { patterns = { ".git" } })

	-- default enabled
	vim.g["Telescope#rooter#enabled"] = vim.F.if_nil(config.enable, true)

	local group = vim.api.nvim_create_augroup("TelescopeRooter", { clear = true })

	vim.api.nvim_create_autocmd({ "DirChangedPre" }, {
		callback = function()
			if vim.g["Telescope#rooter#enabled"] ~= true then
				return
			end

			if vim.g["Telescope#rooter#oldpwd"] == nil then
				vim.g["Telescope#rooter#oldpwd"] = vim.uv.cwd()
			end
		end,
		group = group,
	})

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
		callback = function()
			if vim.g["Telescope#rooter#enabled"] ~= true then
				return
			end

			vim.schedule(function()
				if vim.bo.filetype == "TelescopePrompt" then
					local rootdir = vim.fs.dirname(vim.fs.find(config.patterns, { upward = true })[1])
					if rootdir ~= nil then
						vim.api.nvim_set_current_dir(rootdir)
					end
				end
			end)
		end,
		group = group,
	})

	vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
		callback = function()
			if vim.g["Telescope#rooter#enabled"] ~= true then
				return
			end

			vim.schedule(function()
				if vim.bo.filetype ~= "TelescopePrompt" then
					if vim.g["Telescope#rooter#oldpwd"] ~= nil then
						vim.api.nvim_set_current_dir(vim.g["Telescope#rooter#oldpwd"])
						vim.g["Telescope#rooter#oldpwd"] = nil
					end
				end
			end)
		end,
		group = group,
	})
end

return telescope.register_extension({ setup = setup, exports = { toggle = toggle } })

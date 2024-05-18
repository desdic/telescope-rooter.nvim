local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
	error("This extension requires telescope.nvim")
	return
end

local has_plenary, plenary = pcall(require, "plenary")
if not has_plenary then
	error("This extension requires plenary")
	return
end

local log = plenary.log.new({ plugin = "telescope_rooter", level = "info" })

local toggle = function(_)
	vim.g["Telescope#rooter#enabled"] = not vim.g["Telescope#rooter#enabled"]
	print("Telescope#rooter#enabled=" .. vim.inspect(vim.g["Telescope#rooter#enabled"]))
end

local setup = function(ext_config, _)
	local config = vim.F.if_nil(ext_config, { patterns = { ".git" } })

	-- default enabled
	vim.g["Telescope#rooter#enabled"] = vim.F.if_nil(config.enable, true)

	-- redefine log if debug enabled
	if vim.F.if_nil(config.debug, false) then
		log = plenary.log.new({ plugin = "telescope_rooter", level = "debug" })
	end

	local group = vim.api.nvim_create_augroup("TelescopeRooter", { clear = true })

	vim.api.nvim_create_autocmd({ "DirChangedPre" }, {
		callback = function()
			if vim.g["Telescope#rooter#enabled"] ~= true then
				return
			end

			if vim.g["Telescope#rooter#oldpwd"] == nil then
				vim.g["Telescope#rooter#oldpwd"] = vim.uv.cwd()
				log.debug("before " .. vim.inspect(vim.uv.cwd()))
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
						log.debug("changing dir to " .. rootdir)
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
						log.debug("restoring " .. vim.g["Telescope#rooter#oldpwd"])
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

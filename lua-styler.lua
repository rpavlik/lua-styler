#!/usr/bin/env lua

pcall(require,"luarocks.loader")
require "styler"

local makeBackup = true

local donothing = function() end
local vverbose_func = donothing
local verbose_func = donothing

local script_verbose = print

--[[ Options and Help ]]

local script_info = [[
Lua Styler - reformats Lua code.

Usage: styler [options] filename(s)...

]]

local options = {
	["--nobackup"] = {
		help = "Do not create .bak files when re-styling a file.",
		action = function() makeBackup = false end
	},
	["-v"] = {
		help = "Enable verbose output from the styler procedure.",
		action = function() verbose_func = print end
	},
	["-vv"] = {
		help = "Enable very verbose output from the styler procedure (implies -v).",
		action = function() verbose_func = print; vverbose_func = print end
	},
	["-q"] = {
		help = "Silence all non-error output from the styler procedure and the main script.",
		action = function() vverbose_func = donothing; verbose_func = donothing; script_verbose = donothing end
	}
}

local showHelp = function()
	print(script_info)
	for flag, val in pairs(options) do
		print("", flag, val.help)
		print("")
	end
	os.exit(1)
end

options["-h"] = {
	help = "Show this help information",
	action = showHelp
}
options["--help"] = options["-h"]

--[[ Process arguments ]]
local inputFiles = {}
for _, v in ipairs(arg or {}) do
	if options[v] ~= nil then
		options[v].action()
	else
		table.insert(inputFiles, v)
	end
end

if #inputFiles < 1 then
	io.stderr:write("Must provide at least one file name!\n\n")
	showHelp()
	os.exit(1)
end

local function handleFile(fn)
	local f = assert(io.open(fn, 'rb'))
	local orig = f:read("*all")
	f:close()

	local styledCode = styler.processCode(orig, verbose_func, vverbose_func)

	if styledCode == orig then
		script_verbose(fn, "Already cleanly styled!")
	else
		if makeBackup then
			local fbak = assert(io.open(fn .. ".bak", "wb"))
			fbak:write(orig)
			fbak:close()
		end
		local f = assert(io.open(fn, 'wb'))
		f:write(styledCode)
		f:close()
		script_verbose(fn, "Style cleanup changes applied.")
	end
end

for _, fn in ipairs(inputFiles) do
	handleFile(fn)
end

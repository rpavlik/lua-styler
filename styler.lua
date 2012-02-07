#!/usr/bin/env lua

require "styler"

local makeBackup = true

local options = {
	["--nobackup"] = function() makeBackup = false end,
}

local inputFiles = {}
for _, v in ipairs(arg) do
	if options[v] ~= nil then
		options[v]()
	else
		table.insert(inputFiles, v)
	end
end


if #inputFiles < 1 then
	print "Must provide at least one file name."
	os.exit(1)
end

local function handleFile(fn)
	local f = assert(io.open(fn, 'r'))
	local orig = f:read("*all")
	f:close()

	local styledCode = styler.processCode(orig)

	if styledCode == orig then
		print(fn, "Already cleanly styled!")
	else
		if makeBackup then
			local fbak = assert(io.open(fn .. ".bak", "w"))
			fbak:write(orig)
			fbak:close()
		end
		local f = assert(io.open(fn..".styled", 'w'))
		f:write(styledCode)
		f:close()
		print(fn, "Style cleanup changes applied.")
	end
end

for _, fn in ipairs(inputFiles) do
	handleFile(fn)
end

#!/usr/bin/env lua

--require "luarocks.loader"
require "lxsh.init"
require "lxsh.lexers.lua"


local indent = function(level)
	return ("\t"):rep(level)
end

local hasNewline = function(whitespace)
	return whitespace:find("\n", 1, true) ~= nil
end

local Set = function(args)
	for _, v in ipairs(args) do
		args[v] = true
	end
	return args
end

local blockOpen = Set{
	"{",
	"then",
	"else",
	"elseif",
	"do",
	"function",
	"repeat",
	"while",
	"("	
}

local blockClose = Set{
	"}",
	"else",
	"elseif",
	"end",
	"until",
	")",
}

local function processCode(text)
	local level = 0
	local startingNewline = true
	local ret = {}
	local function output(text)
		if blockClose[text] then
			level = level - 1
			print("Closing a block", text, level)
		end
		if not startingNewline then
			table.insert(ret, text)
		else
			table.insert(ret, indent(level))
			table.insert(ret, text)
			startingNewline = false
		end
		if blockOpen[text] then
			level = level + 1
			print("Opening a block", text, level)
		end
	end
	
	local kinds = {
		whitespace = function(text, lnum, cnum)
			if hasNewline(text) then
				table.insert(ret, "\n")
				startingNewline = true
			elseif not startingNewline then
				output " "
			end
		end,
	}
	
	for kind, text, lnum, cnum in lxsh.lexers.lua.gmatch(text) do
		if kinds[kind] then
			kinds[kind](text, lnum, cnum)
		else
			output(text)
		end
	end
	return table.concat(ret)
end

-- Main is down here.

if #arg ~= 1 then
	print "Must provide a file name."
	os.exit(1)
end

local f = assert(io.open(arg[1], 'r'))
local orig = f:read("*all")
f:close()
print(processCode(orig))

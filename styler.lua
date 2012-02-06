#!/usr/bin/env lua

--require "luarocks.loader"
require "lxsh.init"
require "lxsh.lexers.lua"

if #arg ~= 1 then
	print "Must provide a file name."
	os.exit(1)
end

local f = assert(io.open(arg[1], 'r'))
local orig = f:read("*all")
f:close()

local indent = function(level)
	return ("\t"):rep(level)
end

local hasNewline = function(whitespace)
	return whitespace:find("\n", 1, true) ~= nil
end

local kindHandler = {
	level = 0,
	needsNewline = false,
}

local Set = function(args)
	for _, v in ipairs(args) do
		args[v] = true
	end
	return args
end

local blockOpen = Set{
	"{",
	"do",
	"function",
	"repeat",
	"while",
	"("	
}

local blockClose = Set{
	"}",
	"end",
	"until",
	")",
}

local function processCode(text)
	local level = 0
	local needsNewline = false
	local ret = {}
	local function output(text)
		if not needsNewline then
			table.insert(ret, text)
		else 
			if blockClose[text] then
				level = level - 1
			end
			table.insert(ret, "\n")
			table.insert(ret, indent(level))
			table.insert(ret, text)
			needsNewline = false
			if blockOpen[text] then
				level = level + 1
			end
		end
	end
	
	local kinds = {
		whitespace = function(text, lnum, cnum)
			if hasNewline(text) then
				if needsNewline then
					table.insert(ret, "\n")
					-- still needs newline
				else
					needsNewline = true
				end
			else
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
--[[
	
	
kindHandler.processString = function(self, text)
	if not self.needsNewline then
		return text
	else
		if blockClose[text] then
			self.level = self.level - 1
		end
		local ret = indent(self.level) .. text
		self.needsNewline = false
		if blockOpen[text] then
			self.level = self.level + 1
		end
		return ret
	end
end

local defaultHandler = function(self, text, lnum, cnum)
	return self.processString(text)
end

kindHandler.__index = function(self, index)
	return defaultHandler
end

setmetatable(kindHandler, kindHandler)

kindHandler.whitespace = function(self, text, lnum, cnum)
	if hasNewline(text) then
		if self.needsNewline then
			return "\n"
		end
		self.needsNewline = true
		return ""
	end
	return " "
end


local ret = {}
for kind, text, lnum, cnum in lxsh.lexers.lua.gmatch(orig) do
	--print(string.format('%s: %q (%i:%i)', kind, text, lnum, cnum))
	table.insert(ret, kindHandler[kind](kindhandler, text, lnum, cnum))
end
print(table.concat(ret))
]]

print(processCode(orig))

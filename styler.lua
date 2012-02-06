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

for kind, text, lnum, cnum in lxsh.lexers.lua.gmatch(orig) do
	print(string.format('%s: %q (%i:%i)', kind, text, lnum, cnum))
end

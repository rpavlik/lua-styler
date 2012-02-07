
pcall(require,"luarocks.loader")
require "lxsh"


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


local _M = {}

function _M.processCode(text, verbose_print, vverbose_print)
	local level = 0
	local startingNewline = true
	local ret = {}

	local verbose = verbose_print or function(...)
		print(...)
	end
	local vverbose = vverbose_print or function(...)
		verbose(...)
	end

	local function buffer(text)
		vverbose(("Buffering %q"):format(text))
		table.insert(ret, text)
	end
	local function output(text)
		if blockClose[text] then
			level = level - 1
			verbose("Closing a block", text, level)
		end
		if not startingNewline then
			buffer(text)
		else
			buffer(indent(level))
			buffer(text)
		end
		if blockOpen[text] then
			level = level + 1
			verbose("Opening a block", text, level)
		end

		startingNewline = hasNewline(text) -- this catches comments which end with a newline, etc.
	end

	local kinds = {
		whitespace = function(text, lnum, cnum)
			if hasNewline(text) then
				-- Extract and buffer all and only the newlines
				buffer(text:gsub("[^\n]*(\n)[^\n]*","%1"))
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
			vverbose("No special treatment for", kind)
			output(text)
		end
	end
	return table.concat(ret)
end


-- Register "styler" in the global scope if it doesn't clash with an existing
-- global variable and bypass strict.lua because "we know what we're doing"
-- (in other words, "lua -lstyler" is very convenient).
if not rawget(_G, 'styler') then
  rawset(_G, 'styler', _M)
end

return _M

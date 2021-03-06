pcall(require, "luarocks.loader")

-- This weird construct handles a bug in luarocks and/or lxsh's rockspec.
local success = pcall(require, "lxsh")
if not success then
	require "lxsh.init"
end


local indent = function(level)
	return ("\t"):rep(level)
end

local hasNewline = function(whitespace)
	return whitespace:find("\n", 1, true) ~= nil
end

-- Utility function to process a string token by token, building up a new
-- string using a table as a buffer.
local function filterTokens(input, filter, setup)
	local ret = {}

	local function nilToEmptyString(s)
		if s == nil then
			return ""
		else
			return s
		end
	end
	local common = {
		buffer = function(s)
			table.insert(ret, s)
		end,
		popBuffer = function()
			return nilToEmptyString(table.remove(ret))
		end,

		getBufferSize = function()
			return #ret
		end,

		peekBuffer = function()
			return nilToEmptyString(ret[#ret])
		end
	}

	if setup then
		setup(common)
	end
	local mt = {__index = common}
	for kind, text, lnum, cnum in lxsh.lexers.lua.gmatch(input) do
		filter(setmetatable({kind = kind, text = text, lnum = lnum, cnum = cnum}, mt))
	end
	return table.concat(ret)
end

local Set = function(args)
	for _, v in ipairs(args) do
		args[v] = true
	end
	return args
end

local _M = {}

do -- block indenter/whitespace minimizer
	local blockOpen = Set{
		"{",
		"then",
		"else",
		"do",
		"function",
		"repeat",
		"(",
		"[",
	}

	local blockClose = Set{
		"}",
		"else",
		"elseif",
		"end",
		"until",
		")",
		"]",
	}

	function _M.reindentBlocks(text, verbose, vverbose)
		local level = 0

		local buffer
		local peekBuffer
		local getBufferSize

		local function setup(common)
			buffer = common.buffer
			peekBuffer = common.peekBuffer
			getBufferSize = common.getBufferSize
		end

		local function lastBufferedCharIsNewline()
			return peekBuffer():sub(-1) == "\n" or getBufferSize() == 0
		end

		local function output(text)
			if blockClose[text] then
				level = level - 1
				verbose("Closing a block", text, level)
			end
			if lastBufferedCharIsNewline() then
				buffer(indent(level))
			end

			buffer(text)
			if blockOpen[text] then
				level = level + 1
				verbose("Opening a block", text, level)
			end
		end

		local function blockIndenter(self)
			if self.kind == "whitespace" then
				if hasNewline(self.text) then
					-- Extract and buffer all and only the newlines
					buffer(self.text:gsub("[^\n]*(\n)[^\n]*", "%1"))
				elseif not lastBufferedCharIsNewline() then
					output " "
				end
			else
				vverbose("No special treatment for", self.kind)
				output(self.text)
			end
		end

		return filterTokens(text, blockIndenter, setup)
	end

end

do -- addPadding
	local padBoth = Set{
		"=",
		"==",
		"~=",
		"<",
		">",
		"<=",
		">=",
		"+",
		--"-", -- unary minus looks weird padded on both sides
		"*",
		"/",
		"^",
		"%",
		"..",
		--[["and",
		"or", -- buggy in current lxsh
		]]
	}

	local padBefore = Set{
		--"end"
	}

	local padAfter = Set{
		",",
		";",
		--[[
		"if",
		"then",
		"else",
		"elseif",
		"not" -- buggy in current lxsh
		]]
	}

	function _M.addPadding(text, verbose, vverbose)

		local function paddingFilter(self)
			local text = self.text
			if self.kind == "keyword" or self.kind == "operator" then
				local token = text
				if padBoth[token] then
					vverbose("Padding both:", token)
					text = " " .. text .. " "
				elseif padBefore[token] then
					vverbose("Padding before:", token)
					text = " " .. text
				elseif padAfter[token] then
					vverbose("Padding after:", token)
					text = text .. " "
				end
			end
			self.buffer(text)
		end

		return filterTokens(text, paddingFilter)
	end
end

do -- eatPrecedingWhitespace
	local eatsPrecedingWS = Set{
		",",
		";",
	}

	function _M.eatPrecedingWhitespace(text, verbose, vverbose)
		local function eatPrecedingFilter(self)
			if eatsPrecedingWS[self.text] then
				local preceding = self.peekBuffer()
				-- look at preceding token
				if lxsh.lexers.lua.patterns.whitespace:match(preceding) and preceding ~= "\n" then
					-- if it's whitespace and not a newline, pop it.
					self.popBuffer()
				end
			end
			-- In any case, buffer this token.
			self.buffer(self.text)
		end
		return filterTokens(text, eatPrecedingFilter)
	end
end

function _M.removeDosEndlines(text, verbose, vverbose)
	local function handleToken(self)
		if self.type == "whitespace" or self.type == "comment" then
			self.buffer(self.text:gsub("\r(\n)?", "\n"))
		else
			self.buffer(self.text)
		end
	end
	return filterTokens(text, handleToken)
end

function _M.processCode(text, verbose_print, vverbose_print)
	local verbose = verbose_print or print
	local vverbose = vverbose_print or verbose

	local config = {
		"removeDosEndlines",
		"addPadding",
		"reindentBlocks",
		"eatPrecedingWhitespace",
		"reindentBlocks",
	}

	local ret = text
	for _, filter in ipairs(config) do
		verbose("Applying filter:", filter)
		ret = _M[filter](ret, verbose, vverbose)
	end
	return ret
end


-- Register "styler" in the global scope if it doesn't clash with an existing
-- global variable and bypass strict.lua because "we know what we're doing"
-- (in other words, "lua -lstyler" is very convenient).
if not rawget(_G, 'styler') then
	rawset(_G, 'styler', _M)
end

return _M

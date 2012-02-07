#!/bin/bash
(
	cd $(dirname $0)
	cp lua-styler.lua win32
	cp styler.lua win32/lua
)

#!/bin/bash
(
	cd $(dirname $0)
	./lua-styler.lua lua-styler.lua styler.lua
)

@echo off
SETLOCAL

set SCRIPTDIR=%~dp0
set LUA_PATH=%SCRIPTDIR%lua/?.lua;%SCRIPTDIR%lua/?/init.lua;;
set LUA_CPATH=%SCRIPTDIR%lib/?.dll;;
"%SCRIPTDIR%lua-styler.lua" %*
pause
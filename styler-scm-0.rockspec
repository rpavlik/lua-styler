package = "styler"
version = "scm-0"
source = {
   url = "git://github.com/rpavlik/lua-styler.git"
}
description = {
   summary = "Lua code re-formatter.",
   detailed = [[ TODO ]],
   homepage = "https://github.com/rpavlik/lua-styler",
   license = "MIT/X11"
}
dependencies = {
   "lua >= 5.1",
   "lxsh"
}

build = {
  type = "builtin",
  modules = {
    ["styler"] = "styler.lua"
  },
  install = {
    bin = {
      "lua-styler.lua"
    }
  }
}

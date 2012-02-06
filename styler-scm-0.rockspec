package = "styler"
version = "scm-0"
source = {
   --url = "git://github.com/rpavlik/lua-feedfilter.git"
   url = "."
}
description = {
   summary = "Lua code re-formatter.",
   detailed = [[ TODO ]],
--   homepage = "https://github.com/rpavlik/lua-feedfilter",
--   license = "MIT/X11" -- or whatever you like
}
dependencies = {
   "lua >= 5.1",
   "lxsh"
}

build = {
  type = "builtin",
  modules = {
  --[[
    ["feedfilter.configdsl"] = "feedfilter/configdsl.lua",
    ["feedfilter.feed"] = "feedfilter/feed.lua",
    ["feedfilter.filter"] = "feedfilter/filter.lua",
    ["feedfilter.generate"] = "feedfilter/generate.lua",
    ["feedfilter.https"] = "feedfilter/https.lua",
    ["feedfilter.verbose"] = "feedfilter/verbose.lua", ]]
  },
  install = {
    bin = {
      "styler.lua"
    }
  },
  copy_directories = { --[["samples", "doc", "tests" ]]},
}

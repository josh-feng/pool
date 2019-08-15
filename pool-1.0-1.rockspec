package = "pool"
version = "1.0-1"
source = {
   url = "git+https://github.com/josh-feng/pool"
}
description = {
   summary = "Poorman's object-oriented lua (POOL) and Reduced Markup Language (RML) support.",
   detailed = [[
      POOL supports light OO programming.
      RML works like a punctuation system for data serializtion.
   ]],
   homepage = "http://github.com/josh-feng/pool",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1, < 5.4"
}
external_depencies = {
   LIBLRP = {
      header = "lrp.h"
   }
}
build = {
   type = "builtin",
   modules = {
      -- class (POOL)
      pool = "src/pool.lua",

      -- Reduced Markup Language (RML) parser (lua or C)
      lrm = "src/lrm.lua",  

      lsrml = "src/lsrml.lua",  

      -- c module written in C/++
      lrp = {
         sources = {"src/lrp.c",},
         defines = {},
         libraries = {"lrp"},
         incdirs = {},
         libdirs = {}
      }
   },
   copy_directories = {"doc"}
}

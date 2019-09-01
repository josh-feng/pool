// RML parser
// MIT license
#ifndef _lip_hpp
#define _lip_hpp
#include <lua.hpp>
#include <lualib.h>
#include <lauxlib.h>

// LUA_API properly handle C or C++ function name in compiled object code
LUA_API int luaopen_lrp (lua_State *);

#endif
// vim: ts=2 sw=2 sts=2 et foldenable fdm=marker fmr={{{,}}} fdl=1

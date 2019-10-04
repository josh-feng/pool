// RML parser
// MIT license
//
// local lrmcallbacks = {
//     Spec = function (parser, spec) -- {{{ end; -- }}}
//     StartTag = function (parser, name, attr) -- {{{ end; -- }}}
//     EndTag = function (parser, name) -- {{{ end; -- }}}
//     Data = function (parser, str) -- {{{ end; -- }}}
//     Paste = function (parser, str, hint, seal) -- {{{ end; -- }}}
//     String = function (parser, str) -- {{{ end; -- }}}
// }
//
// local plrm = lrp(lrmcallbacks)
// local status, msg, line = plrm:parse(txt) -- status, msg, line, col, pos
// plrm:close() -- seems destroy the lrp obj
// node['?'] = status and {} or {msg..' @line '..line}

#include "lrp.hpp"

static int lrpclass (lua_State *L) {
  return 1;
}

static int lrpparse (lua_State *L) {
  return 1;
}

static int lrpclose (lua_State *L) {
  return 1;
}

static void setfield (lua_State *L, int itype, const char *index, int vtype, void *value) {
  lua_pushstring(L, (const char *) index);
  lua_pushstring(L, (const char *) value);
  lua_settable(L, -3);
}

static const struct luaL_Reg lrp_m [] = {
  {"__call", lrpclass}, // return table has parse and close method
  {NULL, NULL}
};

int luaopen_lrp (lua_State *L) {
  lua_newtable(L);
  setfield(L, LUA_TSTRING, "_VERSION",     LUA_TSTRING, (void *) "LuaRmlParser 1.0.0");
  setfield(L, LUA_TSTRING, "_DESCRIPTION", LUA_TSTRING, (void *) "An RML parser");
  setfield(L, LUA_TSTRING, "_COPYRIGHT",   LUA_TSTRING, (void *) "Copyright (C) 2019 Pool Project");
  luaL_setfuncs(L, lrp_m, 0); // put into metatable method TODO
  // object parse/close
  return 1;
}
// vim: ts=2 sw=2 sts=2 et foldenable fdm=marker fmr={{{,}}} fdl=1

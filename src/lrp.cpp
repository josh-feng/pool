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
#include <math.h>

static int lrpclass (lua_State *L) {
  return 1;
}

static int lrpparse (lua_State *L) {
  return 1;
}

static int lrpclose (lua_State *L) {
  return 1;
}

static const struct luaL_Reg lrp [] = {
  {"new", lrpclass},
  {"parse", lrpparse},
  {"close", lrpclose},
  {NULL, NULL} /* sentinel */
};

int luaopen_lrp (lua_State *L) {
  luaL_newlib(L, lrp);
  return 1;
}
// vim: ts=2 sw=2 sts=2 et foldenable fdm=marker fmr={{{,}}} fdl=1

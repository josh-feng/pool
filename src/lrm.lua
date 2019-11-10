#!/usr/bin/env lua
-- ======================================================================== --
-- Lua RML-object Model
-- Usage example:
--      lrm = require('lrm')
--      doc = lrm.ParseRml(file)
--      rml = lrm.Dump(docs)
-- ======================================================================== --
local lrm = {id = ''} -- version control

local lrp = require('lrps') -- the standard Lua Expat module (or lrp.so)

local next, assert, type = next, assert, type
local strlen, strsub, strmatch, strgmatch = string.len, string.sub, string.match, string.gmatch
local strrep, strgsub, strfind = string.rep, string.gsub, string.find
local tinsert, tremove, tconcat = table.insert, table.remove, table.concat

local indent = strrep(' ', 4)
-- ======================================================================== --
local normpath = function (path, pwd) -- {{{ full, base, name
    path = string.match(pwd and strsub(path, 1, 1) ~= '/' and pwd..'/'..path or path, '^%s*(%S.*)%s*$')
    local o = {}
    for _ in string.gmatch(strgsub(path, '/+/', '/'), '[^/]*') do
      if _ == '..' and #o > 0 and o[#o] ~= '..' then
        if o[#o] ~= '' then tremove(o) end
      elseif _ ~= '.' then
        tinsert(o, _)
      end
    end
    o = string.match(tconcat(o, '/'), '^%s*(%S.*)%s*$')
    return o, strmatch(o, '(.-/?)([^/]+)$') -- full, base, name
end -- }}}
local strToTbl = function (tmpl, sep, set) -- {{{ -- build the tmpl from string
    local res, order = {}
    if tmpl then
        set = set or '='
        for token in strgmatch(tmpl, '([^'..(sep or ',')..']+)') do
            local k, v = strmatch(token, '([^'..set..']+)'..set..'(.*)')
            if k and v and k ~= '' then
                local q, qo = strmatch(v, '^([\'"])(.*)%1$') -- trim qotation mark
                res[k] = qo or v
                tinsert(res, token)
            elseif strfind(token, '%S') then
                tinsert(res, token)
                order = token
            end
        end
    end
    return res, tonumber(order)
end -- }}}
local match = function (targ, tmpl, fExact) -- {{{ -- match assignment in tmpl
    if type(targ) ~= 'table' then return not next(tmpl) end
    if tmpl then
        for k, v in pairs(tmpl) do if targ[k] ~= v then return false end end
    end
    if fExact then
        for k in pairs(targ) do if tmpl[k] == nil then return false end end
    end
    return true
end -- }}}
local rPath = function (doc, path) -- {{{ return doc/rml-node table, missingTag
    if (not path) or path == '' or #doc == 0 then return doc, path end
    -- NB: xpointer does not have standard treatment -- A/B, /A/B[@attr="val",@bb='4']
    local tag, attr, idx
    tag, path = strmatch(path, '([^/]+)(.*)$')
    tag, attr = strmatch(tag, '([^%[]+)%[?([^%]]*)')
    attr, idx = strToTbl(attr) -- idx: []/all, [-]/last, [0]/merged, [+]/first
    local xn = {} -- rml-node (doc)
    repeat -- collect along the metatable (if mode is defined)
        for i = 1, #doc do -- no metatable -- {{{
            local mt = doc[i]
            if type(mt) == 'table' and mt['.'] == tag and match(mt['@'], attr) then
                if idx and idx < 0 then xn[1] = nil end -- clean up
                if path ~= '' or idx == 0 then
                    repeat -- collect along the metatable (NB: ipairs will dupe metatable)
                        for j = 1, #mt do if type(mt[j]) == 'table' or path == '' then tinsert(xn, mt[j]) end end
                        mt = getmetatable(mt)
                        if mt then mt = mt.__index end
                    until not mt
                else
                    tinsert(xn, mt)
                end
                if idx and idx > 0 then break end
            end
        end -- }}}
        if idx and idx > 0 and #xn > 0 then break end
        doc = getmetatable(doc)
        if doc then doc = doc.index end
    until not doc
    if path == '' and idx == 0 then xn['.'] = tag; xn = {xn} end
    return rPath(xn, path)
end -- }}}
-- ======================================================================== --
-- LOM (Lua Object Model)
-- ======================================================================== --
lrm.Parse = function (txt, fmt) -- {{{ fmt: 0/rml, 1/lua
    local node = {} -- working variable: doc == root node (node == token == tag == table)

    local lrmcallbacks = {
        Spec = function (parser, spec) -- {{{
        end; -- }}}
        StartTag = function (parser, name, attr) -- {{{
            local xn = {['.'] = node} -- record parent node
            if #attr > 0 then xn['@'] = attr end
            -- TODO
            tinsert(node, xn)
            node = xn
        end; -- }}}
        EndTag = function (parser, name) -- {{{
            -- TODO
            -- if fmt then -- record the tag/node name
            --   node, node['.'] = node['.'], name
            --   if name == '' then
            --     node['.'] = nil
            --   end
            -- else
              node, node['.'] = node['.'], name
            --end
        end; -- }}}
        Data = function (parser, str) -- {{{
            -- TODO
            node['*'] = str
        end; -- }}}
        Paste = function (parser, str, hint, seal) -- {{{
            return str
        end; -- }}}
        String = function (parser, str) -- {{{
            return str
        end; -- }}}
    }

    local plrm = lrp(lrmcallbacks)
    local status, msg, line = plrm:parse(txt) -- status, msg, line, col, pos
    plrm:close() -- seems destroy the lrp obj
    node['?'] = status and {} or {msg..' @line '..line}
    return node
end
-- }}}
-- ======================================================================== --
lrm.ParseRml = function (filename, doctree, mode) -- doc = lrm.ParseRml(rmlfile, docfactory) -- {{{
    filename = normpath(filename)
    if type(doctree) == 'table' and doctree[filename] then return doctree[filename] end

    local file, msg = io.open(filename, 'r')
    if not file then return {['?'] = {msg}} end
    local doc = lrm.Parse(file:read('*all'), mode)
    file:close()

    if type(doctree) == 'table' then doctree[filename] = doc end
    return doc
end -- }}}
lrm.RmlBuild = function (rmlfile, mode) -- toprml, doctree = lrm.RmlBuild(rootfile) -- {{{ -- trace and meta
    local toprml, base = normpath(rmlfile)
    local doctree = {}
    local doc = lrm.ParseRml(toprml, doctree, mode) -- doc table

    local function TraceTbl (xn, rml) -- {{{ lua table form
        local v = xn['@'] and xn['@']['url']
        if v then -- attr

            local link, rpath = strmatch(v, '^([^#]*)(.*)') -- {{{ file_link, tag_path
            if link == '' then -- back to this doc root
                link = rml
            else -- new file
                if strsub(link, 1, 1) ~= '/' then link = strgsub(rml, '[^/]*$', '')..link end
                link = normpath(link)
            end -- }}}

            if not doctree[link] then TraceTbl(lrm.ParseRml(link, doctree, mode), link) end
            link, rpath = rPath(doctree[link], strmatch(rpath or '', '#ptr%((.*)%)'))

            if #link == 1 then -- the linked table
                local meta = link[1]
                repeat -- loop detect {{{
                    meta = getmetatable(meta) and getmetatable(meta).__index
                    if meta == xn then break end
                until not meta -- }}}
                if meta then
                    tinsert(doctree[rml]['?'], 'loop '.. v) -- error message
                elseif xn ~= link[1] then
                    setmetatable(xn, {__index = link[1]})
                    TraceTbl(link[1], rml)
                end
            else
                tinsert(doctree[rml]['?'], 'broken <'..xn['.']..'> '..rpath..':'..#link..':'..v) -- error message
            end
        end
        for i = 1, #xn do if type(xn[i]) == 'table' then TraceTbl(xn[i], rml) end end -- continous override
    end -- }}}

    if #doc['?'] == 0 then TraceTbl(doc, toprml) end -- no error msg
    return toprml, doctree
end -- }}}
local function Simplify (doc, keys) -- {{{
    if (not doc['*'] or doc['*'] == '') and #doc == 0 then return
    end
    local attr = doc['@'] or {}
    local i1 = 0
    for i = 1, #doc do
        local item = Simplify(doc[i], keys)
        if item then
            i1 = i1 + 1
            for j = 1, #keys do
                if item['.'] == keys[j] then
                    if #item == 0 then
                        tinsert(attr, item['.'])
                        attr[item['.']] = item['*']
                        i1 = i1 - 1
                        item = nil
                    end
                    break
                end
            end
        end
        doc[i1] = item
    end
    for i = i1 + 1, #doc do doc[i] = nil end
    doc['@'] = #attr > 0 and attr or nil
    return doc
end -- }}}
lrm.Simplify = function (docs, keys) -- {{{
    for _, doc in ipairs(docs) do docs[_] = Simplify(doc, keys) end
end -- }}}
-- ======================================================================== --
-- Output
-- ======================================================================== --
lrm.threData = 512 -- threshold
lrm.threItem = 8   -- threshold
local rmlstring = function (s) -- {{{
    local q = (strfind(s, "^'") or not strfind(s, '"')) and '"' or "'"
    return q..strgsub(s, '([^\\])'..q..'(%s)', '%1\\'..q..'%2')..q
end -- }}}
local rmlpaste = function (s) -- {{{ -- encode: gzip -c | base64 -w 128 -- decode: base64 -i -d | zcat -f
    local seal, t = '', {}
    for _ in strgmatch(s, '%[(%w*)%]>') do if _ ~= '' and not t[_] then tinsert(t, _) ; t[_] = true end end -- uniq
    table.sort(t, function (a, b) return strlen(a) < strlen(b) end)
    if #t > 0 then seal = t[#t]..'0' end
    -- for i = 1, #t do end
    return '<txt['..seal..']'..s..'['..seal..']>'
end -- }}}
lrm.rmldata = function (s, mode, wid) -- {{{ -- mode=nil/auto,0/string,1/paste
    if s == '' then return s end
    if mode == 0 then return rmlstring(s) end
    if mode == 1 then return rmlpaste(s) end
    local t, d
    if strfind(s, '[\n\t]') or strfind(s, '%s%s') then -- {{{
        t, d = strmatch(s, '^(.*%s%s+%S*)(.*)$')
        if d and strfind(d, '[\n\t]') then
            d, s = strmatch(d, '^(.*[\n\t])%s*(.*)')
            d = rmlpaste(t..d)..' '
        elseif d and strfind(t, '[\n\t]') then
            d, s = rmlpaste(t)..' ', d
        elseif t then
            d, s = rmlstring(t)..' ', d
        else
            d, s = rmlpaste(s), ''
        end
    else
        t, d = strmatch(s, '^(.-%S+)(.*)$')
        if t and strfind(t, '[\'"]') or strfind(t, '<%w+%[') then
            d = '"" ' -- d, s = '"'..t..'" ', d
        elseif strfind(s, '^%s') then
            d = '"'..(strmatch(s, '^%s*'))..'" '
        else
            d = nil
        end
    end -- }}}
    s = strgsub(strgsub(s, ' #', ' \\#'), '^#', '\\#')
    wid = wid or 80 -- width
    t, mode = {}, 0 -- recycle variable
    for _ in strgmatch(s, '%S+') do -- {{{
        mode = mode + strlen(_) + 1
        if strsub(_, strlen(_)) == ':' then end
        if mode > wid and strsub(_, strlen(_)) ~= ':' then mode = 0 end
        tinsert(t, mode == 0 and #t > 0 and '\n'.._ or _)
    end -- }}}
    return d and d..tconcat(t, ' ') or tconcat(t, ' ')
end -- }}}
local fold_b, fold_e = '# {{{', '\n# }}}'
local function dumpLom (node, mode) -- {{{ RML format: mode nil/tbm-strict,0/all,1/lua
    -- tbm = {['.'] = tag; ['@'] = value; ...}
    local res, attr
    if node['@'] then -- {{{
        res = {}
        local len = 0 -- {{{ check the attr style
        for _, k in ipairs(node['@']) do
            local v = node['@'][k]
            if v then
                if not attr and strfind(v, '%s') then attr = true end
                len = len + strlen(v) + 1
            end
            len = len + strlen(k) + 1
        end
        if len < 0 then attr = true end -- }}}
        for _, k in ipairs(node['@']) do
            local v = node['@'][k]
            if v then
                tinsert(res, attr and k..' = '..strgsub(lrm.rmldata(v, 0), '\n', '\n'..indent) or k..'='..v)
            else
                tinsert(res, k)
            end
        end
        attr = attr and '{\n'..tconcat(res, '\n')..'\n}' or tconcat(res, '|')
    end -- }}}
    res = node['*'] and lrm.rmldata(node['*']) or ''
    local foldb, folde = '', ''
    if strlen(res) > lrm.threData or #node > lrm.threItem then foldb, folde = fold_b, fold_e end
    if strfind(res, '\n') or #node > 0 then
        res = strfind(res, '\n') and ' '..foldb..'\n'..res or (res == '' and ' ' or ' '..res..' ')..foldb
        if #node == 0 then res = res..folde end
    elseif res ~= '' then
        res = ' '..res
    end
    res = (node['.'] or '')..(attr and '|'..attr or '')..':'..res
    if #node > 0 then -- {{{
        res = {res}
        for i = 1, #node do
            if type(node[i]) == 'table' then
                tinsert(res, dumpLom(node[i]))
            -- else
            --     s = tostring(s)
            --     tinsert(res, {['*'] = node[i]}) -- or ERROR
            end
        end
        res = tconcat(res, '\n')..folde
    end -- }}}
    return (strgsub(res, '\n', '\n'..indent))
end -- }}}
lrm.Dump = function (docs) -- {{{ dump table -- rml is of multiple document format
    local res = {}
    for _, doc in ipairs(docs) do tinsert(res, dumpLom(doc)) end
    return #res == 0 and '' or '#rml version=1 mode=0 tab=4\n'..strgsub(tconcat(res, '\n'), '[ ]*\n', '\n')..
        '\n# vim: ts=4 sw=4 sts=4 et foldenable fdm=marker fmr={{{,}}} fdl=1' -- editor hint
end -- }}}
-- ======================================================================== --
if #arg > 0 then -- service for fast checking object model -- {{{
    local rml = (arg[1] == '-' and io.stdin or io.open(arg[1], 'r')) or error('Erro open '..arg[1])
    rml = lrm.Parse(rml:read('a'), 0)
    print(rml['?'][1] or lrm.Dump(rml))
end -- }}}

return lrm
-- ======================================================================== --
-- vim: ts=4 sw=4 sts=4 et foldenable fdm=marker fmr={{{,}}} fdl=1

#!/usr/bin/env lua
-- ======================================================================== --
-- Lua Object Model
-- Usage example:
--      lrm = require('lrm')
--      doc = lrm.ParseRml(file)
--      print(doc.Flow.LayoutWriter[1]['@name'])
--      rml = lrm.Dump(doc, true)
--      subrml = lrm.Dump(doc.Flow.LayoutWriter, 'TestTag')
-- ======================================================================== --
local lrm = {id = ''} -- version control

-- local lrp = require('lrp') -- the standard Lua Expat module
local lrp = require('lsrml') -- the standard Lua Expat module
local tun = require('util') -- for path

local next, assert, type = next, assert, type
local strlen, strsub, strmatch, strgmatch = string.len, string.sub, string.match, string.gmatch
local strrep, strgsub, strfind = string.rep, string.gsub, string.find
local tinsert, tremove, tconcat = table.insert, table.remove, table.concat

local indent = strrep(' ', 4)
-- ======================================================================== --
-- LOM (Lua Object Model)
-- ======================================================================== --
lrm.Parse = function (txt, fmt) -- {{{ fmt: 0/xml, 1/lua
    local node = {} -- working variable: doc == root node (node == token == tag == table)

    local lrmcallbacks = {
        Spec = function (parser, spec) -- {{{
        end; -- }}}
        StartTag = function (parser, name, attr) -- {{{
            local xn = {['.'] = node} -- record parent node
            if #attr > 0 then xn['@'] = attr end
            tinsert(node, xn)
            node = xn
        end; -- }}}
        EndTag = function (parser, name) -- {{{
            node, node['.'] = node['.'], name -- record the tag/node name
        end; -- }}}
        Data = function (parser, s) -- {{{
            node[''] = s
        end; -- }}}
        Paste = function (parser, s, hint, seal) -- {{{
            return s
        end; -- }}}
        String = function (parser, s) -- {{{
            return s
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
    filename = tun.normpath(filename)
    if type(doctree) == 'table' and doctree[filename] then return doctree[filename] end

    local file, msg = io.open(filename, 'r')
    if not file then return {['?'] = {msg}} end
    local doc = lrm.Parse(file:read('*all'), mode)
    file:close()

    if type(doctree) == 'table' then doctree[filename] = doc end
    return doc
end -- }}}
lrm.RmlBuild = function (rmlfile, mode) -- toprml, doctree = lrm.RmlBuild(rootfile) -- {{{ -- trace and meta
    local toprml, base = tun.normpath(rmlfile)
    local doctree = {}
    local doc = lrm.ParseRml(toprml, doctree, mode) -- doc table

    local function TraceTbl (xn, rml) -- {{{ lua table form
        local v = xn['@'] and xn['@']['url']
        if v then -- attr

            local link, xpath = strmatch(v, '^([^#]*)(.*)') -- {{{ file_link, tag_path
            if link == '' then -- back to this doc root
                link = rml
            else -- new file
                if strsub(link, 1, 1) ~= '/' then link = strgsub(rml, '[^/]*$', '')..link end
                link = tun.normpath(link)
            end -- }}}

            if not doctree[link] then TraceTbl(lrm.ParseRml(link, doctree, mode), link) end
            link, xpath = tun.xPath(doctree[link], strmatch(xpath or '', '#ptr%((.*)%)'))

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
                tinsert(doctree[rml]['?'], 'broken <'..xn['.']..'> '..xpath..':'..#link..':'..v) -- error message
            end
        end
        for i = 1, #xn do if type(xn[i]) == 'table' then TraceTbl(xn[i], rml) end end -- continous override
    end -- }}}

    if #doc['?'] == 0 then TraceTbl(doc, toprml) end -- no error msg
    return toprml, doctree
end -- }}}
-- ======================================================================== --
-- Output
-- ======================================================================== --
lrm.rmlstr = function (s, fenc) -- {{{
    -- encode: gzip -c | base64 -w 128
    -- decode: base64 -i -d | zcat -f
    -- return '<!-- base64 -i -d | zcat -f -->{{{'..
    --     tun.popen(s, 'tun.gzip -c | base64 -w 128'):read('*all')..'}}}'
    s = tostring(s)
    if strfind(s, '\n') or (strlen(s) > 1024) then -- large text
        if fenc or strfind(s, ']]>') then -- enc flag or hostile strings
            local status, stdout, stderr = tun.popen(s, 'gzip -c | base64 -w 128')
            return '<!-- base64 -i -d | zcat -f -->{{{'..stdout..'}}}'
        else
            -- return (strfind(s, '"') or strfind(s, "'") or strfind(s, '&') or
            --         strfind(s, '<') or strfind(s, '>')) and '<![CDATA[\n'..s..']]>' or s
            return (strfind(s, '&') or strfind(s, '<') or strfind(s, '>')) and '<![CDATA[\n'..s..']]>' or s
        end
    else -- escape characters
        return strgsub(strgsub(strgsub(strgsub(strgsub(s,
            '"', '&quot;'), "'", '&apos;'), '&', '&amp;'), '<', '&lt;'), '>', '&gt;')
    end
end -- }}}
local function dumpLom (node) -- {{{ RML format: tbm = {['.'] = tag; ['@attr'] = value; ...}
    if not node['.'] then return end
    local res, subnode = {}, #node > 0
    if node['@'] then
        for _, k in ipairs(node['@']) do
            tinsert(res, k..'="'..strgsub(node['@'][k], '"', '\\"')..'"')
        end -- table.sort(res)
    end
    res = '<'..node['.']..(#res > 0 and ' '..tconcat(res, ' ') or '')
    if #node == 0 then return res..' />' end
    for i = 1, #node do if type(node[i]) == 'table' then subnode = false ; break end end
    if subnode then return res..'>'..lrm.rmlstr(tconcat(node, ' '))..'</'..node['.']..'>' end
    res = {res..'>'}
    for i = 1, #node do tinsert(res, type(node[i]) == 'table' and dumpLom(node[i]) or lrm.rmlstr(node[i])) end
    return strgsub(tconcat(res, '\n'), '\n', '\n'..indent)..'\n</'..node['.']..'>'
end -- }}}
lrm.Dump = function (doc, frml) -- {{{ dump
    return type(doc) ~= 'table' and '' or (frml and '#rml ver=1\n'..dumpLom(doc) or tun.dumpVar(0, doc))
end -- }}}

return lrm
-- ======================================================================== --
-- vim: ts=4 sw=4 sts=4 et foldenable fdm=marker fmr={{{,}}} fdl=1

#!/usr/bin/env lua
--[=[ RML (Reduced Markup Language) Parser
    rml     := '#rml' [blank+ [attr1]]* blank* '\r' [assign | blank* comment]*
    blank   := ' ' | '\t'
    space   := [blank | '\r']+
    assign  := blank* [id] [prop1* | prop2] ':' [blank+ (pdata | sdata)] [[space (ndata | comment)]* '\r']+
    comment := '#' ([^\r]*' '\r' | pdata)
    prop1   := '|' [attr0 | attr1]
    prop2   := '|{' space [blank* [[attr0 | attr2]] space comment* '\r']* '}'
    attr0   := id
    attr1   := id '=' ndata
    attr2   := id blank* '=' [blank+ (pdata | sdata)]
    pdata   := '<' [id] '[' id ']' .* '[' id ']>'
    sdata   := ['|"] .* ['|"] {C-string}
    ndata   := \S+ {' \#' is replaced w/ ' #'}
--]=]
local lrp = require('pool') { -- linux rml parser
    spec = false; -- document spec
    tags = false; -- tag hierarchy
    data = false; -- current data
    attr = false; -- attribute array
    seek = false; -- seeking tag and seta
    hint = false; -- paste hint
    seal = false; -- paste seal/stamp
    indl = false; -- indentation level
    quot = false; -- quotation type " or '
    seta = false; -- setting attribute

    ['<'] = function (o, callbacktbl, debug) -- {{{
        if type(callbacktbl) == 'table' then
            o.Spec     = callbacktbl.Spec     or o.Spec
            o.StartTag = callbacktbl.StartTag or o.StartTag
            o.EndTag   = callbacktbl.EndTag   or o.EndTag
            o.Data     = callbacktbl.Data     or o.Data
            o.Paste    = callbacktbl.Paste    or o.Paste
            o.String   = callbacktbl.String   or o.String
            o.Comment  = callbacktbl.Comment  or o.Comment
        end
        o.spec = {version = '1'; tab = 4; mode = 0} -- mode 0/relax, 1/strict, 2/critical
        if debug then o.debug = function (o, ...) print(...) end end
    end; -- }}}

    ['>'] = function (o) o:close() end;

    -- pseudo member functions for callbacks
    Spec     = function (o, spec)            o:debug('Spec:', spec)                end;
    StartTag = function (o, name, attr, ind) o:debug('StartTag:', name, attr, ind) end;
    EndTag   = function (o, name)            o:debug('EndTag:', name)              end;
    Data     = function (o, str)             o:debug('Data:', str)                 end;
    Paste    = function (o, str, hint, seal) o:debug('Paste:', str, hint, seal)    return str end;
    String   = function (o, str)             o:debug('String:', str)               return str end;
    Comment  = false; -- function (o, str) o:debug('Comment:', str) end;

    debug = function (o) end; -- nil function
    checkIdFmt = function (o, name) return name and string.match(name, '^[%w_][%w_%:%.%-]*$') end;

    close = function (o, indl) -- close and validation -- {{{
        if not indl then
            if o.attr or o.quot or o.seal then return "Data not closed" end
            indl = 0
        end
        if o.data and (#o.tags > 0) then
            o:Data(type(o.data) == 'table' and table.concat(o.data, ' ') or o.data)
        end
        o.data = false
        while #o.tags > indl do o:EndTag(o.tags[#(o.tags)]) table.remove(o.tags) end
        o.indl = #o.tags -- sync
    end; -- }}}

    setSpec = function (o, line) -- {{{ tab:version:mode:style:stamp
        line = string.match(line, '^#rml%s(.*)')
        if line then
            for item in string.gmatch(line, '%S+') do
                local k, v = string.match(item, '([^=]*)=(.*)')
                if k and v then o.spec[k] = v end
            end
            o.spec.tab = tonumber(o.spec.tab) or 0
            if o.spec.tab <= 0 then msg = 'setting: tab' end
            o.spec.mode = tonumber(o.spec.mode) or 0
            o:Spec(o.spec)
            o.tags = {}
        else
            return line, 'Not an RML document'
        end
    end; -- }}}

    forceIndent = function (o, line) -- {{{ indentation?
        local s = o.spec.mode > 0 and o.indl * o.spec.tab or 0
        if s > 1 and #o.data > 0 then
            if string.find(string.sub(line, 1, s), '%S') then
                if o.spec.mode > 1 then return nil, "indentation("..s..")" end
            else
                line = string.sub(line, 1 + s)
            end
        end
        return line
    end; -- }}}

    setString = function (o, line) -- string {{{
        local t, d = o.quot..' ', string.gsub(line, '\\'..o.quot, '\n')..' ' -- replace quote w/ \n
        if string.find(d, t) then -- closing
            d, line = string.match(d, '(.-)'..t..'(.-)%s?$')
            d, t = o:forceIndent((string.gsub(d, '\n', o.quot))) -- t is the error msg
            table.insert(o.data, d)
            o.data = o:String(table.concat(o.data, '\n'))
            line = string.find(line, '%S') and string.gsub(line, '\n', '\\'..o.quot) or nil
            o.quot = false
            o.seek = false
            return line, t
        else
            line, t = o:forceIndent(line)
            table.insert(o.data, line)
            return nil, t
        end
    end; -- }}}

    setPaste = function (o, line) -- paste -- {{{
        if o.hint then
            local d = line..' '
            if string.find(d, '%['..o.seal..'%]> ') then -- closing
                d, line = string.match(d, '^(.-)%['..o.seal..'%]>%s(.*)')
                d, t = o:forceIndent(d) -- t is the error msg
                table.insert(o.data, d)
                o.data = o:Paste(table.concat(o.data, '\n'), o.hint, o.seal)
                o.seal = false
                o.seek = false
                return (string.find(line, '%S') and line or nil), t
            else
                line, t = o:forceIndent(line)
                table.insert(o.data, line)
                return nil, t
            end
        else -- comment
            if o.Comment then o:Comment(line) end
            if string.find(line, '#%['..o.seal..'%]>') then o.seal = false end
        end
    end; -- }}}

    setData = function (o, line, s) -- {{{
        local t, d
        if not o.data then -- {{{ data: string and paste first once
            o.quot, d = string.match(line, '^%s*(["\'])(.*)')
            if not o.quot then o.hint, o.seal, d = string.match(line, '^%s*<([^%[]*)%[([^%]]*)%](.*)') end
            if d then -- o.quot or o.seal
                o.data = {}
                o.seek = false
                return d
            end
        end -- }}}
        t, d = string.match(line, '^(.-)%s(#.*)') -- {{{ retular data
        if not t then t = line end
        if string.find(t, '%S') then
            if s < o.spec.tab * o.indl then return t, 'data indentation' end
            t = string.gsub(string.gsub(string.match(t, '(%S.-)%s*$'), '%s+', ' '), '\\#', '#')
            if o.attr then return d, 'attr data format ('..t..')' end
            if type(o.data) == 'table' then
                table.insert(o.data, t)
            else
                o.data = o.data and o.data ~= '' and {o.data, t} or t
            end
        end
        return d -- }}}
    end; -- }}}

    parse = function (o, rml) -- {{{
        local l, c, p, msg = 0 -- message, line, column, position
        for line in string.gmatch(rml, '[^\n]*') do -- {{{
            o.seek = true
            l = l + 1
            o:debug(l, line)
            local s, t, d = string.match(line, '^(%s*)') -- space, tag, data
            s = string.len(s)
            repeat -- {{{
                if not o.tags then
                    line, msg = o:setSpec(line) -- #rml [var=val]*
                elseif o.quot then
                    line, msg = o:setString(line)
                elseif o.seal then
                    line, msg = o:setPaste(line)
                elseif string.find(line, '%S') then -- non empty -- {{{
                    t, d = string.match(line, '^%s*(%S+)(.*)')
                    if string.sub(t, 1, 1) == '#' then -- {{{ comment
                        if o.Comment then o:Comment(t..d) end
                        o.hint, o.seal, d = string.match(t, '^%s*#<([^%[]*)%[([^%]]*)%](.*)')
                        if o.seal then o.hint = false ; line = d else line = nil end -- }}}
                    else -- attr or tags -- {{{
                        if o.seek then -- {{{ seek tag
                            if o.attr then -- {{{
                                if o.seta then o.attr[o.seta] = o.data or '' end
                                o.data = false
                                if string.find(t, "=$") or string.find(d, "^%s+=") then -- {{{
                                    o.seta = string.match(t, "[^=]*")
                                    if o:checkIdFmt(o.seta) and not o.attr[o.seta] then -- check duplicate
                                        table.insert(o.attr, o.seta) -- record order
                                        line = string.match(d, "%s*=?%s*(.*)")
                                    else
                                        msg = 'wrong/duplicate attribute '..o.seta
                                    end
                                else
                                    if t == '}:' then
                                        o.indl = o.indl - 1
                                        o:StartTag(o.tags[#o.tags], o.attr, o.indl) o.attr = false
                                    else
                                        if o:checkIdFmt(string.match(t, '^[%&%*]?(%S+)$')) then
                                            table.insert(o.attr, t)
                                            o.data = '' -- true
                                        else
                                            msg = 'wrong attribute property'
                                        end
                                    end
                                    o.seta = false
                                    line = d
                                end -- }}}
                                o.seek = false -- }}}
                            elseif string.find(t, ':$') then -- tag -- {{{
                                if s % o.spec.tab == 0 then
                                    o:close(math.ceil(s / o.spec.tab))
                                    o.attr = {}
                                    t = string.match(t, '(.*):$')
                                    for _ in string.gmatch(t, '([^|]*)') do -- {{{
                                        if type(o.seek) ~= 'string' then
                                            o.seek = _ -- the real (first) tag
                                        else
                                            local k, v = string.match(_, '([^=]+)=(.*)')
                                            if k then
                                                table.insert(o.attr, k)
                                                o.attr[k] = v
                                            else
                                                table.insert(o.attr, _)
                                            end
                                        end
                                    end -- }}}
                                    if o.seek == '' or o:checkIdFmt(o.seek) then -- {{{
                                        table.insert(o.tags, o.seek)
                                        o:StartTag(o.tags[#o.tags], o.attr, o.indl) o.attr = false
                                        o.seek = false
                                        line = d
                                    else
                                        msg = 'wrong tag name '..o.seek
                                    end -- }}}
                                else
                                    msg = 'indentation'
                                end -- }}}
                            elseif string.find(t, '|{$') then -- attr -- {{{
                                if s % o.spec.tab == 0 then
                                    o:close(math.ceil(s / o.spec.tab))
                                    t = string.match(t, '^(.*)|{$')
                                    if o:checkIdFmt(t) then
                                        table.insert(o.tags, t)
                                        o.attr = {}
                                        line = d
                                        o.indl = o.indl + 1
                                    else
                                        msg = 'wrong tag name for attr'
                                    end
                                else
                                    msg = 'indentation'
                                end
                            end -- }}}
                        end -- }}}

                        if msg or not string.find(line, '%S') then line = nil
                        elseif not string.find(line, '^%s*#') then line, msg = o:setData(line, s)
                        elseif o.Comment                      then o:Comment(line) end
                    end -- }}} -- }}}
                else -- empty line
                    line = nil
                end
            until msg or not line -- }}}
            if msg then break end
        end -- }}}
        return msg == nil, msg, l, c, p -- status, msg, line, col, pos
    end; -- }}}
}
-- {{{ ==================  demo and self-test (QA)  ==========================
local rml = lrp()
local status, msg, line = rml:parse(
[[#rml version=1.0 tab=4 mode=1 stamp=md5:127e416ebd01bf62ee2321e7083be0df style=var://style
  #<[]comment start
  #[]>comment end

style: "html" default # {{{
    h1: fn=5          # header 1
    f1: fn=3 color=4  # footnote 1
        numbering: # i, ii, ...
            roman
    # }}}
doc1:
    title|h1: self test
    footnote|f1: #
        <tex[seal1]
        simple latex math
\[
    1 + \exp^{i \pi} \;\;=\;\; 0
\]
    [seal1]> shows in the "footnote" section # no need to escape char like \"

    chapter|http://link/to/other/file/var|&id: # setting id
    chapter|{ # comment
        *id   #<[]
              handling id depends on dom
              #[]> whole line in comment
        ft = #
        fn = "30" #
        fs = <test[]start
        end[]> # string or paste do not allow extra regular data
        }: example text
        item: "" "item 1" test: <and[]# test and # comment part
            footnote|f1: another footnote
        : \#
doc2|h1:
    |p:
        :
    |p:
        regular "data]])
msg = msg or rml:close()
if msg or not status then error('RML QA failed @'..line..': '..msg, 1) end
-- }}}
if #arg > 0 then -- service for fast checking rml syntax -- {{{
    rml = lrp(true, false)
    status, msg, line = rml:parse(
        ((arg[1] == '-' and io.stdin or io.open(arg[1], 'r')) or error('Failed open '..arg[1])):read('a')
        )
    msg = msg or rml:close()
    if msg or not status then print('@line('..line..'): '..msg) end -- as unix tradition, say nothing if OK
end -- }}}

return lrp -- lua object model
-- ======================================================================== --
-- vim: ts=4 sw=4 sts=4 et foldenable fdm=marker fmr={{{,}}} fdl=1

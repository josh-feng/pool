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
    spec = false;
    tags = false;
    data = false;
    attr = false;
    seek = false; -- tag seeking
    hint = false;
    seal = false;
    indn = false; -- indentation
    quot = false; -- quotation mark q or qq
    setk = false;

    ['<'] = function (o, callbacktbl) -- {{{
        if type(callbacktbl) == 'table' then
            o.StartTag = callbacktbl.StartTag or o.StartTag
            o.EndTag   = callbacktbl.EndTag   or o.EndTag
            o.Data     = callbacktbl.Data     or o.Data
            o.Paste    = callbacktbl.Paste    or o.Paste
            o.String   = callbacktbl.String   or o.String
        end
        o.spec = {tab = 4; ver = '1.0'}
    end; -- }}}

    ['>'] = function (o) o:close() end;

    -- pseudo member functions for callbacks
    StartTag = function (o, name, ind, attr) print('StartTag:', name, ind, attr) end;
    EndTag   = function (o, name)            print('EndTag:', name) end;
    Data     = function (o, s)               print('Data:', s) end;
    Paste    = function (o, s, hint, seal)   print('Paste:', s, hint, seal) return s end;
    String   = function (o, s)               print('String:', s) return s end;

    close = function (o) -- close and validation -- {{{
        if o.data and (#o.tags > 0) then
            o:Data(type(o.data) == 'table' and table.concat(o.data, ' ') or o.data)
            while #o.tags > 0 do
                o:EndTag(o.tags[#(o.tags)])
                table.remove(o.tags)
            end
        end
    end; -- }}}

    parse = function (o, rml) -- {{{
        local l, c, p, msg = 0 -- message, line, column, position
        for line in string.gmatch(rml, '[^\n]*') do -- {{{
            o.seek = true
            l = l + 1
            print(l, line) -- debug
            local s, t, d -- space, tag, data
            repeat -- {{{
                if not o.tags then -- #rml [var=val]* -- {{{ tab:version:style:stamp
                    line = string.match(line, '^#rml%s(.*)')
                    if line then
                        for item in string.gmatch(line, '%S+') do
                            local k, v = string.match(item, '([^=]*)=(.*)')
                            if k and v then o.spec[k] = v end
                        end
                        o.spec.tab = tonumber(o.spec.tab) or 0
                        if o.spec.tab <= 0 then msg = 'setting: tab' end
                        if o.spec.ver ~= '1.0' then msg = 'setting: ver' end
                        o.tags = {}
                        line = nil
                    else
                        msg = 'Not a RML document'
                    end -- }}}
                elseif o.quot then -- string {{{
                    t, d = o.quot..' ', string.gsub(line, '\\'..o.quot, '\n')..' '
                    if string.find(d, t) then -- closing
                        d, line = string.match(d, '(.-)'..t..'(.-)%s?$')
                        table.insert(o.data, (string.gsub(d, '\n', '\\'..o.quot)))
                        o.data = o:String(table.concat(o.data, '\n'))
                        if line ~= '' then line = string.gsub(line, '\n', '\\'..o.quot) end
                        o.quot = false
                        o.seek = false
                    else
                        table.insert(o.data, line)
                        line = nil
                    end -- }}}
                elseif o.seal then -- paste -- {{{
                    if o.hint then
                        d = line..' '
                        if string.find(d, '%['..o.seal..'%]> ') then -- closing
                            d, line = string.match(d, '^(.-)%['..o.seal..'%]>%s(.*)')
                            table.insert(o.data, d)
                            o.data = o:Paste(table.concat(o.data, '\n'), o.hint, o.seal)
                            o.seal = false
                            o.seek = false
                        else
                            table.insert(o.data, line)
                            line = nil
                        end
                    else -- comment
                        if string.find(line, '#%['..o.seal..'%]>') then o.seal = false end
                        line = nil
                    end -- }}}
                elseif string.find(line, '%S') then -- non empty -- {{{
                    s, t, d = string.match(line, '^(%s*)(%S+)(.*)')
                    if string.sub(t, 1, 1) == '#' then -- {{{ comment
                        o.hint, o.seal, d = string.match(t, '^%s*#<([^%[]*)%[([^%]]*)%](.*)')
                        if o.seal then o.hint = false ; line = d else line = nil end -- }}}
                    else -- attr or tags -- {{{
                        if o.seek then -- {{{ seek tag
                            if o.attr then -- {{{
                                if o.setk then o.attr[o.setk] = o.data or '' end
                                if string.find(t, "=$") or string.find(d, "^%s+=") then
                                    o.setk = string.match(t, "[^=]*")
                                    table.insert(o.attr, o.setk)
                                    line = string.match(d, "%s*=?%s*(.*)")
                                    o.data = false
                                else
                                    if t == '}:' then
                                        o:StartTag(o.tags[#o.tags], o.indn, o.attr)
                                        o.attr = false
                                        o.data = false
                                    else
                                        table.insert(o.attr, t)
                                        o.data = '' -- true
                                    end
                                    o.setk = false
                                    line = d
                                end -- }}}
                                o.seek = false
                            elseif string.find(t, ':$') then -- tag -- {{{
                                if string.len(s) % o.spec.tab == 0 then
                                    if o.data and (#o.tags > 0) then
                                        o:Data(type(o.data) == 'table' and table.concat(o.data, ' ') or o.data)
                                    end
                                    o.indn = math.ceil(string.len(s) / o.spec.tab)
                                    while o.indn < #o.tags do o:EndTag(o.tags[#(o.tags)]) table.remove(o.tags) end
                                    o.attr = {}
                                    t = string.match(t, '(.*):$')
                                    for _ in string.gmatch(t, '([^|]*)') do table.insert(o.attr, _) end
                                    table.insert(o.tags, o.attr[1] or '')
                                    o:StartTag(o.tags[#o.tags], o.indn, o.attr)
                                    o.attr = false
                                    o.data = false
                                    o.seek = false
                                    line = d
                                else
                                    msg = 'indentation'
                                end -- }}}
                            elseif string.find(t, '|{$') then -- attr -- {{{
                                if string.len(s) % o.spec.tab == 0 then
                                    if o.data and (#o.tags > 0) then
                                        o:Data(type(o.data) == 'table' and table.concat(o.data, ' ') or o.data)
                                    end
                                    o.indn = math.ceil(string.len(s) / o.spec.tab)
                                    while o.indn < #o.tags do o:EndTag(o.tags[#(o.tags)]) table.remove(o.tags) end
                                    table.insert(o.tags, string.match(t, '^(.*)|{$'))
                                    o.data = false
                                    o.attr = {}
                                    line = d
                                else
                                    msg = 'indentation'
                                end
                            end -- }}}
                        end -- }}}

                        if msg or not string.find(line, '%S') then -- {{{
                            line = nil -- }}}
                        else -- {{{ search for data: string and paste first once
                            if not o.data then -- regular data -- {{{
                                o.quot, d = string.match(line, '^%s*(["\'])(.*)')
                                if not o.quot then -- {{{
                                    o.hint, o.seal, d = string.match(line, '^%s*<([^%[]*)%[([^%]]*)%](.*)')
                                end -- }}}
                            end -- }}}
                            if o.quot or o.seal then -- {{{
                                o.data = {}
                                line = d
                                o.seek = false -- }}}
                            else -- {{{ retular data
                                t, d = string.match(line, '^(.-)%s(#.*)')
                                if not t then t = line end
                                line = d
                                if string.find(t, '%S') then
                                    t = string.gsub(string.match(t, '(%S.-)%s*$'), '%s+', ' ')
                                    if o.attr and o.data then -- {{{
                                        msg = 'attr'
                                    elseif type(o.data) == 'table' then
                                        table.insert(o.data, t)
                                    else
                                        o.data = o.data and {o.data, t} or t
                                    end -- }}}
                                end
                            end -- }}}
                        end -- }}}
                    end -- }}} -- }}}
                else -- empty line -- {{{
                    line = nil
                end -- }}}
            until msg or not line -- }}}
            if msg then break end
        end -- }}}
        -- return status, msg, line, col, pos = lrp:parse(txt) -- passed nil if failed
        if msg then print('ERR '..msg) end
        return msg == nil, msg, l, c, p -- passed nil if failed
    end; -- }}}
}
-- {{{ ==================  demo and self-test (QA)  ==========================
if not lrp():parse([[#rml ver=1.0 stamp=md5:127e416ebd01bf62ee2321e7083be0df style=file1
    #<[ab] test
    # another test
    #[ab]>

#
style: "html" and another # {{{
    h1: # header 1
    h2: # header 2
    f1: font=3 color=4 # footnote 1
    atest|{  # comment
        test # test
        test = " test" #<[] test
        #[]>
        test = " test "
        abce #<[] test and all
            test not
        #[]>
        test = <test[]
            est test
            # est
        []>
        all = "is good = # "
        }: test
    : a: "" test: <and[] # test and # }}}

encoded: #
    <lua[]
    <test status="test" and=""> </test>
    -- continue of the text
    |encoded: # self reference
[]>
    continue of the text
    : # self reference

|h1: 魔鬼
    |f1: 已婚男士
: 搭訕。
: 這樣追孩真的很           容易
    author|f1: 魔鬼 著
: 以下是我2006年搭仙的統計數據 :
    : 約出來見面35人
    : 發展成好朋友的16個

|p:
    : 搭訕場景 : 商場、街頭、校園、地錢. 酒吧從來不去，成本太高，

123              3      5
124]])
then error('RML QA failed.', 1) end
-- }}}
return lrp -- lua object model
-- ======================================================================== --
-- vim: ts=4 sw=4 sts=4 et foldenable fdm=marker fmr={{{,}}} fdl=1

#!/usr/bin/env lua
-- ======================================================================== --
-- POOL (programming oo lua) 5.1 or later
-- ======================================================================== --
-- for efficiency, announce them as local variables
local error, tostring, type, setmetatable, rawset =
      error, tostring, type, setmetatable, rawset

local function cloneTbl (src) -- {{{ deep copy the string-key-ed
    local targ = {}
    for k, v in pairs(src) do
        if 'string' == type(k) then targ[k] = type(v) == 'table' and cloneTbl(v) or v end
    end
    return targ
end -- }}}

local function setVar (t, k, v) -- forbid creating vars -- {{{
    if t[k] == nil then error('Undefined in class:'..tostring(t), 2) end
    rawset(t, k, v)
end -- }}}
local function annihilator (o, ...) -- {{{ destructor for objects
    local mt = getmetatable(o)
    while mt do
        if mt['>'] then mt['>'](o) end -- rawget is not necessary
        mt = getmetatable(mt.__index)
    end
end -- }}} NB: not collected by gc immediately
local function polymorphism (o, mt, ...) -- {{{ constructor for objects
    local mtt = mt.__index -- metatable template
    if mtt then
        for _, v in pairs(mtt) do if type(v) == 'table' then o[_] = cloneTbl(v) end end -- dupe the table
        mtt = getmetatable(mtt)
        if mtt then polymorphism(o, mtt, ...) end
    end
    if mt['<'] then mt['<'](o, ...) end -- rawget is not necessary
end -- }}}

local class = { -- {{{
    list = {}; -- class record
    copy = function (c, o) -- duplicate object o
        local omt = getmetatable(o) or error('bad object', 2)
        o = cloneTbl(o)
        setmetatable(o, omt)
        return o
    end;
}

function class:new (o, ...) -- {{{
    o = (getmetatable(o) or error('bad object', 2))[1] -- class creator
    if not self.list[o] then error('bad object', 2) end
    return o(...)
end -- }}}
function class:parent (o) -- {{{ parent class
    o = (type(o) == 'table' and getmetatable(o) or self.list[o]) or error('bad object/class', 2)
    o = getmetatable(o.__index)
    return o and o[1] -- parent class creator
end -- }}}

setmetatable(class, {
    __metatable = true;
    __call = function (c, tmpl) -- class {{{
        if 'table' ~=  type(tmpl) then error('Class declaration:'..tostring(t), 2) end
        local omt, creator = {}, (type(tmpl[1]) == 'table') and tmpl[1][1]
        if creator then -- baseClass
            creator = c.list[creator] or error(' bad base class: '..tostring(tmpl[1][1]), 2)
            for k, v in pairs(creator) do omt[k] = v end -- inherite operators
        else
            omt.__newindex = setVar -- forbid new field addition
            omt.__gc = annihilator
        end
        if type(tmpl[1]) == 'table' then
            for k, v in pairs(tmpl[1]) do if type(k) == 'string' then omt[k] = v end end -- newly defined operators
        end
        tmpl = cloneTbl(tmpl) -- class template closure
        if tmpl['<'] and type(tmpl['<']) ~= 'function' then error(' bad constructor', 2) end
        if tmpl['>'] and type(tmpl['>']) ~= 'function' then error(' bad destructor', 2) end
        omt['<'], omt['>'], tmpl['<'], tmpl['>'] = tmpl['<'], tmpl['>'] -- polymorphism and remove reach from object
        if creator then
            creator.__gc = nil -- disable extra tmpl destructor
            setmetatable(tmpl, creator)
            creator.__gc = annihilator -- recover
        end
        omt.__index = tmpl

        creator = function (...) -- classes {{{ tmpl is the hidden class template
            local o = {}
            setmetatable(o, omt) -- need member functions
            polymorphism(o, omt, ...)
            return o -- the object
        end -- }}}
        c.list[creator] = omt
        omt[1] = creator
        return creator
    end; -- }}}
}) -- }}}

-- {{{ ==================  demo and self-tgest (QA)  =========================
local base = class {
    value = 1;
    variant = 1;

    { -- metatable: operator
        __add = function (o1, o2)
            local o = class:new(o1)
            o.value = o1.value - o2.value
            return o
        end;
    };

    ['<'] = function (o, v) o.value = v or o.value end; -- o is the object
}

local test = class {
    cvs_id = '$Id: $';
    extra = {};

    { -- metatable: inherit class 'base'
        base;
        __add = function (o1, o2) return o1.value + o2.value end; -- override
    };

    ['<'] = function (o, v) o.extra = (v or -1) + o.value end; -- overridden
}

local obj1, obj2, obj3 = base(3), test(2), test()

if -- failing conditions:
    obj1.value ~= 3 or obj2.extra ~= 4 or obj3.value ~= 1 -- constructor
    or obj2.variant ~= 1 or obj3.extra ~= 0 -- inheritance
    or ((obj1 + obj2).value ~= 1) -- operator following base obj1
    or (obj2 + obj3 ~= 3) -- operator following base obj2
    or (class:parent(test) ~= base) -- aux function
    or pcall(function () obj2.var = 1 end) -- object making new var
    or pcall(function () obj3['<'] = 1 end) -- object constructor
    or pcall(function () class(1) end) -- bad class declaration
then error('Class QA failed.', 1) end -- }}}

return class
-- ======================================================================== --
-- vim: ts=4 sw=4 sts=4 et foldenable fdm=marker fmr={{{,}}} fdl=1

#!/usr/bin/env lua5.3
-- POOL (programming object-oriented lua)
-- Josh Feng <joshfwisc@gmail.com> (C) GNU 2.0
-- Usage: require('pool')
--        sedan = class { make = 'Audi'; year = '2017'; }
--        car1 = sedan()

local error, tostring, type, getmetatable, setmetatable, rawget, rawset =
      error, tostring, type, getmetatable, setmetatable, rawget, rawset

local classList = {} -- class records
debug.class = classList

local function cloneTbl (src) -- {{{
    local targ = {}
    for k, v in pairs(src) do
        if 'string' == type(k) then targ[k] = type(v) == 'table' and cloneTbl(v) or v end
    end
    return targ
end -- }}}

local function setVar (t, k, v) -- forbid creating new vars {{{
    if t[k] == nil then error(k..' undefined in class:'..tostring(t), 2) end
    rawset(t, k, v)
end -- }}}

local function annihilator (o) -- {{{ destructor for objects
    local mt = getmetatable(o)
    while mt do
        if 'function' == type(rawget(mt, ';')) then mt[';'](o) end
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
    if 'function' == type(rawget(mt, ':')) then mt[':'](o, ...) end
end -- }}}

local class = function (tmpl) -- {{{ class
    if 'table' ~= type(tmpl) then error('Class decLaration: '..tostring(tmpl), 2) end
    local omt, constructor = {}, (type(tmpl[1]) == 'table') and tmpl[1][1]
    if constructor then -- baseClass
        constructor = classList[constructor] -- baseClass metatable
        if not constructor then error(' bad base class: '..tmple[1][1], 2) end
        for k, v in pairs(constructor) do omt[k] = v end -- inherite operators
    else
        omt.__newindex = setVar -- forbid new field addition
        omt.__gc = annihilator
    end
    if type(tmpl[1]) == 'table' then
        for k, v in pairs(tmpl[1]) do if type(k) == 'string' then omt[k] = v end end -- newly defined operators
    end
    tmpl = cloneTbl(tmpl) -- class template closure
    if tmpl[':'] and type(tmpl[':']) ~= 'function' then error(' bad constructor', 2) end
    if tmpl[';'] and type(tmpl[';']) ~= 'function' then error(' bad destructorr', 2) end
    omt[':'], omt[';'], tmpl[':'], tmpl[';'] = tmpl[':'], tmpl[';'] -- polymorphism and remove reach from object
    if constructor then setmetatable(tmpl, constructor) end
    omt.__index = tmpl

    constructor = function (...) -- creator {{{ tmpl is the hidden class template
        local o = {}
        setmetatable(o, omt) -- need member functions
        polymorphism(o, omt, ...)
        return o -- the object
    end -- }}}
    classList[constructor] = omt
    return constructor
end -- }}}

-- ========================= demo and self-tesst (QA) ============================ -- {{{
local base = class {
    value = 1;
    variant = 1;

    { -- metatable: operator
        __add = function (o1, o2) return o1.value - o2.value end;
    };

    [':'] = function (o, v) o.value = v or o.value end; -- o is the object
}

local test = class {
    extra = {};

    { -- metatable: inherit class 'base'
        base;
        __add = function (o1, o2) return o1.value + o2.value end; -- override
    };

    [':'] = function (o, v) o.extra = (v or -1) + o.value end;
}

local obj1, obj2, obj3 = base(3), test(2), test()
if -- failing conditions:
    obj1.value ~= 3 or obj2.extra ~= 4 or obj3.value ~= 1 -- constructor
    or obj2.variant ~= 1 or obj3.extra ~= 0 -- inheritance
    or (obj1 + obj2 ~= 1) -- operator follow base obj1
    or (obj2 + obj3 ~= 3) -- operator follow test obj2
    or pcall(function () obj2.var = 1 end) -- object making new var
    or pcall(function () obj3[':'] = 1 end) -- object constructor
    or pcall(function () class(1) end) -- bad clss declaration
    then error('Class QA failed.', 1)
end
for _ in pairs(classList) do classList[_] = nil end -- clean-up }}}

return class
-- vim: ts=4 sw=4 sts=4 ft=lua et foldenable fdm=marker fmr={{{,}}} fdl=1

#!/usr/bin/env lua
-- ====================================================================== --
-- POOL (Poorman's object-oriented lua)    MIT License (c) 2022 Josh Feng --
local pairs, error, tostring, type, getmetatable, setmetatable, rawset, next =
      pairs, error, tostring, type, getmetatable, setmetatable, rawset, next
local strmatch = string.match

--- deep copy a string-key-ed table
-- @parame src The source table
-- @parame mt The metatable for the target table
local function dupTbl (src, mt) -- {{{
    local targ = {}
    for k, v in pairs(src) do
        if 'string' == type(k) then
            targ[k] = type(v) == 'table' and dupTbl(v, getmetatable(v)) or v
        end
    end
    if mt then setmetatable(targ, mt) end -- No trace of src, since object is flat
    return targ
end -- }}}

--- forbid creating vars after class template
-- @param t The object (i.e. table)
-- @param k The key
-- @param v The value
local function setVar (t, k, v) -- {{{
    if t[k] == nil and type(k) ~= 'number' then error('Undefined ('..k..') in class:'..tostring(t), 2) end
    rawset(t, k, v)
end -- }}}

--- destructor for the object
-- Note that the object is not collected by gc immediately
-- @param o The object
local function annihilator (o, ...) -- {{{
    local mt = getmetatable(o)
    while mt do
        if mt['>'] then mt['>'](o) end -- rawget is not necessary
        mt = getmetatable(mt.__index)
    end
end -- }}}

--- constructor for the object
-- @param o The object
-- @param mt The metatable of the object
local function polymorphism (o, mt, ...) -- {{{
    local mtt = mt.__index -- metatable template
    if mtt then
        if mt[2] then -- default table values
            for _, v in pairs(mt[2]) do
                if not o[_] then o[_] = dupTbl(v, getmetatable(v)) end
            end
        end
        mtt = getmetatable(mtt)
        if mtt then polymorphism(o, mtt, ...) end
    end
    if mt['<'] then mt['<'](o, ...) end -- rawget is not necessary
end -- }}}

local class = { -- class records
    copy = function (c, o) -- duplicate the object o
        return dupTbl(o, getmetatable(o) or error('bad object', 2))
    end;
}

--- create a new object of the class
-- @param o An object that associates the class
function class:new (o, ...) -- {{{
    o = (getmetatable(o) or error('bad object', 2))[1] -- class (object creator)
    if type(self[o]) ~= 'table' then error('bad object', 2) end
    return o(...)
end -- }}}

--- find the parent class of a class (object)
-- @param o An object or its class
function class:parent (o) -- {{{
    o = (type(o) == 'table' and getmetatable(o) or self[o]) or error('bad object/class', 2)
    o = getmetatable(o.__index)
    return o and o[1] -- parent class (object creator)
end -- }}}

--- declare the class based on the template
-- @param tmpl The class template
-- @param creator The parent class
local function __class (tmpl, creator) -- {{{
    if 'table' ~= type(tmpl) then error('Class declaration:'..tostring(t), 2) end
    if tmpl['<'] and type(tmpl['<']) ~= 'function' then error(' bad constructor', 2) end
    if tmpl['>'] and type(tmpl['>']) ~= 'function' then error(' bad destructor', 2) end
    if tmpl['^'] and type(tmpl['^']) ~= 'table' then error(' bad operators', 2) end

    local omt = {} -- object's metatable
    omt.__call = function (o) return dupTbl(o, omt) end -- fast copy
    if creator then -- baseClass
        for k, v in pairs(creator) do omt[k] = v end -- inherite operators
    else
        omt.__newindex = setVar -- forbid new field addition
        omt.__gc = annihilator
    end
    if tmpl['^'] then
        for k, v in pairs(tmpl['^']) do -- newly defined operators
            if type(k) == 'string' then omt[k] = v end
        end
        omt[1], tmpl['^'] = tmpl['^'], nil
        omt[1], tmpl['^'] = dupTbl(tmpl), omt[1]
        tmpl = omt[1] -- class template closure
    else
        tmpl = dupTbl(tmpl) -- class template closure
    end

    -- polymorphism & remove their access from object
    omt['<'], omt['>'], tmpl['<'], tmpl['>'] = tmpl['<'], tmpl['>'], nil, nil
    if creator then
        creator.__gc = nil -- disable extra tmpl destructor
        setmetatable(tmpl, creator)
        creator.__gc = annihilator -- recover
    end
    omt.__index = tmpl

    omt[2] = {} -- default table value and recovery
    for k, v in pairs(tmpl) do
        if type(v) == 'table' then
            omt[2][k] = v
            tmpl[k] = false -- table-value when reset w/ nil
        end
    end
    if not next(omt[2]) then omt[2] = nil end

    tmpl = 'class_'..strmatch(tostring(omt), '%S*$') -- class identity
    omt.__tostring = omt.__tostring or function (o) return tmpl end

    creator = function (...) -- {{{ class/object-creator
        local o = {}
        setmetatable(o, omt) -- need member functions
        polymorphism(o, omt, ...)
        return o -- the object
    end -- }}}
    class[creator] = omt
    omt[1] = creator
    return creator
end; -- }}}

setmetatable(class, {
    __metatable = true;
    __call = function (c, cls) -- wrap the inheritance
        return type(cls) == 'function' and function (tpl) return __class(tpl, c[cls]) end or __class(cls)
    end;
})

return class
-- ====================================================================== --
-- vim:ts=4:sw=4:sts=4:et:fen:fdm=marker:fmr={{{,}}}:fdl=1

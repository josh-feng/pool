#!/usr/bin/env lua
-- ====================================================================== --
-- POOL (Poorman's object-oriented lua)    MIT License (c) 2019 Josh Feng --
-- ======================  demo and self-test (QA)  ===================== --
-- test basic class usage

local class = require('pool')

local base = class {
    value = 1;
    variant = 1;

    ['<'] = function (o, v) o.value = v or o.value end; -- o is the object

    ['^'] = { -- metatable: operator
        __add = function (o1, o2)
            local o = class:new(o1)
            o.value = o1.value - o2.value
            return o
        end;
    };
}

local test = class (base) { -- inherit class 'base'
    extra = {};

    ['<'] = function (o, v) o.extra = (v or -1) + o.value end; -- overridden

    ['^'] = { -- metatable:
        __add = function (o1, o2) return o1.value + o2.value end; -- override
    };
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
then error('Class QA failed.', 1) end
class[base] = nil
class[test] = nil

#!/usr/bin/env lua
-- ====================================================================== --
-- POOL (Poorman's object-oriented lua)    MIT License (c) 2019 Josh Feng --
-- complex number mathematics module
-- ref: R.V.Churchill, J.W. Brown, "Complex Variables and Applications", 4th ed., McGraw-Hill, 1984
local class = require 'pool'

local _type, _log, _exp, _sin, _cos, _atan, _sqrt =
    type, math.log, math.exp, math.sin, math.cos, math.atan, math.sqrt

local _tan, _asin, _acos, _abs = math.tan, math.asin, math.acos, math.abs

local complex = class {
    x = 0; -- real part
    y = 0; -- imaginary part

    ['<'] = function (o, x, y) o.x, o.y = x, y end;

    ['^'] = { -- support o1 or o2 regular number
        __add = function (o1, o2)
            if _type(o1) == 'number' then o1, o2 = o2, o1 end
            return 'number' == _type(o2)
                and class:new(o1, o1.x + o2, o1.y) or class:new(o1, o1.x + o2.x, o1.y + o2.y)
        end;

        __sub = function (o1, o2)
            if _type(o1) == 'number' then return class:new(o2, o1 - o2.x, - o2.y) end
            return _type(o2) == 'number'
                and class:new(o1, o1.x - o2, o1.y)
                or class:new(o1, o1.x - o2.x, o1.y - o2.y)
        end;

        __mul = function (o1, o2)
            if _type(o1) == 'number' then o1, o2 = o2, o1 end
            return 'number' == _type(o2)
                and class:new(o1, o1.x * o2, o1.y * o2)
                or class:new(o1, o1.x * o2.x - o1.y * o2.y, o2.x * o1.y + o2.y * o1.x)
        end;

        __div = function (o1, o2)
            if 'number' == _type(o2) then return class:new(o1, o1.x / o2, o1.y / o2) end
            local r = o2.x * o2.x + o2.y * o2.y
            return _type(o1) == 'number'
                and class:new(o2, o1 * o2.x / r, - o1 * o2.y / r)
                or class:new(o1, (o1.x * o2.x + o1.y * o2.y) / r, (o2.x * o1.y - o2.y * o1.x) / r)
        end;

        __pow = function (o1, o2) -- Pow ^ : o = o1^o2 = e^(o2 * log o1)
            if _type(o1) == 'number' then o1 = class:new(o2, o1) end
            local r, t = _log(o1.x * o1.x + o1.y * o1.y) * 0.5, _atan(o1.y, o1.x)
            if 'number' == _type(o2) then r, t = _exp(o2 * r), o2 * t
            else r, t = _exp(o2.x * r - o2.y * t), o2.x * t + o2.y * r end
            return class:new(o1, r * _cos(t), r * _sin(t))
        end;

        __band = function (o1, o2) -- Log & : o = log_o1 o2 i.e. o2 = o1^o = e^(o * log o1)
            if _type(o1) == 'number' then o1 = class:new(o2, o1) end
            local r, t = _log(o1.x * o1.x + o1.y * o1.y) * 0.5, _atan(o1.y, o1.x)
            if 'number' == _type(o2) then
                o2 = _log(o2) / (r * r + t * t)
                return class:new(o1, o2 * r, - o2 * t)
            end
            local r2, t2, d = _log(o2.x * o2.x + o2.y * o2.y) * 0.5, _atan(o2.y, o2.x), r * r + t * t
            return class:new(o1, (r2 * r + t2 * t) / d, (t2 * r - r2 * t) / d)
        end;

        __eq = function (o1, o2) return o1.x == o2.x and o1.y == o2.y end; -- same type

        __unm = function (o) return class:new(o, - o.x, - o.y) end;
        __bnot = function (o) return class:new(o, o.x, - o.y) end; -- ~ (conjugate)
        __len = function (o) -- the polar transform
            return class:new(o, _sqrt(o.x * o.x + o.y * o.y), _atan(o.y, o.x))
        end;
        __call = function (o, mode) -- ()fast-copy/(0)log-branch/(false)exp
            return mode == nil and class:copy(o) or
                (mode and class:new(o, _log(o.x * o.x + o.y * o.y) * 0.5, _atan(o.y, o.x))
                       or class:new(o, _exp(o.x) * _cos(o.y), _exp(o.x) * _sin(o.y)))
        end;
        __tostring = function (o)
            return o.y == 0 and tostring(o.x) or '('..o.x..', '..o.y..')'
        end;
    };
}

-- global variable
I = I or complex(0, 1)

-- demo
-- local z = complex()          --> (0, 0)
-- local z1 = z()               --> fast copy of z
-- local z2 = complex(1, 2)     --> (1, 2)
-- print(I, z1, z2)             --> (0, 1) (0, 0) (1, 2)
-- print((complex(2)&2) + I)    --> (1, 1)
-- print((2&complex(2)) + I)    --> (1, 1)
-- print(#I)                    --> polar form
-- print(complex(0) == 0)       --> false (must be the same type)
-- print(1 + I * I)
-- print(1 ~= I * I)
-- print(I - 1, I - I, 1 - I, 1 / I, 1^I, 2&I )

-- ====================================================================== --
-- modify type
type = function (o) return (getmetatable(o) and getmetatable(o)[1] == complex) and 'complex' or _type(o) end
-- print(type(I))

-- ====================================================================== --
-- extend math table function
math.sqrt = function (o)
    if 'number' == type(o) and o < 0 then return complex(0, _sqrt(-o)) end
    if 'complex' == type(o) then
        local r, t = _sqrt(_sqrt(o.x * o.x + o.y * o.y)), _atan(o.y, o.x) * 0.5
        return complex(r * _cos(t), r * _sin(t))
    end
    return _sqrt(o)
end

math.exp = function (o)
    if 'complex' == type(o) then
        local r = _exp(o.x)
        return complex(r * _cos(o.y), r * _sin(o.y))
    end
    return _exp(o)
end

math.log = function (o)
    if 'number' == type(o) and o < 0 then o = complex(o) end
    return 'complex' == type(o) and complex(_log(o.x * o.x + o.y * o.y) * 0.5, _atan(o.y, o.x)) or _log(o)
end

math.sin = function (o)
    if 'complex' == type(o) then
        local y = _exp(o.y)
        return complex((y + 1 / y) * 0.5 * _sin(o.x), (y - 1 / y) * 0.5 * _cos(o.x))
    end
    return _sin(o)
end

math.cos = function (o)
    if 'complex' == type(o) then
        local y = _exp(o.y)
        return complex((y + 1 / y) * 0.5 * _cos(o.x), (1 / y - y) * 0.5 * _sin(o.x))
    end
    return _cos(o)
end

math.tan = function (o)
    if 'complex' == type(o) then
        local y = _exp(o.y)
        local y2 = y * y
        local r = y2 + 1 / y2 + 2 * _cos(2 * o.x)
        return complex(2 * _sin(2 * o.x) / r, (1 / y2 - y2) / r)
    end
    return _tan(o)
end

math.asin = function (o) -- -I log ( I z + (1 - z*z)^1/2 )
    if 'number' == type(o) and o < -1 or 1 < o then o = complex(o) end
    if 'complex' == type(o) then
        local r, t = 1 - o.x * o.x + o.y * o.y, - 2 * o.x * o.y
        r, t = _sqrt(_sqrt(r * r + t * t)), _atan(t, r) * 0.5
        r, t = r * _cos(t) - o.y, r * _sin(t) + o.x
        return complex(_atan(t, r), - _log(r * r + t * t) * 0.5)
    end
    return _asin(o)
end

math.acos = function (o) -- -I log ( z + I (1 - z*z)^1/2 )
    if 'number' == type(o) and o < -1 or 1 < o then o = complex(o) end
    if 'complex' == type(o) then
        local r, t = 1 - o.x * o.x + o.y * o.y, - 2 * o.x * o.y
        r, t = _sqrt(_sqrt(r * r + t * t)), _atan(t, r) * 0.5
        r, t = o.x - r * _sin(t), r * _cos(t) + o.y
        return complex(_atan(t, r), - _log(r * r + t * t) * 0.5)
    end
    return _acos(o)
end

math.atan = function (o1, o2) -- 0.5 * I log ((I + z) / (I - z))
    if 'complex' == type(o1) then
        local r1, t1 = 1 + o1.x * o1.x + o1.y * o1.y + 2 * o1.y, _atan(1 + o1.y,  o1.x)
        local r2, t2 = 1 + o1.x * o1.x + o1.y * o1.y - 2 * o1.y, _atan(1 - o1.y, -o1.x)
        return complex((t2 - t1) * 0.5, (_log(r1 * r1 + t1 * t1) - _log(r2 * r2 + t2 * t2)) * 0.25)
    end
    return _atan(o1, o2)
end

math.abs = function (o)
    return 'complex' == type(o) and _sqrt(o.x * o.x + o.y * o.y) or _abs(o)
end

-- demo
-- print(math.log(I))
-- print(math.sqrt(I))
-- print(math.sqrt(-1) == I)
-- print(math.atan(I))
-- print(math.abs(I))
-- print(math.asin(2))

return complex
-- vim: ts=4 sw=4 sts=4 et foldenable fdm=marker fmr={{{,}}} fdl=1

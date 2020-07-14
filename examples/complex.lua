#!/usr/bin/env lua
-- Complex number mathematics
-- ref: R.V.Churchill, J.W. Brown, "Complex Variables and Applications", 4th ed., McGraw-Hill, 1984
local class = require 'pool'

local complex = class {
    x = 0; -- real part
    y = 0; -- imaginary part

    ['<'] = function (o, x, y) o.x, o.y = x, y end;

    { -- support o2 regular number
        __add = function (o1, o2) return 'number' == type(o2)
            and class:new(o1, o1.x + o2, o1.y) or class:new(o1, o1.x + o2.x, o1.y + o2.y)
        end;

        __sub = function (o1, o2) return 'number' == type(o2)
            and class:new(o1, o1.x - o2, o1.y) or class:new(o1, o1.x - o2.x, o1.y - o2.y)
        end;

        __mul = function (o1, o2) return 'number' == type(o2)
            and class:new(o1, o1.x * o2, o1.y * o2)
            or class:new(o1, o1.x * o2.x - o1.y * o2.y, o1.x * o2.y + o1.y * o2.x)
        end;

        __div = function (o1, o2)
            if 'number' == type(o2) then return class:new(o1, o1.x / o2, o1.y / o2) end
            local r = o2.x * o2.x + o2.y * o2.y
            return class:new(o1, (o1.x * o2.x + o1.y * o2.y) / r, (o1.x * o2.y - o1.y * o2.x) / r)
        end;

        __pow = function (o1, o2) -- Pow ^ : o = o1^o2 = e^(o2 * log o1)
            local r, t = math.log(o1.x * o1.x + o1.y * o1.y) * 0.5, math.atan(o1.y, o1.x)
            if 'number' == type(o2) then r, t = math.exp(o2 * r), o2 * t
            else r, t = math.exp(o2.x * r - o2.y * t), o2.y * r + o2.x * t end
            return class:new(o1, r * math.cos(t), r * math.sin(t))
        end;

        __band = function (o1, o2) -- Log & : o = log_o1 o2 i.e. o2 = o1^o = e^(o * log o1)
            local r, t = math.log(o1.x * o1.x + o1.y * o1.y) * 0.5, math.atan(o1.y, o1.x)
            if 'number' == type(o2) then
                o2 = math.log(o2) / (r * r + t * t)
                return class:new(o1, o2 * r, - o2 * t)
            end
            local r2, t2, d = math.log(o2.x * o2.x + o2.y * o2.y) * 0.5, math.atan(o2.y, o2.x), r * r + t * t
            return class:new(o1, (r2 * r + t2 * t) / d, (t2 * r - r2 * t) / d)
        end;

        __eq = function (o1, o2) return 'number' == type(o2) and o1.x == o2 or (o1.x == o2.x and o1.y == o2.y) end;
        __unm = function (o) return class:new(o, - o.x, - o.y) end;
        __bnot = function (o) return class:new(o, o.x, - o.y) end; -- ~ (conjugate)
        __len = function (o) return math.sqrt(o.x * o.x + o.y * o.y) end; -- the length (#) operation.
        __tostring = function (o) return '('..o.x..', '..o.y..')' end;
    };
}

-- global variable
I = complex(0, 1)

-- demo
-- local z = complex()
-- local z1 = z()                  -- fast copy of z
-- local z2 = complex(1)
-- print(I, z1 + z2)               --> (0, 1) (0, 0) (1, 0)
-- print((complex(2, 0)&2) + I)    --> (1, 1)

return complex
-- vim: ts=4 sw=4 sts=4 et foldenable fdm=marker fmr={{{,}}} fdl=1

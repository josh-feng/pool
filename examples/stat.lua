#!/usr/bin/env lua
-- probablity and statistical toolbox
-- ref:
--  - Wong, "Stochastic Processes in Engineering Systems"
--  - Hoel, Port, Stone,
--  - Doob, "Stochastic Processes", 1971
--  - Feller,
--  <http://www.circuitwizard.de/lmpfrlib/lmpfrlib.html>
local class = require('pool')
-- local complex = require('complex') -- for characteristic function (FFT)

local tsort, tconcat, tunpack = table.sort, table.concat, table.unpack
local mfloor, msqrt = math.floor, math.sqrt

local sample = class { -- {{{ pseudo random variable
    dims = false; -- data dimenstion of sample space

    ['<'] = function (o, ...) -- standard distribution {{{
        o.dims = table.pack(...)
        local f
        for i = 1, #(o.dims) do
            if f then
                o.dims[i] = nil
            elseif type(o.dims[i]) ~= 'number' then
                f = o.dims[i]
                o.dims[i] = nil
            end
        end
        local total = o.dims[1] or 0
        for i = 2, #(o.dims) do total = total * o.dims[i] end
        if type(f) == 'function' then -- initialize
            for i = 1, total do o[i] = f(o, i) end
        else
            f = f and 1 or 0
            for i = 1, total do o[i] = f end
        end
    end; -- }}}

    ['^'] = { -- operators (cycle rule)
        __add = function (o1, o2)
            local n1, n2 = #o1, #o2
            local o = class:new(o1)
            if n1 == 0 or n2 == 0 then return o end
            if n1 > n2 then for i = 1, n1 do o[i] = o1[i] + o2[(i - 1) % n2 + 1] end
            else            for i = 1, n2 do o[i] = o1[(i - 1) % n1 + 1] + o2[i] end end
            return o
        end;

        __sub = function (o1, o2)
            local n1, n2 = #o1, #o2
            local o = class:new(o1)
            if n1 == 0 or n2 == 0 then return o end
            if n1 > n2 then for i = 1, n1 do o[i] = o1[i] - o2[(i - 1) % n2 + 1] end
            else            for i = 1, n2 do o[i] = o1[(i - 1) % n1 + 1] - o2[i] end end
            return o
        end;

        __mul = function (o1, o2)
            local n1, n2 = #o1, #o2
            local o = class:new(o1)
            if n1 == 0 or n2 == 0 then return o end
            if n1 > n2 then for i = 1, n1 do o[i] = o1[i] * o2[(i - 1) % n2 + 1] end
            else            for i = 1, n2 do o[i] = o1[(i - 1) % n1 + 1] * o2[i] end end
            return o
        end;

        __div = function (o1, o2)
            local n1, n2 = #o1, #o2
            local o = class:new(o1)
            if n1 == 0 or n2 == 0 then return o end
            if n1 > n2 then for i = 1, n1 do o[i] = o1[i] / o2[(i - 1) % n2 + 1] end
            else            for i = 1, n2 do o[i] = o1[(i - 1) % n1 + 1] / o2[i] end end
            return o
        end;

        __eq = function (o1, o2)
            if #o1 ~= #o2 then return false end
            for i = 1, #o1 do if o1[i] ~= o2[i] then return false end end
            return true
        end;

        __band = function (o1, o2) -- bitwise AND & : convolution
            if #o1 == 0 or #o2 == 0 then return end
            local o = class:new(o1)
            for i = 1, (#o1 + #o2 - 1) do
                local v = 0
                for j = 1, #o2 do -- TODO
                    if i >= j then v = v + o1[i - j + 1] * o2[j] else break end
                end
                o[i] = v
            end
            return o
        end;

        __bor = function (o1, o2) -- bitwise OR | : inner product
            if #o1 ~= #o2 then return end
            local v = 0
            for i = 1, #o1 do v = v + o1[i] * o2[i] end
            return v
        end;

        -- __pow = function (o1, o2) end; -- power ^ : norm?
        -- __mod = function (o1, o2) end; -- modulo % : regression?
        -- __idiv = function (o1, o2) end; -- floor division // : norm?
        -- __unm = function (o1, o2) end; -- negation -
        -- __bnot   = function (o1, o2) end; -- bitwise not ~ : transpose?
        -- __bxor   = function (o1, o2) end; -- bitwise exclusive OR ~
        -- __shl    = function (o1, o2) end; -- bitwise shift left <<
        -- __shr    = function (o1, o2) end; -- bitwise shift right >>
        -- __concat = function (o1, o2) end; -- concatination ..
        -- __len    = function (o1, o2) end; -- transpose #
        -- __lt     = function (o1, o2) end; -- less than < (not defined)
        -- __le     = function (o1, o2) end; -- less equal <= (not defined)
        -- __call = function (o, mode) end; -- ()fast-copy/(0)/(false)

        __tostring = function (o) -- TODO dims/average/std.dev
            return o.dims and tconcat(o.dims, ':') or ''
        end;
    };

    -- member functions / statistics (sample)
    dup = function (o) -- duplicate {{{
        local n = o()
        for i = 1, #o do n[i] = o[i] end -- transfer the data
        return n
    end; -- }}}

    map = function (o, f) for i = 1, #o do o[i] = f(o, i) end end;

    fft = function (o1, o2) --{{{ complex characteristic function? TODO
        local f1, f2 -- real and complex part array
        return f1, f2
    end; --}}}

    sort = table.sort;

    range = function (o, tile) -- min / median / max {{{
        tile = tonumber(tile) or 0
        local d = o:dup()
        d:sort()
        return d[1 + tile], d[mfloor((#d + 1) / 2)], d[#d - tile]
    end; --}}}

    mnt = function (o, n) --{{{ moments (sum, 2nd-mom, ... )
        n = n or 1 -- upto n-th moments
        local res = {}
        for i = 1, n do res[i] = 0 end
        for _, v in ipairs(o) do
            local mom = 1
            for i = 1, n do
                mom = mom * v
                res[i] = res[i] + mom
            end
        end
        return tunpack(res)
    end; --}}}

    cmnt = function (o, n) --{{{ centered mnts (mean, variance, ...)
        local mean = 0
        for i = 1, #o do mean = mean + o[i] end
        mean = mean / #o
        local cvar = 0 -- centered variance
        for _, v in ipairs(o) do
            v = v - mean
            cvar = cvar + v * v
        end
        return mean, cvar
    end; --}}}

    property = function (o, rv) --{{{ TODO skewness, kertosis, ...
    end; --}}}
} -- }}}

-- ==================================================================== --
local stat = {
    api = class[sample].__index; -- random variable api
}

setmetatable(stat, {
    __metatable = "MIT license";
    __call = function (c, ...) return sample(...) end;
})

-- ==================================================================== --
-- distribution library (stochastic process)

stat.api.uniform = function (o, n) -- uniform distribution PRNG
    -- math.randomseed(os.time()) -- seed
    for i = 1, (n or #o) do o[i] = math.random() end
end

stat.api.gaussian = function (o, u, s) -- gaussian distribution
end

-- ==================================================================== --
-- demo
a = stat(10)
b = stat(10, 10, 10)
b:uniform()
c = stat(10, 10, 10, function (o, i) return (i - 1) / 1000 end)
-- c:uniform()
-- c:sort()
-- for i, v in ipairs(c) do print(i, v) end
-- for i, v in ipairs(c) do print(i, v) end
-- for i = 1000, 950, -1 do
--     print(#c, c:cmnt())
--     c[i] = nil
-- end
print(c:cmnt())
print(c:mnt(2))
print(c:range())
a = stat(2)
b = stat(2)
a[1], a[2] = 1, 1
b[1], b[2] = 1, 1
-- c = a & b
-- print(c[1], c[2], c[3])


for k, v in pairs(stat.api) do print(k, v) end

return stat
-- ==================================================================== --
-- vim:ts=4:sw=4:sts=4:et:fen:fdm=marker:fmr={{{,}}}:fdl=1

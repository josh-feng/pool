#!/usr/bin/env lua
-- probablity and statistical toolbox
-- ref:
--  - Wong, "Stochastic Processes in Engineering Systems"
--  - Hoel, Port, Stone,
--  - Doob, "Stochastic Processes", 1971
--  - Feller,
local class = require('pool')

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
        else -- TODO 0/1/...
            for i = 1, total do o[i] = 0 end
        end
    end; -- }}}

    -- ['>'] = function (o) end;

    { -- operators (cycle rule)
        __add = function (o1, o2) -- TODO
            local n1, n2 = #o1, #o2
            local n = class:new(o)
            if n1 >= n2 then
            else
            end
            return n
        end;

        __sub = function (o1, o2) -- TODO
        end;

        __mul = function (o1, o2) -- TODO
        end;

        __div = function (o1, o2) -- TODO
        end;

        __tostring = function (o) -- TODO dims/average/std.dev
            return o.dims and tconcat(o.dims, ':') or ''
        end;

        -- convolution
        -- regression / ...
    };

    -- member functions / statistics (sample)
    dup = function (o) -- duplicate {{{
        local n = o()
        for i = 1, #o do n[i] = o[i] end -- transfer the data
        return n
    end; -- }}}

    map = function (o, f) for i = 1, #o do o[i] = f(o, i) end end;

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
        cvar = cvar / (#o - 1)
        -- TODO kertosis
        return mean, cvar
    end; --}}}
} -- }}}

-- ==================================================================== --
local stat = {
    api = class[sample].__index; -- random variable api
}

setmetatable(stat, {
    __metatable = true;
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


return stat
-- ==================================================================== --
-- vim:ts=4:sw=4:sts=4:et:fen:fdm=marker:fmr={{{,}}}:fdl=1

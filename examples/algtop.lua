#!/usr/bin/env lua
-- algebraic topology module (under construcion)
-- ref:
--      May, ""
--      Harper, Greenberg ""
--      Bott, Tu, ""
--      Munker, ""
--      Whitehead, ""
--      https://nmd.pages.math.illinois.edu/computop/
-- +  sum
-- -  opposite orientation
-- *  product
-- /  mod
-- %
-- Cell (exterior algebra) {dx1, dx2, ..., dxn}
--  C0 = {i} == {}  -- index
--  C1 = {{0, 100}, r = false} == {0, {0, 100}, 0} -- dx
--      {0}
--      {100}
--  C2 = {{0, 100}, {0, 100}} -- dx, dy
--      {0  , {0  , 100}, r = true}
--      {100, {0  , 100}}
--      {{0  , 100},   0, r = true}
--      {{0  , 100}, 100}
--  C3 = {{0, 100}, {0, 100}, {0, 100}} -- dx, dy, dz
--      { 0      , {0, 100}, {0, 100}, r = true}
--      {    100 , {0, 100}, {0, 100}}
--      {{0, 100},  0      , {0, 100}, r = true}
--      {{0, 100},     100 , {0, 100}}
--      {{0, 100}, {0, 100},  0      , r = true}
--      {{0, 100}, {0, 100},     100 }
--  other examples:
--      3 * C1 = {{0, 300}}
--      -3 * C1 = {{0, 300}, r = true} -- NB orientation
--
-- n = 0 -> ø
--
-- n = 1 -> 2 pt
--
-- n = 2 -> 4 -> 4 * 2 pt
--          4
-- n = 3 -> 6 -> 6 * 4 -> 6 * 4 * 2 pt
--          12   24
-- n = 4 -> 8 -> 8 * 6 -> 8 * 6 * 4 -> 8 * 6 * 4 * 2 pt
--          24?
--
-- S = { // +-*/%
--    type simple/compound
--    C, b1, b2, ... // cell + boundary
--    C1, C2, C3 // compound
--    // TODO
--    // cell / complex -- 1 / n
--    // refine-boundary / mod (kernel) -- n / n
-- }
--
local class = require('pool')

local tinsert, tconcat = table.insert, table.concat
local abs, floor = math.abs, math.floor

local function cloneTbl (src) -- {{{
    local targ = {}
    for k, v in pairs(src) do
        targ[k] = type(v) == 'table' and cloneTbl(v) or v
    end
    return targ
end -- }}}

local function dupCell (c) -- {{{
    local d = {}
    for i = 1, #c do tinsert(d, c[i]) end
    return d
end -- }}}

local space = class { -- cell/complex
    b = false; -- boundary/refine/mod/surgery
    d = false; -- extends/parents +odd/-even

    ['<'] = function (o, cell, ext)
        if type(cell) == 'number' and type(ext) == 'table' then
            -- cell-space boundary index
            for _, v in ipairs(ext) do tinsert(o, v) end
            o[cell + ((cell % 2 == 0) and -1 or 1)] = o[cell]
            o.d = o.d or {}
            tinsert(o.d, cell)
            tinsert(o.d, ext)
            print(cell, tconcat(o, ':')) -- ext
        else
            if type(cell) == 'table' then -- cellspec (n1, n2, ...)
                for _, v in ipairs(cell) do
                    tinsert(o, 0)
                    tinsert(o, floor(abs(tonumber(v))) or 0) -- dx
                end -- {0, dx1; 0, dx2; 0, dx3; ...}
                -- o.d = o.d or {}
            end
        end
        o.b = o:bd() -- boundary table
    end;

    ['>'] = function (o)
    end;


    ['^'] = { -- algebra
        __add = function(o1, o2) -- +
        end;

        __sub = function(o1, o2) -- - inverse orient
        end;

        __mul = function(o1, o2) -- * product
        end;

        __div = function(o1, o2) -- / mod
        end;
    }
}

-- member function extension
local spaceAPI = class[space].__index

spaceAPI.im = function (o, b1, b2, ...) -- i: b1 -> b2 (include map) TODO
end

spaceAPI.ec = function (o, b1, i1, b2, i2) -- b1==b2 (eq class) TODO
end

spaceAPI.bd = function (o, idx) -- boundary operator
    if idx then return o.b and o.b[idx] end
    local bd = {}
    for i = 1, #o / 2 do
        if o[2 * i - 1] ~= o[2 * i] then
            tinsert(bd, space(2 * i - 1, o))
            tinsert(bd, space(2 * i    , o))
        end
    end
    -- join/seam boundary patches (id/mod)
    for i = 1, #o / 2 do
        for j = 1, #o / 2 do
            if j ~= i then
                o:ec(2 * i - 1, 1, 2 * j - 1, 2)
                o:ec(2 * i - 1, 1, 2 * j    , 2)
                o:ec(2 * i    , 1, 2 * j - 1, 2)
                o:ec(2 * i    , 1, 2 * j    , 2)
            end
        end
    end
    return bd
end

spaceAPI.join = function (o, b1, b2) -- boundary operator
    -- return o / (b1 + b2)
end

spaceAPI.j = function (o, b1, b2) -- join/ideal
    return b1 + b2
end

-- s1 = space({100, 200, 300})
s1 = space({100, 200})
-- print(#(s1.c))

-- s2 = space()
-- print(#(s2.c))

-- ====================================================================== --
return space
-- vim:ts=4:sw=4:sts=4:et:fen:fdm=marker:fmr={{{,}}}:fdl=1

local dmlib = {}

-- ;>========================================================
-- ;>===                    GLOBALS                     ===<;
-- ;>========================================================

--- Emulates the `case` structure from Pascal.
--- @param enumVal boolean
---@param results table
---@param elseVal any
function dmlib.case(enumVal, results, elseVal)
    for k,v in pairs(results) do if enumVal == k then return v end end
    return elseVal
end

--- Creates an enumeration.
---
--- Example:
--- `dangerLevels = Enum {"Normal","Warning", "Danger", "Critical"}`
function dmlib.enum(tbl)
    for i = 1, #tbl do local v = tbl[i] tbl[v] = i end
    return tbl
end


-- ;>========================================================
-- ;>===                     BASIC                      ===<;
-- ;>========================================================

--- Composes a list of functions and returns a function that sequentially evaluates them all.
function dmlib.pipeTbl(tbl)
    return function(x)
        local valIn = x
        local y
        for _, f in pairs(tbl) do
            y = f(valIn)
            valIn = y
        end
        return y
    end
end

--- Composes many functions and returns a function that sequentially evaluates them all.
function dmlib.pipe(...)
    return dmlib.pipeTbl({...})
end

--- Applies a function to all members of a list.
--- @param func function
---@param array table
function dmlib.map(func, array)
    local new_array = {}
    for i,v in pairs(array) do new_array[i] = func(v) end
    return new_array
end

--- Returns same value.
function dmlib.identity(x) return x end

-- ;>========================================================
-- ;>===                   COMPARISON                   ===<;
-- ;>========================================================

--- Ensures some value is at least...
function dmlib.forceMin(min) return function(x) return math.max(min, x) end end

--- Caps some value to at most...
function dmlib.forceMax(cap) return function (x) return math.min(x, cap) end end

--- Forces some value to never get outside some range.
function dmlib.forceRange(min, max)
    return function (x) return dmlib.pipe(dmlib.forceMax(max), dmlib.forceMin(min)) (x) end
end
--- Forces some value to be positive
dmlib.forcePositve = dmlib.forceMin(0)
--- Forces a value to be between [0, 1]
dmlib.forcePercent = dmlib.forceRange(0, 1)

--- Returns a function that returns a default value `val` if `x` is nil.
function dmlib.defaultVal(val) return function(x) if(x == nil) then return val else return x end end end
dmlib.defaultMult = dmlib.defaultVal(1)
dmlib.defaultBase = dmlib.defaultVal(0)

--- Returns a value only if some predicate is true. If not, returns `0`.
---
--- Use this when you expect to add this result to other things.
--- In Sandow++ it is used
function dmlib.boolBase(callback, predicate)
    return function(x)
        if predicate then return callback(x)
        else return 0
        end
    end
end

--- Multiplies a value only if some predicate is true. If not, returns the same value.
function dmlib.boolMultiplier(callback, predicate)
    return function(x)
        if predicate then return callback(x)
        else return x
        end
    end
end

--- Multiplies some <value> by <mult> if predicate is true.
function dmlib.boolMult(predicate, val, mult)
    if predicate then return val * mult
    else return val
    end
end

-- ;>========================================================
-- ;>===                      MATH                      ===<;
-- ;>========================================================

--- Creates an exponential function that adjusts a curve of some shape to two points.
---
    --- Example:
    ---
    ---              `f = expCurve(-2.3, {x=0, y=3}, {x=1, y=0.5})`
    ---
    ---              `f(0) -> 3`
---@param shape number
---@param p1 table
---@param p2 table
function dmlib.expCurve(shape, p1, p2)
    return function(x)
        local e = math.exp
        local b = shape
        local ebx1 = e(b * p1.x)
        local a = (p2.y - p1.y) / (e(b * p2.x) - ebx1)
        local c = p1.y - a * ebx1
        return a * e(b * x) + c
    end
end

--- Creates a linear function adjusted to two points.
---
    --- Example:
    ---
    ---              `f = linCurve({x=24, y=2}, {x=96, y=16})`
    ---
    ---              `f(24) -> 2`
    ---
    ---              `f(96) -> 16`
    ---
    ---              `f(0) -> -2.6666666666667`
---@param p1 table
---@param p2 table
function dmlib.linCurve(p1, p2)
    return function (x)
        local m = (p2.y - p1.y) / (p2.x - p1.x)
        return (m * (x - p1.x)) + p1.y
    end
end

-- ;>========================================================
-- ;>===                     STRING                     ===<;
-- ;>========================================================

--- Given a file name with path, returns the file name with extension
function dmlib.getFileName(f) return string.match(string.gsub(f, "\\", "/"), "^.+/(.+)$") end

-- Trimming functions gotten from:
-- https://rosettacode.org/wiki/Strip_whitespace_from_a_string/Top_and_tail#Lua

--- Trims leading blanks.
function dmlib.triml(s) return string.match(s, "^%s*(.+)") end
--- Trims trailing blanks.
function dmlib.trimr(s) return string.match(s, "(.-)%s*$") end
--- Trim right and left
function dmlib.trim(s) return string.match(s, "^%s*(.-)%s*$") end

function dmlib.floatToPercentStr(x) return string.format("%.2f%%", x * 100) end
function dmlib.printColor(c) return string.format("%.6X", c) end

return dmlib

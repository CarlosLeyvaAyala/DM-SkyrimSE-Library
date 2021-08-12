local dmlib = {}

-- ;>========================================================
-- ;>===                    GLOBALS                     ===<;
-- ;>========================================================

function dmlib.assign(to, from)
    for k, v in pairs(to) do
        if from[k] ~= nil then
            if type(v) == "table" then
                dmlib.assign(to[k], from[k])
            else
                to[k] = from[k]
            end
        end
    end
end

function dmlib.deepCopy(o, seen)
    seen = seen or {}
    if o == nil then return nil end
    if seen[o] then return seen[o] end

    local no
    if type(o) == 'table' then
        no = {}
        seen[o] = no

        for k, v in next, o, nil do
            no[dmlib.deepCopy(k, seen)] = dmlib.deepCopy(v, seen)
        end
    else -- number, string, boolean, etc
        no = o
    end
    return no
end

function dmlib.tableLen(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end


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

--- Used to watch values while in pipe.
function dmlib.logPipe(msg)
    return function (x)
        print(msg)
        return x
    end
end

function dmlib.curry(func, argument)
    return function(...)
        return func(argument, ...)
    end
end

function dmlib.curryLast(func, argument)
    return function(...)
        return func(..., argument)
    end
end

--- If a two argument function is called with one, curries the last one,
--- which is expected to be a fuction. If it's called with two arguments,
--- executes the function.
dmlib.makePipeable2 = _MakePipeable2

local function _MakePipeable2(func, arg1, arg2)
    if not arg2 then
        return dmlib.curryLast(func, arg1)
    else
        return func(arg1, arg2)
    end
end

--- Composes many functions and returns a function that sequentially evaluates them all.
---
--- composed = pipe(func1, func2... funcN)
---
--- composed = pipe({func1, func2... funcN})
function dmlib.pipe(...)
    local function pipeTbl(tbl)
        return function(x)
            local y = x
            for _, f in pairs(tbl) do
                y = f(y)
            end
            return y
        end
    end

    if type(...) == "table" then
       return pipeTbl(...)
    else
        return pipeTbl({...})
    end
end

--- Synonym for `dmlib.pipe`.
dmlib.compose = dmlib.pipe

function dmlib.range(start_i, end_i, step)
    if end_i == nil then
        end_i = start_i
        start_i = 1
    end
    step = step or 1
    local new_array = {}
    for i = start_i, end_i, step do
        table.insert(new_array, i)
    end
    return new_array
end

--- Applies a function to all members of a list.
---@param array table
--- @param func function
function dmlib.map(array, func)
    local function _map(a, f)
        local new_array = {}
        for i, v in pairs(a) do
            new_array[i] = f(v, i)
        end
        return new_array
    end
    return _MakePipeable2(_map, array, func)
end

function dmlib.filter(array, func)
    local function _filter(a, f)
        local new_array = {}
        for i, v in pairs(a) do
            if f(v, i) then new_array[i] = v end
        end
        return new_array
    end
    return _MakePipeable2(_filter, array, func)
end

function dmlib.reject(array, func)
    local function f(fun)
        return function (v, k) return not fun(v, k) end
    end
    if not func then
        return dmlib.filter(f(array))
    else
        return dmlib.filter(array, f(func))
    end
end

function dmlib.take(array, items)
    local function _take(a, itms)
        local new_array = {}
        local n = 1
        for i, v in pairs(a) do
            if n <= itms then new_array[i] = v
            else return new_array end
            n = n + 1
        end
        return new_array
    end
    return _MakePipeable2(_take, array, items)
end

--- Reduction function. Extracts the value from the first element in a `key = value` map.
function dmlib.extractValue(array)
    for _, v in pairs(array) do return v end
end

--- Does something to each member of the array. Called for its side effects.
---@param array table
--- @param func function
function dmlib.foreach(array, func)
    local function _foreach(a, f)
        for k, v in pairs(a) do f(v, k) end
        return a
    end
    return _MakePipeable2(_foreach, array, func)
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

--- Rounds a number to it's nearest integer.
function dmlib.round(n) return math.floor(n + 0.5) end

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

dmlib.fmt = string.format

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
function dmlib.intToHexLower(c) return string.format("%.x", c) end

return dmlib

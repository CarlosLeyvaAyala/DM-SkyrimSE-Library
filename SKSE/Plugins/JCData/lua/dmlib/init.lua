local dmlib = {}

-- ;>========================================================
-- ;>===                    GLOBALS                     ===<;
-- ;>========================================================

---Transforms the result table from a function to a `JMap`.
---This may be ***the most important function in this library***, since it lets you
---directly getting out to Skyrim tables created in Lua.
---@param func fun(): table
---@return fun(): JMap
function dmlib.toJMap(func)
  return function (...)
    return JMap.objectWithTable(func(...))
  end
end

--- Emulates the `case` structure from Pascal.
---
---Usage:
---```
--- x = case("value", {meh = y, value = x}, z)
---```
---@generic T, R
--- @param enumVal T
---@param results table<T, R>
---@param elseVal R
---@return R
function dmlib.case(enumVal, results, elseVal)
  for k,v in pairs(results) do
    if enumVal == k then return v end
  end
  return elseVal
end

---`If` statement as an expresion.
---@param condition boolean
---@generic T
---@param cTrue T
---@param cFalse T
---@return T
function dmlib.IfThen(condition, cTrue, cFalse)
  if condition then return cTrue
  else return cFalse end
end

--- Creates an enumeration.
---
--- Usage:
---```
--- dangerLevels = Enum {"Normal","Warning", "Danger", "Critical"}
--- lvl = dangerLevels.Normal
--- lvl -> 1
---```
---@param tbl table<integer, string>
---@return table<string, integer>
function dmlib.enum(tbl)
  for i = 1, #tbl do local v = tbl[i] tbl[v] = i end
  return tbl
end


-- ;>========================================================
-- ;>===                     TABLES                     ===<;
-- ;>========================================================

---Deep copies a value to another. Used to deal with JContainers limitation
---of not letting the allocation of new tables to get out to Skyrim.
---@generic T,V
---@param to T
---@param from V
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

---Completely copies one variable. Mostly used to copy entering values from Skyrim, so they don't get
---accidentally modified.
---@param o any Original variable
---@param seen table Optimization value. No need to call it from outside this function.
---@return any
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

---Returns the length of a table that has arbitrary keys.
---Made to deal with the fact that `#t` only works with tables that have integer indexes.
---@param t table<any, any>
---@return integer
function dmlib.tableLen(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

--- Forces a value to be a table.
function dmlib.forceTable(val)
  if type(val) == 'table' then
    return val
  else
    return {val}
  end
end

---Joins two tables using applying a function when keys are repeated on both tables.
---
---Usage:
---```
---t1 = {a=1, b=3}
---t2 = {a=3, c=4}
---join = function(v1: number, v2: number, _: string) return (v1 + v2) / 2 end
---t3 = joinTables(t1, t2, join)
---
---t3 -> {a=2, b=3, c=4}
---```
---@generic K, V
---@param t1 table<K, V>
---@param t2 table<K, V>
---@param onExistingKey fun(value1: V, value2: V, key: K)
---@return table<K, V>
function dmlib.joinTables(t1, t2, onExistingKey)
  local tr = dmlib.deepCopy(t1)
  for k, v2 in pairs(t2) do
    if tr[k] then
      tr[k] = onExistingKey(tr[k], v2, k)
    else
      tr[k] = v2
    end
  end
  return tr
end

function dmlib.keys(obj)
  local keys = {}
  for k,v in pairs(obj) do
    keys[#keys+1] = k
  end
  return keys
end

function dmlib.values(obj)
  local values = {}
  for k,v in pairs(obj) do
    values[#values+1] = v
  end
  return values
end

function dmlib.flatten(array)
  local all = {}

  for _, ele in pairs(array) do
    if type(ele) == "table" then
      local flattened_element = dmlib.flatten(ele)
      dmlib.foreach(flattened_element, function(e) all[#all+1] = e end)
    else
      all[#all+1] = ele
    end
  end
  return all
end

function dmlib.dropNils(table)
  local all = {}
  for _, v in pairs(table) do
    if (v) then all[#all+1] = v end
  end
  return all
end

function dmlib.isEmpty(obj)
  return next(obj) == nil
end

--- Reduction function. Extracts the value from the first element in a `key = value` map.
function dmlib.extractValue(array)
  for _, v in pairs(array) do return v end
end

-- ;>========================================================
-- ;>===             FUNCTIONAL PRIMITIVES              ===<;
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

--- If a two argument function is called with only one, curries the last one,
--- which is expected to be a fuction. If it's called with two arguments,
--- executes the function.
---@param func function
---@param arg1 any
---@param arg2 any
---@return function|any
local function _MakePipeable2(func, arg1, arg2)
  if not arg2 then
    return dmlib.curryLast(func, arg1)
  else
    return func(arg1, arg2)
  end
end

dmlib.makePipeable2 = _MakePipeable2

---@generic T
---@return fun(argument: T): T
--- Composes many functions and returns a function that sequentially evaluates them all, piping the argument.
---
---Usage:
---```
--- composed = pipe(func1, func2... funcN)
--- composed = pipe({func1, func2... funcN})
---```
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

dmlib.compose = dmlib.pipe

---@generic T
---@return fun(argument: T): T
---Sequentially applies many functions to some argument, without changing it.
---
---Usage:
---```
--- seq = sequence(func1, func2... funcN)
--- seq = sequence({func1, func2... funcN})
---```
function dmlib.sequence(...)
  local function seq(tbl)
    return function(x)
      for _, f in pairs(tbl) do f(x) end
      return x
    end
  end

  if type(...) == "table" then
    return seq(...)
  else
    return seq({...})
  end
end

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

--- Applies a function to all members of a list and returns a list with all those transformed elements.
---@generic K, V
---@alias curriedFunc fun(array: table): table
---@param array? table<K, V> Array to transform.
---@param func fun(v: V, k?: K): V Transformation function. Will be curried if `array` is not present.
---@return table|curriedFunc
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

function dmlib.reduce(list, accum, func)
  local function _reduce(l, a, f)
    for _, v in pairs(l) do
      a = f(a, v)
    end
    return a
  end
  if not func then
    func = accum
    accum = list
    return function(l1) return _reduce(l1, accum, func) end
  else
    return _reduce(list, accum, func)
  end
end

---Returns a table with only the elements that satisfy some predicate.
---@alias filter fun(value: any, key?: any): boolean
---@param array? table Array to filter.
---@param func filter Filtering predicate. Will be curried if `array` is not present.
---@return table|curriedFunc
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

---Returns a table with only the elements that **do not** satisfy some test.
---@param array? table Array to filter.
---@param func filter Filtering predicate. Will be curried if `array` is not present.
---@return table|curriedFunc
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

---Takes the first `n` elements in an array.
---@param array table
---@param n integer
---@return table|function
function dmlib.take(array, n)
  local function _take(a, itms)
    local new_array, m = {}, 1
    for k, v in pairs(a) do
        if m <= itms then new_array[k] = v
        else return new_array end
        m = m + 1
    end
    return new_array
  end
  return _MakePipeable2(_take, array, n)
end

---Skips the first `n` elements in an array.
---@param array table
---@param n integer
---@return table|function
function dmlib.skip(array, n)
  local function _skip(a, itms)
    local new_array, m = {}, 1
    for k, v in pairs(a) do
        if m > itms then new_array[k] = v end
        m = m + 1
    end
    return new_array
  end
  return _MakePipeable2(_skip, array, n)
end

---Returns `true` if at least one element in the array satisfies the predicate func.
---@generic V, K
---@param array? table<K,V>
---@param func fun(v: V, k: K): boolean
---@return boolean|fun(array: table<K,V>): boolean
function dmlib.any(array, func)
  local function _any(a, f)
    for k, v in pairs(dmlib.forceTable(a)) do
      if f(v, k) then return true, v, k end
    end
    return false
  end
  return _MakePipeable2(_any, array, func)
end

--- Does something to each member of the `array`. Called for its side effects.
---@param array table
--- @param func function
function dmlib.foreach(array, func)
  local function _foreach(a, f)
    for k, v in pairs(dmlib.forceTable(a)) do f(v, k) end
    return a
  end
  return _MakePipeable2(_foreach, array, func)
end

---Wraps a function. Equivalent to "decorating" it.
---@param func function
---@param wrapper function
---@return function
function dmlib.wrap(func, wrapper)
  return function(...)
    return wrapper(func, ...)
  end
end

--- Returns same value.
---@generic T
---@param x T
---@return T
function dmlib.identity(x) return x end

---Does some action on a whole `array` and returns the unmodified array. Called for its side effects.
---@generic T
---@param array T
---@param func fun(a: T): nil
---@return T|fun(array: T): T
function dmlib.tap(array, func)
  local function _tap(a, f)
    f(a)
    return a
  end
  return _MakePipeable2(_tap, array, func)
end

function dmlib.alt(f1, f2)
  return function(val)
    if val then return f1(val)
    else return f2(val)
    end
  end
end

function dmlib.alt2(test, f1, f2)
  return function(val)
    if test then return f1(val)
    else return f2(val)
    end
  end
end

-- ;>========================================================
-- ;>===                   COMPARISON                   ===<;
-- ;>========================================================

---Ensures some value is at least...
function dmlib.forceMin(min) return function(x) return math.max(min, x) end end

---Caps some value to at most...
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

function dmlib.inRange(x, lo, hi)
  return (x >= lo) and (x <= hi)
end

function dmlib.floatEquals(n1, n2, precision)
  precision = precision or 0.001
  return dmlib.inRange(n1, n2 - precision, n2 + precision)
end

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
--- Usage:
---```
---f = expCurve(-2.3, {x=0, y=3}, {x=1, y=0.5})
---f(0) -> 3
---```
---@alias funN2N fun(x: number): number
---@param shape number
---@param p1 table
---@param p2 table
---@return funN2N
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
--- Usage:
---```
---f = linCurve({x=24, y=2}, {x=96, y=16})
---f(24) -> 2
---f(96) -> 16
---f(0) -> -2.6666666666667
---```
---@param p1 table
---@param p2 table
---@return funN2N
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

--- Given a file name with path, returns the file name with extension.
function dmlib.getFileName(f) return string.match(string.gsub(f, "\\", "/"), "^.+/(.+)$") end

-- Trimming functions gotten from:
-- https://rosettacode.org/wiki/Strip_whitespace_from_a_string/Top_and_tail#Lua

--- Trims leading blanks.
function dmlib.triml(s) return string.match(s, "^%s*(.+)") end
--- Trims trailing blanks.
function dmlib.trimr(s) return string.match(s, "(.-)%s*$") end
--- Trim right and left
function dmlib.trim(s) return string.match(s, "^%s*(.-)%s*$") end

function dmlib.encloseStr(s, e1, e2)
    if not e2 then e2 = e1 end
    return e1 .. s .. e2
end

function dmlib.encloseSingleQuote(s) return dmlib.encloseStr(s, "'") end
function dmlib.encloseDoubleQuote(s) return dmlib.encloseStr(s, '"') end

function dmlib.reduceStr(accum, s, separator)
    return accum .. dmlib.IfThen(accum == '', '', separator) .. s
end

function dmlib.reduceComma(accum, s) return dmlib.reduceStr(accum, s, ',') end
function dmlib.reduceCommaPretty(accum, s) return dmlib.reduceStr(accum, s, ', ') end

function dmlib.floatToPercentStr(x) return string.format("%.2f%%", x * 100) end
function dmlib.intToHexLower(c) return string.format("%.x", c) end
function dmlib.intToHexUpper(c) return string.format("%.X", c) end
function dmlib.printColor(c) return string.format("%.6X", c) end

function dmlib.padZeros(x, n)
  n = n or 0
  return string.format(string.format("%%.%dd", n), x)
end

-- ;>========================================================
-- ;>===                     ACTOR                      ===<;
-- ;>========================================================
---@alias Actor table<string, any>

---Deep copies, transforms and returns an actor.
---@param actor Actor Actor to process.
---@param functions table<integer, function> Table with all functions to pipe.
---@return table<string, any>
function dmlib.processActor(actor, functions)
  local processed = dmlib.pipe(functions)(dmlib.deepCopy(actor))
  dmlib.assign(actor, processed)
  return actor
end

---Deep copies, transforms and returns any table.
---@param table table Table to process.
---@param functions table<integer, function> Table with all functions to pipe.
---@return table
dmlib.processTable = function(table, functions) return dmlib.processActor(table, functions) end

return dmlib

local dmlib = {}

-- ;>========================================================
-- ;>===                    GLOBALS                     ===<;
-- ;>========================================================

---@alias SkyrimBool
---|'0'
---|'1'

---Transforms a Lua table to a JMap.\
---
---This may be ***the most important function in this library***, since it lets you
---directly getting out tables created in Lua to Skyrim.
---
--- Useful for **up until JContainers (SE) v4.1.13**. Newer versions may have corrected
--- the implementation of `JMap.objectWithTable`, which is supposed to do this, but only
--- converts to a JMap the main table, not all nested tables, as this function actually does.
function dmlib.tableToJMap(t)
  local object = JMap.object()
  for k,v in pairs(t) do
    if type(v) == "table" then
      object[k] = dmlib.tableToJMap(v)
    else
      object[k] = v
    end
  end
  return object
end

function dmlib.filterMap(collection, predicate)
  return dmlib.tableToJMap(dmlib.filter(collection, predicate))
end

---Transforms the result table from a function to a `JMap`.
---@param func fun(): table
---@return fun(): JMap
function dmlib.toJMap(func)
  return function (...)
    return dmlib.tableToJMap(func(...))
  end
end

---`unpack` function seems not to be available in JContainers.
---
--- This is a hack that lets you get up until 20 items from a vararg table. \
--- Pray you will never need more than those.
---@param t table
---@return any
function dmlib.unpack20(t)
  return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20]
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

---;@Deprecated: Use `toJMap` instead.
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

---Returns the length of a table that has arbitrary keys.\
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
  for k, v in pairs(table) do
    if (v and k) then all[#all+1] = v end
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

function dmlib.Not(f) return function (...) return not f(...) end end

---Forces a multiple argument function to use only one.
---
---Sample usage:
---```
--- uP = l.unary(print)
--- uP("Only this will be printed", 2, 3, 4, 5)
---```
---@param f function
---@return function
function dmlib.unary(f) return function (arg) return f(arg) end end

--- Returns same value.
---@generic T
---@param x T
---@return T
function dmlib.identity(x) return x end

--- [`I` combinator](https://leanpub.com/javascriptallongesix/read#leanpub-auto-making-data-out-of-functions). Returns same value.
---@generic T
---@param x T
---@return T
dmlib.I = dmlib.identity

--- [`K` combinator](https://leanpub.com/javascriptallongesix/read#leanpub-auto-making-data-out-of-functions).\
--- Returns a function that accepts one parameter but ignores it and returns whatever you originally defined it with.
---@generic T, K
---@param x T
---@return fun(y: K): T
function dmlib.K(x) return function(y) return x end end

dmlib.first =dmlib.K
dmlib.second = dmlib.K(dmlib.I)

---Returns a fuction that, when its parameter exists, evaluates it to `f1`. Otherwise, `f2`.\
---This function is prefereable to `dmlib.IfThen` because that is _eager evaluation_ and this is _lazy_.
---@generic T, K
---@param f1 fun(val: T): K
---@param f2 fun(val: T): K
---@return fun(val: T): K
function dmlib.alt(f1, f2)
  return function(val)
    if val then return f1(val)
    else return f2(val)
    end
  end
end

---Returns a fuction that, a test is true, evaluates it to `f1`. Otherwise, `f2`.\
---This function is prefereable to `dmlib.IfThen` because that is _eager evaluation_ and this is _lazy_.
function dmlib.alt2(test, f1, f2)
  return function(...)
    if test then return f1(...)
    else return f2(...)
    end
  end
end

---Curries a function with all provided arguments. \
---Returns a function that only accepts one argument.
---
---Usage:
---```
---p = curryAll(print)(2, 3, 4)
---p(1) ==> 1, 2, 3, 4
---```
---@generic T
---@param f fun(...): T
---@return fun(x: any): T
function dmlib.curryAll(f)
  return function (...)
    local curried = {...}
    return function (x)
      return f(x, dmlib.unpack20(curried))
    end
  end
end

---```
---return x == y
---```
---@param x any
---@param y any
---@return boolean
function dmlib.equals(x, y) return x == y end

---```
---return x < y
---```
---@param x number
---@param y number
---@return boolean
function dmlib.lessThan(x, y) return x < y end

---Returns function that can evaluate wether it was provided with an specified number of arguments.
---
---Usage:
---```
---   hasNargs(lessThan, 2)(10) ==> true
---   hasNargs(lessThan, 2)(10, 20) ==> false
---   hasNargs(equals, 2)(10, 20) ==> true
---   hasNargs(equals, 4)(10, 20, 30, 40) ==> true
---```
---@param n integer Number of arguments to compare.
---@param comparison fun(x: integer, y: integer): boolean Comparison function.
---@return fun(...): boolean
function dmlib.hasNargs(comparison, n)
  return function (...)
    return comparison(#{...}, n)
  end
end

---If a function `f` has less than `n` arguments, curries it with all the known arguments.
---Else, returns the evaluated function.
---
---Usage:
---```
--  function add(x, y) return x + y end
--  pipedAdd = makePipeable(add, 2)
--  pipe(pipedAdd(20), pipedAdd(50))(30) ==> 100
--  pipedAdd(2,3) ==> 5
---```
---@generic T
---@param f fun(...):T Function thay **may** be curried depending on the number of arguments it is called with.
---@param nArgs integer Minimum number of arguments `f` must have. Else, it will be curried with provided arguments.
---@return fun(...):T|fun(x: any):T
function dmlib.makePipeable(f, nArgs)
  return function (...)
    if dmlib.hasNargs(dmlib.lessThan, nArgs)(...) then
      return dmlib.curryAll(f)(...)
    else
      return f(...)
    end
  end
end

---Flips the values on an array.
---
---Usage:
---```
---  flipArray({1, 2, 3}) ==> {3, 2, 1}
---```
---@param arr table
---@return table
function dmlib.flipArray(arr)
  local new, size = {}, #arr
  for i, v in ipairs(arr) do
    new[size - i + 1] = v
  end
  return new
end

---Flips the order of the arguments when evaluating a function.
---
---Usage:
---```
---   fP = flip(print)
---   fP(1, 2, 3, 4, 5) ==> 5, 4, 3, 2, 1
---   fP(10, 20) ==> 20, 10
---```
---@param f function
---@return function
function dmlib.flip(f)
  return function (...)
    return f(dmlib.unpack20(dmlib.flipArray({...})))
  end
end

---Converts a list of arguments to a table when evaluating a function.
---@param f function
---@return function
function dmlib.forceTableInput(f)
  return function(...)
    if type(...) == "table" then return f(...)
    else return f({...})
    end
  end
end

---If a function gets an invalid argument, returns `nil`. Else, evaluates function.
---
---Usage:
---```
---   add2 = function(x) return x + 2 end
---   maybe(add2)(3) ==> 5
---   maybe(add2)(nil) ==> nil
---```
---@param f function
---@return function
function dmlib.maybe(f)
  return function(arg)
    return dmlib.alt2(arg, f, dmlib.K(nil))(arg)
  end
end

---Executes a function only once. Returns `nil` otherwise.
---```
---   blindDate = once(function() return "Sure, what could go wrong?" end)
---   blindDate() ==> "Sure, what could go wrong?"
---   blindDate() ==> nil
---   blindDate() ==> nil
---```
---@param f function
---@return function
function dmlib.once(f)
  local done = false
  return function(...)
    if done then return nil
    else done = true return f(...)
    end
  end
end

--- Used to watch values while in pipe.
function dmlib.logPipe(msg)
  return function (x)
    print(msg)
    return x
  end
end

---Returns a function that applies some argument as it the first argument for `f`.
---@param f function
---@param argument any
---@return function
function dmlib.curry(f, argument)
  return function(...)
    return f(argument, ...)
  end
end

---;@Delete: Don't use. Better use `flip` and curry it.
---@param func any
---@param argument any
---@return function
function dmlib.curryLast(func, argument)
  return function(...)
    return func(..., argument)
  end
end

---@Delete: ***Don't use***. `MakePipeable` is better.
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

local function _reduce(l, a, f)
  for _, v in pairs(l) do
    a = f(a, v)
  end
  return a
end

---Applies a reducing function and returns just one value.
---@generic T, K
---@param l table<any, K> List to be reduced.
---@param a K Accumulator.
---@param f fun(accum: K, value: T): K Reduction function.
---@return T
dmlib.reduce = function (l, a, f) end
dmlib.reduce = dmlib.makePipeable(_reduce, 3)

local _pipe = function(fnList)
  return function(arg)
    return dmlib.reduce(fnList, arg, function(a, f) return f(a) end)
  end
end

---@generic T
---@param fnList table<integer, function>
---@return fun(argument: T): T
--- Composes many functions and returns a function that sequentially evaluates them all,
--- piping the argument.
---
---Usage:
---```
--- composed = pipe(func1, func2... funcN)
--- composed = pipe({func1, func2... funcN})
---```
dmlib.pipe = function(fnList) end
dmlib.pipe = function(...) end
dmlib.pipe = dmlib.forceTableInput(_pipe)
dmlib.compose = dmlib.pipe

local function _sequence(tbl)
  return function(x)
    for _, f in pairs(tbl) do f(x) end
    return x
  end
end

---Sequentially applies many functions to some argument, without changing it.
---
---Usage:
---```
--- seq = sequence(func1, func2... funcN)
--- seq = sequence({func1, func2... funcN})
---```
---@generic T
---@return fun(argument: T): T
dmlib.sequence = function(fnList) end
dmlib.sequence = function(...) end
dmlib.sequence = dmlib.forceTableInput(_sequence)

---Returns an array filled with numbers.
---@param start_i integer
---@param end_i integer
---@param step integer
---@return table
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

local function _map(a, f)
  local new_array = {}
  for i, v in pairs(a) do
    new_array[i] = f(v, i)
  end
  return new_array
end

--- Applies a function to all members of a list and returns a list with all those transformed elements.
---@generic K, V
---@alias curriedFunc fun(array: table): table
---@param a? table<K, V> Array to transform.
---@param f fun(v: V, k?: K): V Transformation function. Will be curried if `array` is not present.
---@return table
dmlib.map = function(a, f) end
dmlib.map = dmlib.makePipeable(_map, 2)

local function _buildKeys(a, f)
  local new_array = {}
  for i, v in pairs(a) do
    new_array[f(i, v)] = v
  end
  return new_array
end

---Transforms the keys from a table using `f` as a transformation function.
---
--- Usage
---```
---   buildKeys(l.range(3), function (index) return index * 3 end) ==> {[3] = 1, [6] = 2, [9] = 3 }
---   buildKeys(function (i, _) return "meter" .. tostring(i) end)(l.range(3) ==> { meter1 = 1, meter2 = 2, meter3 = 3 }
---```
---@param a? table
---@param f fun(index: any, value?: any): any
---@return table
dmlib.buildKeys = function (a, f) end
dmlib.buildKeys = dmlib.makePipeable(_buildKeys, 2)

local function _filter(a, f)
  local new_array = {}
  for i, v in pairs(a) do
    if f(v, i) then new_array[i] = v end
  end
  return new_array
end

---Returns a table with only the elements that satisfy some predicate.
---@alias filter fun(value: any, key?: any): boolean
---@param a? table Array to filter.
---@param f filter Filtering predicate. Will be curried if `array` is not present.
---@return table
dmlib.filter = function (a, f) end
dmlib.filter = dmlib.makePipeable(_filter, 2)

local function _firstIn(a, f)
  for i, v in pairs(a) do
    if f(v, i) then return v end
  end
  return nil
end

---Returns the first element that satisfy some predicate in some table; `nil` if there's no element. \
---This is an optimization of the `filter` function. Used when only one element is expected **at most**.
---@alias filter fun(value: any, key?: any): boolean
---@param a? table Array to filter.
---@param f filter Filtering predicate. Will be curried if `array` is not present.
---@return table
dmlib.firstIn = function (a, f) end
dmlib.firstIn = dmlib.makePipeable(_firstIn, 2)

local function _reject(array, func) return dmlib.filter(array, dmlib.Not(func)) end

---Returns a table with only the elements that **do not** satisfy some test.
---@param array? table Array to filter.
---@param func filter Filtering predicate. Will be curried if `array` is not present.
---@return table|curriedFunc
dmlib.reject = function (a, f) end
dmlib.reject = dmlib.makePipeable(_reject, 2)

local function _takeBase(a, itms, iterator, selector)
  local new_array, m = {}, 1
  for k, v in iterator(a) do
    -- print(k, "k", v, "v")
    if m <= itms then new_array[selector(k)(m)] = v
    else return new_array end
    m = m + 1
  end
  return new_array
end

local function _take(a, itms) return _takeBase(a, itms, pairs, dmlib.first) end
local function _takeA(a, itms) return _takeBase(a, itms, ipairs, dmlib.second) end

---Takes the first `n` elements in a table. \
---Use it only with key based tables. Unpredictable with index based arrays.
---@param table table
---@param n integer
---@return table|function
dmlib.take = function (table, n) end
dmlib.take = dmlib.makePipeable(_take, 2)

---Takes the first `n` elements in an array. \
---Use it only with index based tables. Unpredictable with key based arrays.
---@param array table
---@param n integer
---@return table|function
dmlib.takeA = function (array, n) end
dmlib.takeA = dmlib.makePipeable(_takeA, 2)

local function _skip(a, itms)
  local new_array, m = {}, 1
  for k, v in pairs(a) do
    if m > itms then new_array[k] = v end
    m = m + 1
  end
  return new_array
end

---Skips the first `n` elements in an array.
---@param array table
---@param n integer
---@return table|function
dmlib.skip = function (array, n) end
dmlib.skip = dmlib.makePipeable(_skip, 2)

local function _any(a, f)
  for k, v in pairs(dmlib.forceTable(a)) do
    if f(v, k) then return true, v, k end
  end
  return false
end
---Returns `true` if at least one element in the array satisfies the predicate func.
---@generic V, K
---@param array? table<K,V>
---@param func fun(v: V, k: K): boolean
---@return boolean|fun(array: table<K,V>): boolean
dmlib.any = function (array, func) end
dmlib.any = dmlib.makePipeable(_any, 2)

local function _foreach(a, f)
  for k, v in pairs(dmlib.forceTable(a)) do f(v, k) end
  return a
end
--- Does something to each member of the `array`. Called for its side effects.
---@param array table
--- @param func function
dmlib.foreach = function (array, func) end
dmlib.foreach = dmlib.makePipeable(_foreach, 2)

---Does some action on a whole `array` and returns the unmodified array. Called for its side effects.
---@generic T
---@param array? T
---@param func fun(a: T): nil
---@return T|fun(array: T): T
local function _tap(a, f)
  f(a)
  return a
end
dmlib.tap = dmlib.makePipeable(_tap, 2)

---Wraps a function. Equivalent to "decorating" it.
---@param func function
---@param wrapper function
---@return function
function dmlib.wrap(func, wrapper)
  return function(...)
    return wrapper(func, ...)
  end
end

-- ;>========================================================
-- ;>===                   COMPARISON                   ===<;
-- ;>========================================================

---Converts a Skyrim `bool` to a Lua `boolean`.
---@param val SkyrimBool
---@return boolean
function dmlib.SkyrimBool(val) return (val ~= nil) and (val == 1) end

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


---Creates a table from an array of numbers (usually generated with `range`).
---@param array table<integer, integer> Array of numbers to transform.
---@param indexGen fun(index:integer, value: integer): any Index transformation function.
---@param valGen fun(val: integer, key: any): any Value transformation function.
function dmlib.tableFromNumbers(array, indexGen, valGen)
  return dmlib.pipe(indexGen, valGen)(array)
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

---Appends a value to a string.
---@param str string
---@return fun(val: any): string
function dmlib.appendStr(str) return function (val) return str..tostring(val) end end

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

-- ;>========================================================
-- ;>===                      TIME                      ===<;
-- ;>========================================================

--- Game time is represented as percents of days. This is that ratio used for convertions.
---
--- **Understanding game time**:
--- ```
--- days == 2.0   ; Two full days
--- days == 0.5   ; Half a day
--- ```
local gamehourRatio = 1 / 24

-- Changes game time to human hours.
-- Sample usage:

-- ```
-- 48 <- ToRealHours(2.0)   ; Two full days
-- 12 <- ToRealHours(0.5)   ; Half a day
-- ```
function dmlib.ToHumanHours(x) return x / gamehourRatio end

--- Changes human hours to game time.
---
--- Sample usage:
--- ```
--- 2.0 <- ToGameHours(48)   ; Two full days
--- 0.5 <- ToGameHours(12)   ; Half a day
-- ```
function dmlib.ToGameHours(x) return x * gamehourRatio end

return dmlib

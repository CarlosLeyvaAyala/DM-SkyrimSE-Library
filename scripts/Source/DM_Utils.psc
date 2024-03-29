Scriptname DM_Utils Hidden

import StringUtil
Import Math
import JValue

;>========================================================
;>===                      MATH                      ===<;
;>========================================================

float Function Exp(float x) Global
    {e^x}
    return Pow(2.718282, x)
EndFunction

; Linear interpolation. Percent [0.0, 1.0]
float Function Lerp(float min, float max, float percent) Global
    Return ((max - min) * percent) + min
EndFunction

int function MaxI(int a, int b) Global
    if a > b
        Return a
    Else
        Return b
    EndIf
EndFunction

int Function MinI(int a, int b) Global
    if a < b
        Return a
    Else
        Return b
    EndIf
EndFunction

float function MaxF(float a, float b) Global
    if a > b
        Return a
    Else
        Return b
    EndIf
EndFunction

float Function MinF(float a, float b) Global
    if a < b
        Return a
    Else
        Return b
    EndIf
EndFunction

float Function EnsurePositiveF(float x) Global
    Return MaxF(x, 0)
EndFunction

float Function ConstrainF(float a, float aMin, float aMax) Global
    Return MinF(aMax, MaxF(a, aMin))
EndFunction

int Function Round(float x) Global
    int temp
    float dec
    If x > 0
        temp = Math.Floor(x)
        dec = x - temp
        if dec >= 0.5
            temp = temp + 1
        EndIf
    ElseIf x < 0
        temp = Math.Ceiling(x)
        dec = Math.abs(x - temp)
        if dec >= 0.5
            temp = temp - 1
        EndIf
    Else
        temp = 0
    EndIf

    Return temp
EndFunction

string Function FloatToStr(float x, int decimals = 2) Global
    If decimals < 1
        ; Delete the decimal point
        decimals = -1
    EndIf

    return Substring( x as string, 0, Find(x as string, ".", 0) + 1 + decimals )
EndFunction

; Decimal to percent
float Function ToPercent(float x) Global
    Return x * 100
EndFunction

; Decimal to percent
float Function FloatToPercent(float x) Global
    Return x * 100
EndFunction

; Percent to decimal
float Function FromPercent(float x) Global
    return x / 100
EndFunction

float Function PercentToFloat(float x) Global
    {Better naming}
    Return FromPercent(x)
EndFunction


;>========================================================
;>===                      TIME                      ===<;
;>========================================================

; Game time is represented as percents of days. This is that ratio used for convertions.
;
; ### Understanding game time
; ```
; days == 2.0   ; Two full days
; days == 0.5   ; Half a day
; ```
float Function GameHourRatio() Global
    return 1.0 / 24.0
endFunction

; Human readable alias for `Utility.GetCurrentGameTime()`.
; Returns time in game hours.
float Function Now() Global
    Return Utility.GetCurrentGameTime()
EndFunction

; Changes game time to human hours.
;
; #### Sample usage
; ```
; 48 <- ToRealHours(2.0)   ; Two full days
; 12 <- ToRealHours(0.5)   ; Half a day
; ```
float Function ToRealHours(float aVal) Global
    Return aVal / GameHourRatio()
EndFunction

; Changes human hours to game time.
;
; #### Sample usage
; ```
; 2.0 <- ToGameHours(48)   ; Two full days
; 0.5 <- ToGameHours(12)   ; Half a day
; ```
float Function ToGameHours(float aVal) Global
    Return aVal * GameHourRatio()
EndFunction

; Returns in **human hours** how much time has passed between two **game hours**.
float Function HourSpan(float then) Global
    Return ToRealHours(Now() - then)
EndFunction

;@Deprecated: Use Lua to format.
; Converts a float to hours.
string Function FloatToHour(float aH) Global
    int h = Floor(aH)
    int m = Floor((aH - h) * 60)
    Return PadZeros(h, 2) + ":" + PadZeros(m, 2)
EndFunction


;>========================================================
;>===                      MISC                      ===<;
;>========================================================

int Function GetEquippedArmor(Actor aAct)
    int result = JArray.object()
    int slot = 0x1
    Armor equipment
    While (slot <= 0x40000000)
      equipment = aAct.GetWornForm(slot) as Armor
      If equipment
        JArray.addForm(result, equipment)
      EndIf
      slot *= 2
    EndWhile
    return result
  EndFunction

  Function EquipByArray(Actor aAct, int array)
    int i = 0
    int n = JArray.count(array)
    Armor equipment
    While i < n
      equipment = JArray.getForm(array, i) as Armor
      If !aAct.IsEquipped(equipment)
        aAct.EquipItem(equipment, false, true)
      EndIf
      i += 1
    EndWhile
  EndFunction

; Saves a JContainers structure (JMap, JArray, etc) to a file in the user directory
; (usually {User}\Documents\My Games\Skyrim Special Edition\JCUser\\).
Function LuaDebugTable(int dataStruct, string fileName) Global
    JValue.writeToFile(dataStruct, JContainers.userDirectory() + "Lua debug - " + filename + ".json")
EndFunction

; Transforms a string value to string argument.
; Use with `LuaTable()`.
;
; Sample usage:
; ```
; string a = "String"
; LuaTable("function", Arg(a)) ; Evaluates to "return function("String")"
; ```
string Function Arg(string argument) Global
    return "\"" + argument + "\""
EndFunction

; Returns a table from Lua by evaluating some function `f` with up to 10 arguments.
; Optional arguments default to `nil`, so Lua can safely ignore them.
;
; ***Handle with care***. This function may not always be viable due to Skyrim's
; annoying and stupid tendency of changing string case to whatever it pleases.
int Function LuaTable(string f, string arg1 = "nil", string arg2 = "nil", string arg3 = "nil", string arg4 = "nil", string arg5 = "nil", string arg6 = "nil", string arg7 = "nil", string arg8 = "nil", string arg9 = "nil", string arg10 = "nil") Global
    ; string body = arg1+","+arg2+","+arg3+","+arg4+","+arg5+","+arg6+","+arg7+","+arg8+","+arg9+","+arg10
    ; string whole = " return "  + f + "(" + body + ")"
    ; string body = arg1+","+arg2+","+arg3+","+arg4+","+arg5+","+arg6+","+arg7+","+arg8+","+arg9+","+arg10
    string whole = _LuaCallingString(f, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
    return JValue.evalLuaObj(0, whole)
EndFunction

; Returns a string from Lua by evaluating some function `f` with up to 10 arguments.
; Optional arguments default to `nil`, so Lua can safely ignore them.
;
; ***Handle with care***. This function may not always be viable due to Skyrim's
; annoying and stupid tendency of changing string case to whatever it pleases.
string Function LuaStr(string f, string arg1 = "nil", string arg2 = "nil", string arg3 = "nil", string arg4 = "nil", string arg5 = "nil", string arg6 = "nil", string arg7 = "nil", string arg8 = "nil", string arg9 = "nil", string arg10 = "nil") Global
    string whole = _LuaCallingString(f, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
    return JValue.evalLuaStr(0, whole)
EndFunction

; Returns a string that can be used to call a Lua function.
; Internally used for functions that call Lua code, like `DM_Utils.LuaTable()`.
string Function _LuaCallingString(string f, string arg1 = "nil", string arg2 = "nil", string arg3 = "nil", string arg4 = "nil", string arg5 = "nil", string arg6 = "nil", string arg7 = "nil", string arg8 = "nil", string arg9 = "nil", string arg10 = "nil") Global
    string body = arg1+","+arg2+","+arg3+","+arg4+","+arg5+","+arg6+","+arg7+","+arg8+","+arg9+","+arg10
    string whole = " return "  + f + "(" + body + ")"
    return whole
EndFunction

;@Deprecated: Better call Lua equivalent.
; Same as doing`string.format(string.format("%%.%dd", n), x)` in Lua.
string Function PadZeros(int x, int n = 0) Global
    string r = x as string
    int m = n - GetLength(r)
    int i = 0
    While i < m
        r = "0" + r
        i += 1
    EndWhile
    Return r
EndFunction

; Searchs a string in an array of strings.
int Function IndexOfS(string[] aArray, string s) Global
    int n = aArray.length
    int i = 0
    While i < n
        If aArray[i] == s
            Return i
        EndIf
        i += 1
    EndWhile
    Return -1
EndFunction

; Binary search on a sorted array.
int Function IndexOfSBin(string[] aArray, string s) Global
    int n = aArray.length
    int l = 0
    int r = n - 1
    int m
    While (l <= r)
        m = Floor((l + r) / 2)
        If (aArray[m] < s)
            l = m + 1
        ElseIf (aArray[m] > s)
            r = m - 1
        Else
            return m
        EndIf
    EndWhile
    return -1
EndFunction

; Tries to find actor name at all costs.
; Skyrim seems to be too unreliable to get the name using only one method
string Function GetActorName(Actor aActor) Global
    string name = aActor.GetLeveledActorBase().GetName()
    If !name
        name = aActor.GetActorBase().GetName()
    EndIf
    If !name
        name = aActor.GetBaseObject().GetName()
    EndIf
    If !name
        name = aActor.GetName()
    EndIf
    return name
EndFunction

; Prints some color in hex format.
string Function ColorToStr(int color) Global
    return evalLuaStr(0, "return dmlib.printColor(" + color + ")")
EndFunction

; Prints integer in hex format.
string Function IntToHex(int color) Global
    return evalLuaStr(0, "return dmlib.printColor(" + color + ")")
EndFunction

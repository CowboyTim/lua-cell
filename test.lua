#!/usr/bin/lua

require("stringextra")
require("cell")
require("spe")


local test = 'aa'
local tist = 'bb'
local fnup = function(a) return a + 1 end
local tbltest = {}

glbvar = "aaabbb"


local function f(a,p,...) 
    local yyy = test
    local xxx = tist
    yyy = yyy .. "oo".. xxx
    if a > 5 then
        p = a * 8
    end
    for i=6,9,2 do
        p = a + p
    end
    local fn = function() return fnup(500) end
    local fn1 = function() return fnup(600) + 10 end
    local rfn = fn() + fn1()
    if p ~= nil then
        print("OK:",p)
    end
    if a == false then
        print("OK:",p)
    end
    if tbltest["uuu"] ~= nil then
        p = p - 1
        p = p / 10
        p = p % 556.6
    end
    if glbvar ~= nil then
        print("ok")
    end
    local lvltbl1 = {["yyy"]=5,56,78}
    local lvltbl2 = {"a1","b1"}
    for a1,b1 in pairs(lvltbl1) do
        print(a1,b1)
    end
    for i,a1 in pairs(lvltbl2) do
        print(i,a1)
    end
    return tostring(p)..yyy..tostring(rfn)
end
local str = "Ole Ola"
someglobal = 5555
someotherglobal = {["cccccc"]=88}
someotherglobal = {["cccccc"]={["aaa"]="Hello World"}}
local h = {"aaa",["cccccc"]={["bbb"]={["lll"]="uuu"}}}
local a = 7788
local function f()
    local b = a + 666666
    local c = h
    local k = "ccc"
    k = k .. k
    local kkk = test
    c = c[k].bbb.lll
    local l = someglobal
    l = l + someotherglobal[k]
    l = l .. someotherglobal.ccc.aaa
    local s = str .. tostring(b)
    local aa = {}
    aa["lll"] = h
    return b..c..tostring(l)..test, pack(someotherglobal)
end
--[[
local function f()
    return 12345
end
--]]

print(string.hex(string.dump(f)))

local a = cell.dump(f)
print(string.hex(a))

--[[
--local a = spe.spe_image_open("../cell/spe_simple")
local a = spe.init("./spe_runner")
print(a)
--for i=1,10000000 do
    local r = spe.run(a, f, 556)
    print(a)
    print('result:',r)
--end
--]]

local r = cell.run(a, f, 556)
print(a)
print('result:',r)


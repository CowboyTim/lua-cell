#!/usr/bin/lua

require("stringextra")
require("cell")
require("spe")

local a = spe.spe_image_open("../cell/spe_simple")

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
--[[
local a
local function f()
    a = 1
    return a
end
--]]
local function f()
    return 12345
end
print(string.hex(string.dump(f)))

local a = cell.dump(f)
print(string.hex(a))

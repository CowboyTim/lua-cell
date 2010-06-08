require("stringextra")
require("cell")

local test = 'aa'
local tist = 'bb'
local fnup = function(a) return a + 1 end


local function f(a,p,...) 
    local p
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
    local rfn = fn()
    if p ~= nil then
        print("OK:",p)
    end
    if a == false then
        print("OK:",p)
    end
    return tostring(p)..yyy..tostring(rfn)
end
print(string.hex(string.dump(f)))

local a = cell.dump(f)
print(string.hex(a))

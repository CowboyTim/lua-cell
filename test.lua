require("stringextra")
require("cell")

local test = 'aa'
local tist = 'bb'


local function f(a,p,...) 
    local p
    local yyy = test
    local xxx = tist
    yyy = yyy .. "oo".. xxx
    if a > 5 then
        p = a * 8
    end
    for i=6,9 do
        p = a + p
    end
    return tostring(p)..yyy
end
print(string.hex(string.dump(f)))

local a = cell.dump(f)
print(string.hex(a))

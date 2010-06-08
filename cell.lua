local C = {}

if _G["cell"] then
    return _G["cell"]
end
_G["cell"] = C


local dump   = string.dump
local ord    = string.byte
local substr = string.sub

require("stringextra")

local function get_bit(byte, bit)
    return byte % 2^(bit+1) >= 2^bit and 1 or 0
end

local function decode(str, i, size, endianness)
    local block = substr(str, i, i + size - 1)
    local sum = 0
    if endianness ~= 0 then
        for j = size, 1, -1 do
          sum = sum * 256 + ord(block, j)
        end
    else
        for j = 1, size, 1 do
          sum = sum * 256 + ord(block, j)
        end
    end
    return sum, i + size
end

C.dump = function(f)
    local s  = dump(f)
    print(string.hex(s), #(s))
    local v = {ord(s,5,12)}
    local header = {
        signature      = string.hex(substr(s, 1, 4)),
        luac_version   = v[1],
        luac_format    = v[2],
        endianness     = v[3],
        sizeof_int     = v[4],
        sizeof_size_t  = v[5],
        sizeof_inst    = v[6],
        sizeof_lnumber = v[7],
        lnumber_is_int = v[8]
    }

    local sum             , sp = decode(s, 13, header.sizeof_size_t, header.endianness)
    print("sum:",sum)
    header.source         , sp = substr(s, sp, sp+sum-2), sp + sum
    header.linedefined    , sp = decode(s, sp, header.sizeof_int, header.endianness)
    header.lastlinedefined, sp = decode(s, sp, header.sizeof_int, header.endianness)
    header.nups           , sp = ord(s,sp, sp), sp + 1
    header.nuparams       , sp = ord(s,sp, sp), sp + 1
    header.is_vararg      , sp = ord(s,sp, sp), sp + 1
    header.maxstacksize   , sp = ord(s,sp, sp), sp + 1

    for k,v in pairs(header) do
        print("k:",k,",v:",v)
    end
    local function_code_size, sp = decode(s, sp, header.sizeof_int, header.endianness) 
    print("function_code_size:", function_code_size)
    for i=1, function_code_size do
        local block = substr(s,sp,sp+header.sizeof_inst-1)
        print("bl:",#(block), string.hex(block))
        block = endianness and string.reverse(block) or block
        print("bl:",#(block), string.hex(block))
        local op = ord(block, 4)
        op = 
            get_bit(op,5) * 32 +
            get_bit(op,4) * 16 +
            get_bit(op,3) *  8 +
            get_bit(op,2) *  4 +
            get_bit(op,1) *  2 +
            get_bit(op,0)
        print("i:",i, "sp:", sp,"op:", op)
        sp = sp + header.sizeof_inst
    end
    return ''
end

return C

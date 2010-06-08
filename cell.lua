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

local function LoadInt(str, i, size, endianness)
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

local function LoadNumber(str, i, size, endianness)
    return substr(str, i, i+size-1), i+size
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

    local sum             , sp = LoadInt(s, 13, header.sizeof_size_t, header.endianness)
    print("sum:",sum)
    header.source         , sp = substr(s, sp, sp+sum-2), sp + sum
    header.linedefined    , sp = LoadInt(s, sp, header.sizeof_int, header.endianness)
    header.lastlinedefined, sp = LoadInt(s, sp, header.sizeof_int, header.endianness)
    header.nups           , sp = ord(s,sp, sp), sp + 1
    header.nuparams       , sp = ord(s,sp, sp), sp + 1
    header.is_vararg      , sp = ord(s,sp, sp), sp + 1
    header.maxstacksize   , sp = ord(s,sp, sp), sp + 1

    for k,v in pairs(header) do
        print("k:",k,",v:",v)
    end
    local function_code_size, sp = LoadInt(s, sp, header.sizeof_int, header.endianness) 
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
    print("sp:",sp,",sizetotal:",#(s))

    --[[
        LoadConstants
    --]]
    local nr_constants, sp = LoadInt(s, sp, header.sizeof_int, header.endianness) 
    print("nr_constants:", nr_constants)
    local t, value
    for i=1, nr_constants do
        print("loading constant nr:",i)
        t, sp = ord(s, sp), sp + 1
        print("constant nr:",i,",t:",t)
        if     t == 8 then  -- thread
        elseif t == 7 then  -- userdata
        elseif t == 6 then  -- function
        elseif t == 5 then  -- table
        elseif t == 4 then  -- string
            local strsize
            strsize, sp = LoadInt(s, sp, header.sizeof_size_t, header.endianness)
            value,     sp = substr(s, sp, sp+strsize-2), sp + strsize
        elseif t == 3 then  -- number
            value, sp = LoadNumber(s, sp, header.sizeof_lnumber, header.endianness)
        elseif t == 2 then  -- lightuserdata
        elseif t == 1 then  -- boolean
        elseif t == 0 then  -- nil
        end
        print("constant nr:",i,",t:",t,",v:",value)
    end
    return ''
end

return C

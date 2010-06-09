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
    local x = substr(str, i, i+size-1)
    x = endianness and string.reverse(x) or x
    local mantissa = ord(x, 7) % 16
    for i=6,1,-1 do 
        mantissa = mantissa * 256 + ord(x, i) 
    end
    local exponent = (ord(x, 8) % 128) * 16 + math.floor(ord(x, 7) / 16)
    if exponent == 0 then
        return 0, i + size 
    end
    mantissa = (math.ldexp(mantissa, -52) + 1) * (ord(x, 8) > 127 and -1 or 1)
    return math.ldexp(mantissa, exponent - 1023), i + size
end

local function LoadDebug(s, sp, header)
end

local function LoadFunction(s, sp, header)
    local LoadInt = function(s, sp)
        return LoadInt(s, sp, header.sizeof_int, header.endianness)
    end

    local header_size, fheader = 0, {}
    header_size            , sp = LoadInt(s, sp)
    fheader.source         , sp = substr(s, sp, sp+header_size-2), sp + header_size
    fheader.linedefined    , sp = LoadInt(s, sp)
    fheader.lastlinedefined, sp = LoadInt(s, sp)
    fheader.nups           , sp = ord(s,sp, sp), sp + 1
    fheader.nuparams       , sp = ord(s,sp, sp), sp + 1
    fheader.is_vararg      , sp = ord(s,sp, sp), sp + 1
    fheader.maxstacksize   , sp = ord(s,sp, sp), sp + 1

    local print = function (...) print(fheader.source, unpack(arg)) end 

    for k,v in pairs(fheader) do
        print("fheader k:",k,",v:",v)
    end

    --[[
        LoadCode
    --]]
    local function_code_size, sp = LoadInt(s, sp) 
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

    --[[
        LoadConstants
    --]]
    local nr_constants, sp = LoadInt(s, sp) 
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
            strsize, sp = LoadInt(s, sp)
            value,     sp = substr(s, sp, sp+strsize-2), sp + strsize
        elseif t == 3 then  -- number
            value, sp = LoadNumber(s, sp, header.sizeof_lnumber, header.endianness)
        elseif t == 2 then  -- lightuserdata
        elseif t == 1 then  -- boolean
            value, sp = ord(s, sp) ~= 0, sp + 1
        elseif t == 0 then  -- nil
            value = nil
        end
        print("constant nr:",i,",t:",t,",v:",value)
    end

    --[[
        LoadFunctions
    --]]
    local nr_functions, sp = LoadInt(s, sp) 
    print("nr_functions:", nr_functions)
    for i=1, nr_functions do
        print("loading function nr:",i)
        local f
        f, sp = LoadFunction(s, sp, header)
    end

    --[[
        LoadDebug
    --]]

    --lines
    fheader.sizelineinfo, sp = LoadInt(s, sp)
    for i=1,fheader.sizelineinfo do
        local lineinfo
        lineinfo, sp = LoadInt(s, sp)
        print("lineinfo:", lineinfo)
    end
    
    -- local vars
    fheader.sizelocvars,  sp = LoadInt(s, sp)
    for i=1,fheader.sizelocvars do
        local varname, startpc, endpc, strsize
        strsize, sp = LoadInt(s, sp)
        varname, sp = substr(s, sp, sp+strsize-2), sp + strsize
        startpc, sp = LoadInt(s, sp)
        endpc,   sp = LoadInt(s, sp)
        print("varname:", varname, ",startpc:", startpc, ",endpc:", endpc)
    end

    -- upvalues
    fheader.sizeupvalues, sp = LoadInt(s, sp)
    for i=1,fheader.sizeupvalues do
        local strsize, str
        strsize, sp = LoadInt(s, sp)
        str,     sp = substr(s, sp, sp+strsize-2), sp + strsize
        print("upvalue:", str)
    end

    return '', sp
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
    for k,v in pairs(header) do
        print("k:",k,",v:",v)
    end

    local f, sp = LoadFunction(s, 13, header)

    print("sp:",sp,",sizetotal:",#(s))
    return f
end


return C

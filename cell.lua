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

local iABC  = 1
local iABx  = 2
local iAsBx = 3

local opcodes = {
    [0]= -- else the LUA array starts at index 1
    {  iABC, function(state, a) end },  -- MOVE
    {  iABx, function(state, a) end },  -- LOADK
    {  iABC, function(state, a) end },  -- LOADBOOL
    {  iABC, function(state, a) end },  -- LOADNIL
    {  iABC, function(state, a) end },  -- GETUPVAL
    {  iABx, function(state, a) end },  -- GETGLOBAL
    {  iABC, function(state, a) end },  -- GETTABLE
    {  iABx, function(state, a) end },  -- SETGLOBAL
    {  iABC, function(state, a) end },  -- SETUPVAL
    {  iABC, function(state, a) end },  -- SETTABLE
    {  iABC, function(state, a) end },  -- NEWTABLE
    {  iABC, function(state, a) end },  -- SELF
    {  iABC, function(state, a) end },  -- ADD
    {  iABC, function(state, a) end },  -- SUB
    {  iABC, function(state, a) end },  -- MUL
    {  iABC, function(state, a) end },  -- DIV
    {  iABC, function(state, a) end },  -- MOD
    {  iABC, function(state, a) end },  -- POW
    {  iABC, function(state, a) end },  -- UNM
    {  iABC, function(state, a) end },  -- NOT
    {  iABC, function(state, a) end },  -- LEN
    {  iABC, function(state, a) end },  -- CONCAT
    { iAsBx, function(state, a) end },  -- JMP
    {  iABC, function(state, a) end },  -- EQ
    {  iABC, function(state, a) end },  -- LT
    {  iABC, function(state, a) end },  -- LE
    {  iABC, function(state, a) end },  -- TEST
    {  iABC, function(state, a) end },  -- TESTSET
    {  iABC, function(state, a) end },  -- CALL
    {  iABC, function(state, a) end },  -- TAILCALL
    {  iABC, function(state, a) end },  -- RETURN
    { iAsBx, function(state, a) end },  -- FORLOOP
    { iAsBx, function(state, a) end },  -- FORPREP
    {  iABC, function(state, a) end },  -- TFORLOOP
    {  iABC, function(state, a) end },  -- SETLIST
    {  iABC, function(state, a) end },  -- CLOSE
    {  iABx, function(state, a) end },  -- CLOSURE
    {  iABC, function(state, a) end },  -- VARARG
}

local function LoadFunction(s, sp, header)
    local LoadInt = function(s, sp, size)
        return LoadInt(s, sp, size or header.sizeof_int, header.endianness)
    end
    local LoadChar = function(s, sp)
        return ord(s, sp), sp + 1
    end
    local LoadString = function(s, sp)
        local strsize, sp = LoadInt(s, sp, header.sizeof_size_t)
        return substr(s, sp, sp + strsize - 2), sp + strsize 
    end

    local fheader = {}
    fheader.source         , sp = LoadString(s, sp)
    fheader.linedefined    , sp = LoadInt(s, sp)
    fheader.lastlinedefined, sp = LoadInt(s, sp)
    fheader.nups           , sp = LoadChar(s, sp)
    fheader.nuparams       , sp = LoadChar(s, sp)
    fheader.is_vararg      , sp = LoadChar(s, sp)
    fheader.maxstacksize   , sp = LoadChar(s, sp)

    local print = function (...) 
        print((#(fheader.source) > 1 and fheader.source or "<tmp>").."::",unpack(arg)) 
    end 

    for k,v in pairs(fheader) do
        print("fheader k:",k,",v:",v)
    end

    local nr_opcodes, nr_constants, nr_functions
    local state = {}

    --[[
        LoadCode
    --]]
    nr_opcodes, sp = LoadInt(s, sp) 
    print("nr_opcodes:", nr_opcodes)
    for i=1, nr_opcodes do
        local opcode
        opcode, sp = LoadInt(s, sp, header.sizeof_inst)
        local a = math.floor(opcode/2^24)
        local code = opcode % 64
        local b, c
        if     opcodes[code][1] == iABC  then
            b = (math.floor(opcode / 2^(6+9)))%(2^9)
            c = (math.floor(opcode / 2^6))%(2^9)
        elseif opcodes[code][1] == iABx  then
            b = (math.floor(opcode / 2^6))%(2^18)
        elseif opcodes[code][1] == iAsBx then
            b = (math.floor(opcode / 2^6))%(2^18)
        end
        print("opcode, sp:",string.hex(substr(s, sp-header.sizeof_inst, sp-1)),
              "i:", i, "32bits:", opcode, "opcode:", code,
              "a:", a, ",b:", b, ",c:", c)
        opcodes[code][2](state, a, b, c)
    end

    --[[
        LoadConstants
    --]]
    nr_constants, sp = LoadInt(s, sp) 
    print("nr_constants:", nr_constants)
    local t, value
    for i=1, nr_constants do
        print("loading constant nr:",i)
        t, sp = LoadChar(s, sp)
        print("constant nr:",i,",t:",t)
        if     t == 8 then  -- thread
        elseif t == 7 then  -- userdata
        elseif t == 6 then  -- function
        elseif t == 5 then  -- table
        elseif t == 4 then  -- string
            value, sp = LoadString(s, sp)
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
    nr_functions, sp = LoadInt(s, sp) 
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
        local varname, startpc, endpc
        varname, sp = LoadString(s, sp)
        startpc, sp = LoadInt(s, sp)
        endpc,   sp = LoadInt(s, sp)
        print("varname:", varname, ",startpc:", startpc, ",endpc:", endpc)
    end

    -- upvalues
    fheader.sizeupvalues, sp = LoadInt(s, sp)
    for i=1,fheader.sizeupvalues do
        local str
        str, sp = LoadString(s, sp)
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

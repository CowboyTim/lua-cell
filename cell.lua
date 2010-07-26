if _G["cell"] ~= nil then
    return _G["cell"]
end

local C = {}

_G["cell"] = C

require("spe")
require("stringextra")

local dump   = string.dump
local ord    = string.byte
local substr = string.sub
local push   = table.insert


local function get_bit(byte, bit)
    return byte % 2^(bit+1) >= 2^bit and 1 or 0
end

local function LoadInt(str, i, size, endianness)
    local x = substr(str, i, i+size-1)
    x = endianness and string.reverse(x) or x
    print("LoadInt, i:",i,",size:",size,string.hex(x))
    local sum = 0
    for j = size, 1, -1 do
        sum = sum * 256 + ord(x, j)
    end
    return sum, i + size
end

local function LoadNumber(str, i, size, endianness)
    local x = substr(str, i, i+size-1)
    x = endianness and string.reverse(x) or x
    print("LoadNumber, i:",i,",size:",size,string.hex(x))
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


function op_move     (state, constants, a, b, c) end
function op_loadk    (state, constants, a, b)    end
function op_loadbool (state, constants, a, b, c) end
function op_loadnil  (state, constants, a, b, c) end
function op_getupval (state, constants, a, b, c) end
function op_getglobal(state, constants, a, b)    end
function op_gettable (state, constants, a, b, c) end
function op_setglobal(state, constants, a, b)    end
function op_setupval (state, constants, a, b, c) end
function op_settable (state, constants, a, b, c) end
function op_newtable (state, constants, a, b, c) end
function op_self     (state, constants, a, b, c) end
function op_add      (state, constants, a, b, c) end
function op_sub      (state, constants, a, b, c) end
function op_mul      (state, constants, a, b, c) end
function op_div      (state, constants, a, b, c) end
function op_mod      (state, constants, a, b, c) end
function op_pow      (state, constants, a, b, c) end
function op_unm      (state, constants, a, b, c) end
function op_not      (state, constants, a, b, c) end
function op_len      (state, constants, a, b, c) end
function op_concat   (state, constants, a, b, c) end
function op_jmp      (state, constants, a, b)    end
function op_eq       (state, constants, a, b, c) end
function op_lt       (state, constants, a, b, c) end
function op_le       (state, constants, a, b, c) end
function op_test     (state, constants, a, b, c) end
function op_testset  (state, constants, a, b, c) end
function op_call     (state, constants, a, b, c) end
function op_tailcall (state, constants, a, b, c) end
function op_return   (state, constants, a, b, c) end
function op_forloop  (state, constants, a, b)    end
function op_forprep  (state, constants, a, b)    end
function op_tforloop (state, constants, a, b, c) end
function op_setlist  (state, constants, a, b, c) end
function op_close    (state, constants, a, b, c) end
function op_closure  (state, constants, a, b)    end
function op_vararg   (state, constants, a, b, c) end

local opcodes = {
    [0]= -- else the LUA array starts at index 1
    {  iABC, op_move      },  -- MOVE
    {  iABx, op_loadk     },  -- LOADK
    {  iABC, op_loadbool  },  -- LOADBOOL
    {  iABC, op_loadnil   },  -- LOADNIL
    {  iABC, op_getupval  },  -- GETUPVAL
    {  iABx, op_getglobal },  -- GETGLOBAL
    {  iABC, op_gettable  },  -- GETTABLE
    {  iABx, op_setglobal },  -- SETGLOBAL
    {  iABC, op_setupval  },  -- SETUPVAL
    {  iABC, op_settable  },  -- SETTABLE
    {  iABC, op_newtable  },  -- NEWTABLE
    {  iABC, op_self      },  -- SELF
    {  iABC, op_add       },  -- ADD
    {  iABC, op_sub       },  -- SUB
    {  iABC, op_mul       },  -- MUL
    {  iABC, op_div       },  -- DIV
    {  iABC, op_mod       },  -- MOD
    {  iABC, op_pow       },  -- POW
    {  iABC, op_unm       },  -- UNM
    {  iABC, op_not       },  -- NOT
    {  iABC, op_len       },  -- LEN
    {  iABC, op_concat    },  -- CONCAT
    { iAsBx, op_jmp       },  -- JMP
    {  iABC, op_eq        },  -- EQ
    {  iABC, op_lt        },  -- LT
    {  iABC, op_le        },  -- LE
    {  iABC, op_test      },  -- TEST
    {  iABC, op_testset   },  -- TESTSET
    {  iABC, op_call      },  -- CALL
    {  iABC, op_tailcall  },  -- TAILCALL
    {  iABC, op_return    },  -- RETURN
    { iAsBx, op_forloop   },  -- FORLOOP
    { iAsBx, op_forprep   },  -- FORPREP
    {  iABC, op_tforloop  },  -- TFORLOOP
    {  iABC, op_setlist   },  -- SETLIST
    {  iABC, op_close     },  -- CLOSE
    {  iABx, op_closure   },  -- CLOSURE
    {  iABC, op_vararg    },  -- VARARG
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

    -- save *here*: this is the start of the opcodes section
    local orig_sp = sp
    nr_opcodes, sp = LoadInt(s, sp)

    --[[
        LoadConstants
    --]]

    -- jump to the start of the constants section
    sp = sp + nr_opcodes*header.sizeof_int
    nr_constants, sp = LoadInt(s, sp)
    print("nr_constants:", nr_constants)
    local constants = {}
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
        push(constants, value)
    end

    local state = {}

    --[[
        LoadCode
    --]]

    -- back to the start of the opcodes section
    sp, orig_sp = orig_sp, sp
    nr_opcodes, sp = LoadInt(s, sp) 
    print("nr_opcodes:", nr_opcodes)
    local opc = {}
    for i=1, nr_opcodes do
        local opcode
        opcode, sp = LoadInt(s, sp, header.sizeof_inst)
        local code = opcode % (2^6)
        local a = math.floor(opcode/2^6)%(2^8)
        local b, c
        if     opcodes[code][1] == iABC  then
            print("iABC!!")
            c = (math.floor(opcode / 2^(6+8)))%(2^9)
            b = (math.floor(opcode / 2^(6+8+9)))%(2^9)
        elseif opcodes[code][1] == iABx  then
            print("iABx!!")
            --b = (math.floor(opcode / 2^(6+8)))%(2^(9+9))
            b = math.floor(opcode / 2^(6+8))
        elseif opcodes[code][1] == iAsBx then
            print("iAsBx!!")
            --b = (math.floor(opcode / 2^(6+8)))%(2^(9+9))
            b = math.floor(opcode / 2^(6+8))
        end
        print("opcode",
              "i:", i, "32bits:", opcode, "opcode:", code,
              "a:"..a..",b:"..b..",c:"..(c or '<nop>'))
        opcodes[code][2](state, constants, a, b, c)
        push(opc, {code, a, b, c})
    end

    -- back to the end of the constants section
    sp = orig_sp

    --[[
        LoadFunctions
    --]]
    nr_functions, sp = LoadInt(s, sp) 
    print("nr_functions:", nr_functions)
    local functions = {}
    for i=1, nr_functions do
        print("loading function nr:",i)
        local f
        f, sp = LoadFunction(s, sp, header)
        push(functions, f)
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
    local ups = {}
    for i=1,fheader.sizeupvalues do
        local str
        str, sp = LoadString(s, sp)
        print("upvalue:", str)
        push(ups, str)
    end

    return {
        ["constants"] = constants,
        ["opcodes"]   = opc,
        ["functions"] = functions,
        ["upvalues"]  = ups,
    }, sp
end

function C:new(f)
    local s = dump(f)
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

    local fobj, sp = LoadFunction(s, 13, header)

    setmetatable(fobj, self)
    self.__index = self
    fobj.header   = header
    fobj.f        = f
    fobj.fstr     = s

    return fobj
end

function C:dump(f)
    return self.fstr
end

function C:run(f)
    local spe_c = spe.init("./spe_runner")
    local op, ra, rb = spe.spe_out_intr_mbox_read(spe_c, 3)
    while op ~= nil do
        print(op, ra, rb)

        if op == 999 then
            local r = spe.spe_out_intr_mbox_read(spe_c, 2)
            break
        end

        local v
        if     op == 4 then -- OP_GETUPVAL
            v = 8877
        elseif op == 5 then -- OP_GETGLOBAL
            local k = self.constants[ra+1]
            print("OP_GETGLOBAL", k)
            v = _G[k]
        end
        spe.spe_in_mbox_write(spe_c, v);

        op, ra, rb = spe.spe_out_intr_mbox_read(spe_c, 3)
    end
    spe.destroy(spe_c)
    return r
end

return C

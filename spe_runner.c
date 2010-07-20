#include <spu_mfcio.h>

#define LUA_LIB
#include "lua.h"
#include "lopcodes.h"
#include "lauxlib.h"

int main(unsigned long long spe, unsigned long long argp, unsigned long long envp) {
    lua_State *L = (lua_State *)&argp;
    int i, j;
    {
        /*  opcode: 4 (GETUPVAL)   a:0,b:0,c:0     */
        spu_write_out_intr_mbox(OP_GETUPVAL);
        spu_write_out_intr_mbox(0);
        i = spu_read_in_mbox();
        fprintf(stderr, "upval 0: %d\n", i);

        /*  opcode: 12 (ADD)       a:0,b:0,c:256   */  
        i = i + 10;

        /*  opcode: 4 (GETUPVAL)   a:1,b:2,c:0     */
        spu_write_out_intr_mbox(OP_GETUPVAL);
        spu_write_out_intr_mbox(1);
        j = spu_read_in_mbox();
        fprintf(stderr, "upval 2: %d\n", j);

        /*  opcode: 1 (LOADK)      a:2,b:1,c:<nop> */
        /*  opcode: 6 (GETTABLE)   a:1,b:1,c:2     */
        /*  opcode: 5 (GETGLOBAL)  a:3,b:2,c:<nop> */
        spu_write_out_intr_mbox(OP_GETGLOBAL);
        spu_write_out_intr_mbox(1);
        j = spu_read_in_mbox();
    }
    spu_write_out_intr_mbox(999);
    spu_write_out_intr_mbox(0);
    spu_write_out_intr_mbox(LUA_TNUMBER);
    spu_write_out_intr_mbox(i);
    return 0;
}

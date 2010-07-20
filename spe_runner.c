#include <spu_mfcio.h>

#define LUA_LIB
#include "lua.h"
#include "lopcodes.h"
#include "lauxlib.h"

int main(unsigned long long spe, unsigned long long argp, unsigned long long envp) {
    lua_State *L = (lua_State *)&argp;
    int r0, r1, r2, r3, r4;
    {
        /*  opcode: 4 (GETUPVAL)   a:0,b:0,c:0     */
        spu_write_out_intr_mbox(OP_GETUPVAL);
        spu_write_out_intr_mbox(0);
        spu_write_out_intr_mbox(0);
        spu_write_out_intr_mbox(0);
        r0 = spu_read_in_mbox();
        fprintf(stderr, "upval 0: %d\n", r0);

        /*  opcode: 12 (ADD)       a:0,b:0,c:256   */  
        r0 = r0 + 10;

        /*  opcode: 4 (GETUPVAL)   a:1,b:1,c:0     */
        spu_write_out_intr_mbox(OP_GETUPVAL);
        spu_write_out_intr_mbox(1);
        spu_write_out_intr_mbox(0);
        spu_write_out_intr_mbox(0);
        r1 = spu_read_in_mbox();
        fprintf(stderr, "upval 1: %d\n", r1);

        /*  opcode: 1 (LOADK)      a:2,b:1,c:<nop> */

        /*  opcode: 4 (GETUPVAL)   a:2,b:2,c:0     */
        spu_write_out_intr_mbox(OP_GETUPVAL);
        spu_write_out_intr_mbox(2);
        spu_write_out_intr_mbox(0);
        spu_write_out_intr_mbox(0);
        r2 = spu_read_in_mbox();
        fprintf(stderr, "upval 2: %d\n", r2);

        /*  opcode: 6 (GETTABLE)   a:1,b:1,c:2     */
        /*  opcode: 5 (GETGLOBAL)  a:4,b:2,c:<nop> */
        spu_write_out_intr_mbox(OP_GETGLOBAL);
        spu_write_out_intr_mbox(1);
        spu_write_out_intr_mbox(0);
        spu_write_out_intr_mbox(0);
        r4 = spu_read_in_mbox();
    }
    spu_write_out_intr_mbox(999);
    spu_write_out_intr_mbox(0);
    spu_write_out_intr_mbox(0);
    spu_write_out_intr_mbox(0);
    spu_write_out_intr_mbox(LUA_TNUMBER);
    spu_write_out_intr_mbox(r0);
    spu_write_out_intr_mbox(0);
    spu_write_out_intr_mbox(0);
    return 0;
}

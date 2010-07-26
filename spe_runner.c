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
        r0 = spu_read_in_mbox();
        fprintf(stderr, "upval 0: %d\n", r0);

        /*  opcode: 12 (ADD)       a:0,b:0,c:256   */  
        r0 = r0 + 10;

        /*  opcode: 4 (GETUPVAL)   a:1,b:1,c:0     */
        spu_write_out_intr_mbox(OP_GETUPVAL);
        spu_write_out_intr_mbox(1);
        spu_write_out_intr_mbox(0);
        r1 = spu_read_in_mbox();
        fprintf(stderr, "upval 1: %d\n", r1);

        /*  opcode: 1 (LOADK)      a:2,b:1,c:<nop> */
        //r2 = "ccc";

        /*  opcode: 1 (MOVE)       a:3,b:2,c:0     */
        //r3 = r2;

        /*  opcode: 1 (MOVE)       a:4,b:2,c:0     */
        //r4 = r2;

        /*  opcode: 1 (CONCAT)     a:2,b:3,c:4     */
        //r2 = r3 .. r4;

        /*  opcode: 4 (GETUPVAL)   a:3,b:2,c:0     */
        spu_write_out_intr_mbox(OP_GETUPVAL);
        spu_write_out_intr_mbox(2);
        spu_write_out_intr_mbox(0);
        r3 = spu_read_in_mbox();
        fprintf(stderr, "upval 2: %d\n", r2);

        /*  opcode: 6 (GETTABLE)   a:4,b:1,c:2     */
        spu_write_out_intr_mbox(OP_GETTABLE);
        spu_write_out_intr_mbox(r1);
        spu_write_out_intr_mbox(r2);
        r4 = spu_read_in_mbox();

        /*  opcode: 6 (GETTABLE)   a:4,b:4,c:258   */
        spu_write_out_intr_mbox(OP_GETTABLE);
        spu_write_out_intr_mbox(r4);
        spu_write_out_intr_mbox(258);
        r4 = spu_read_in_mbox();

        /*  opcode: 6 (GETTABLE)   a:1,b:4,c:259   */
        spu_write_out_intr_mbox(OP_GETTABLE);
        spu_write_out_intr_mbox(r4);
        spu_write_out_intr_mbox(259);
        r1 = spu_read_in_mbox();

        /*  opcode: 5 (GETGLOBAL)  a:4,b:2,c:<nop> */
        spu_write_out_intr_mbox(OP_GETGLOBAL);
        spu_write_out_intr_mbox(1);
        spu_write_out_intr_mbox(0);
        r4 = spu_read_in_mbox();
    }
    spu_write_out_intr_mbox(999);
    spu_write_out_intr_mbox(0);
    spu_write_out_intr_mbox(0);
    spu_write_out_intr_mbox(LUA_TNUMBER);
    spu_write_out_intr_mbox(r0);
    spu_write_out_intr_mbox(0);
    return 0;
}

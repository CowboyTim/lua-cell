#include <spu_mfcio.h>

#define LUA_LIB
#include "lua.h"
#include "lauxlib.h"

int main(unsigned long long spe, unsigned long long argp, unsigned long long envp) {
    lua_State *L = (lua_State *)&argp;
    int i;
    {
        spu_write_out_intr_mbox(LUA_TNUMBER);
        spu_write_out_intr_mbox(2);
        i = spu_read_in_mbox();
        i = i + 10;
    }
    spu_write_out_intr_mbox(999);
    spu_write_out_intr_mbox(0);
    spu_write_out_intr_mbox(LUA_TNUMBER);
    spu_write_out_intr_mbox(i);
    return 0;
}

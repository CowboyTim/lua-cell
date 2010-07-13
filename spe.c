#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <libspe2.h>

#include <pthread.h>

#define LUA_LIB
#include "lauxlib.h"
#include "lopcodes.h"

static int spe_cache_map = LUA_REFNIL;

typedef struct {
    spe_program_handle_t  *program;
    spe_context_ptr_t     context;
    lua_State             *L;
} spe_state_t;

void * run(void *s) {
    unsigned int          entry       = SPE_DEFAULT_ENTRY;
    unsigned int          runflags    = 0;
    void*                 envp        = NULL;
    spe_stop_info_t       stop_info;

    spe_context_run(((spe_state_t *)s)->context, &entry, runflags, ((spe_state_t *)s)->L, envp, &stop_info);
    return NULL;
}

static int l_spe_image_open(lua_State *L) {

    luaL_checktype(L, 1, LUA_TSTRING);
    const char *fn = lua_tostring(L, 1);
    spe_program_handle_t* program = spe_image_open(fn);

    lua_pushlightuserdata(L, program);
    spe_cache_map = luaL_ref(L, LUA_REGISTRYINDEX);

    return 1;
}

static l_run(lua_State *L) {
    spe_state_t           *spe_state = lua_touserdata(L, 1);
    spe_context_ptr_t     context    = spe_state->context;

    unsigned int i[2];
    while(spe_out_intr_mbox_read(context, (unsigned int *)&i, 2, SPE_MBOX_ALL_BLOCKING) != -1){

        if(i[0] == 999){
            break;
        }

        fprintf(stderr, "GOT[0]:%d\n", i[0]);
        fprintf(stderr, "GOT[1]:%d\n", i[1]);

        void *v;

        if (i[0] == OP_GETUPVAL){
            fprintf(stderr, "GETUPVAL:%d, %d\n", i[0], i[1]);
            if(lua_getupvalue(L, -2, i[1]+1) == NULL)
                fprintf(stderr, "NOK GETUPVAL\n");
            int t = lua_type(L, -1);
            fprintf(stderr, "LUA_TYPE:%d\n", t);
            if (t == LUA_TNUMBER){
                fprintf(stderr, "LUA_TNUMBER:%d\n", i[0]);
                unsigned int upv = lua_tointeger(L, -1);
                v = &upv;
                lua_pop(L, 1);
            }

            spe_in_mbox_write(context, v, 1, SPE_MBOX_ALL_BLOCKING);
        }
    }

    spe_out_intr_mbox_read(context, (unsigned int *)&i, 2, SPE_MBOX_ALL_BLOCKING);
    lua_pushnumber(L, i[1]);

    return 1;
}

static l_init(lua_State *L) {
    luaL_checktype(L, 1, LUA_TSTRING);
    const char *fn = lua_tostring(L, 1);

    pthread_t             runner;
    unsigned int          createflags = 0;

    spe_state_t *spe_state = (spe_state_t *)malloc(sizeof(spe_state_t));
    spe_state->program = spe_image_open(fn);
    spe_state->context = spe_context_create(createflags, NULL);
    spe_state->L       = L;


    spe_program_load(spe_state->context, spe_state->program);

    lua_pushlightuserdata(L, spe_state);

    pthread_create(&runner, NULL, run, spe_state);

    return 1;
}

static execute(lua_State *L) {
    luaL_checktype(L, 1, LUA_TSTRING);
    const char *fn = lua_tostring(L, 1);

    unsigned int          createflags = 0;
    unsigned int          runflags    = 0;
    unsigned int          entry       = SPE_DEFAULT_ENTRY;
    void*                 argp        = NULL;
    void*                 envp        = NULL;

    spe_program_handle_t* program     = spe_image_open(fn);
    spe_context_ptr_t     spe         = spe_context_create(createflags, NULL);
    spe_stop_info_t       stop_info;

    spe_program_load(spe, program);
    spe_context_run(spe, &entry, runflags, argp, envp, &stop_info);
    spe_image_close(program);
    spe_context_destroy(spe);

    return 1;
}

static const luaL_reg Cell[] = {
    { "spe_image_open"  , l_spe_image_open },
    { "execute"         , execute          },
    { "init"            , l_init           },
    { "run"             , l_run            },
    { NULL              , NULL             }
};

LUA_API int luaopen_spe(lua_State *L)
{
    luaL_openlib(L, "spe", Cell, 0);

    lua_pushliteral(L, "_COPYRIGHT");
    lua_pushliteral(L, "Copyright (C) 2010 Tim Aerts <aardbeiplantje@gmail.com>");
    lua_settable(L, -3);
    lua_pushliteral(L, "_DESCRIPTION");
    lua_pushliteral(L, "Binding to Cell/BE SPU vector processing");
    lua_settable(L, -3);
    lua_pushliteral(L, "_VERSION");
    lua_pushliteral(L, "LuaCell 0.1");
    lua_settable(L, -3);

    return 1;
}

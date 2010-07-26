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
    pthread_t             runner;
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

static l_spe_out_intr_mbox_read(lua_State *L){
    spe_state_t           *spe_state = lua_touserdata(L, 1);
    spe_context_ptr_t     context    = spe_state->context;

    unsigned int nr = lua_tointeger(L, 2);
    unsigned int *d = malloc(sizeof(unsigned int)*nr);

    if(spe_out_intr_mbox_read(context, d, nr, SPE_MBOX_ALL_BLOCKING) != -1){
        int i;
        for(i = 0; i < nr; i++) {
            unsigned int v = *d;
            fprintf(stdout, "i[%d] = %d\n", i, v);
            lua_pushinteger(L,(lua_Integer)v);
            d++;
        }
    } else {
        lua_pushnil(L);
        return 1;
    }
    return nr;
}

static l_spe_in_mbox_write(lua_State *L){
    spe_state_t           *spe_state = lua_touserdata(L, 1);
    spe_context_ptr_t     context    = spe_state->context;

    unsigned int nr = lua_gettop(L) -1;
    unsigned int *d = malloc(sizeof(unsigned int)*nr);
    fprintf(stdout, "nr = %d\n", nr);
    int i;
    for(i = 0; i < nr; i++) {
        d[i] = lua_tointeger(L, i+1); 
        fprintf(stdout, "d[%d] = %d\n", i, d[i]);
    }
    spe_in_mbox_write(context, d, nr, SPE_MBOX_ALL_BLOCKING);
    return 0;
}

static l_runspe(lua_State *L) {
    spe_state_t           *spe_state = lua_touserdata(L, 1);
    spe_context_ptr_t     context    = spe_state->context;

    int funcindex = lua_gettop(L) -1;

    fprintf(stderr, "FUNC indx: %d\n", funcindex);

    unsigned int i[3];
    while(spe_out_intr_mbox_read(context, (unsigned int *)&i, 3, SPE_MBOX_ALL_BLOCKING) != -1){

        if(i[0] == 999){
            break;
        }

        fprintf(stderr, "GOT[0]:%d\n", i[0]);
        fprintf(stderr, "GOT[1]:%d\n", i[1]);
        fprintf(stderr, "GOT[2]:%d\n", i[2]);

        void *v;

        switch (i[0]) {
            /* fetch from the LUA VM */
            case OP_GETUPVAL: {
                fprintf(stderr, "OP_GETUPVAL:%d, %d\n", i[0], i[1]);
                if(lua_getupvalue(L, funcindex, i[1]+1) == NULL)
                    fprintf(stderr, "NOK GETUPVAL!!!!!!!!!!!!!!!!!!\n");
                break;
            }
            case OP_GETGLOBAL: {
                fprintf(stderr, "OP_GETGLOBAL:%d, %d\n", i[0], i[1]);
                break;
            }
            case OP_GETTABLE: {
                fprintf(stderr, "OP_GETTABLE:%d, %d, %d\n", i[0], i[1], i[2]);
                int t = lua_type(L, i[1]);
                if (t == LUA_TTABLE){
                    if(i[2] >= 256){
                        /* a constant */
                        i[2] -= 256;
                        lua_pushstring(L, "cccccc\0"); 
                    } else {
                        /* FIXME: just a variable: push */
                        lua_pushstring(L, "cccccc\0"); 
                    }
                    lua_gettable(L, i[1]);
                } else {
                    fprintf(stderr, "OP_GETTABLE:%d, %d, %d NOK!!!!\n", i[0], i[1], i[2]);
                }
                break;
            }
            case OP_LOADK: {
                fprintf(stderr, "OP_LOADK:%d, %d\n", i[0], i[1]);
                break;
            }
        }

        /* push */
        int t = lua_type(L, -1);
        fprintf(stderr, "LUA_TYPE:%d\n", t);
        switch (t) {
            case LUA_TNIL: {
                fprintf(stderr, "LUA_TNIL:%d\n", i[0]);
                break;
            }
            case LUA_TBOOLEAN: {
                fprintf(stderr, "LUA_TBOOLEAN:%d\n", i[0]);
                break;
            }
            case LUA_TLIGHTUSERDATA: {
                fprintf(stderr, "LUA_TLIGHTUSERDATA:%d\n", i[0]);
                break;
            }
            case LUA_TNUMBER: {
                fprintf(stderr, "LUA_TNUMBER:%d\n", i[0]);
                unsigned int upv = lua_tointeger(L, -1);
                v = &upv;
                lua_pop(L, 1);
                break;
            }
            case LUA_TSTRING: {
                fprintf(stderr, "LUA_TSTRING:%d\n", i[0]);
                lua_pop(L, 1);
                break;
            }
            case LUA_TTABLE: {
                fprintf(stderr, "LUA_TTABLE:%d\n", i[0]);
                unsigned int tv = lua_gettop(L);
                v = &tv;
                fprintf(stderr, "LUA_TTABLE:%d, index:%d\n", i[0], tv);
                break;
            }
            case LUA_TFUNCTION: {
                fprintf(stderr, "LUA_TFUNCTION:%d\n", i[0]);
                break;
            }
            case LUA_TUSERDATA: {
                fprintf(stderr, "LUA_TUSERDATA:%d\n", i[0]);
                break;
            }
            case LUA_TTHREAD: {
                fprintf(stderr, "LUA_TTHREAD:%d\n", i[0]);
                break;
            }
        }
        spe_in_mbox_write(context, v, 1, SPE_MBOX_ALL_BLOCKING);
    }

    spe_out_intr_mbox_read(context, (unsigned int *)&i, 2, SPE_MBOX_ALL_BLOCKING);
    lua_pushnumber(L, i[1]);

    return 1;
}

static l_init(lua_State *L) {
    luaL_checktype(L, 1, LUA_TSTRING);
    const char *fn = lua_tostring(L, 1);

    unsigned int          createflags = 0;

    spe_state_t *spe_state = (spe_state_t *)malloc(sizeof(spe_state_t));
    spe_state->program = spe_image_open(fn);
    spe_state->context = spe_context_create(createflags, NULL);
    spe_state->L       = L;


    spe_program_load(spe_state->context, spe_state->program);

    lua_pushlightuserdata(L, spe_state);

    pthread_create(&spe_state->runner, NULL, run, spe_state);

    return 1;
}

static l_destroy(lua_State *L) {
    spe_state_t           *spe_state = lua_touserdata(L, 1);
    spe_context_ptr_t     context    = spe_state->context;

    pthread_join(spe_state->runner, NULL);

    spe_image_close(spe_state->program);
    spe_context_destroy(context);
    return 0;
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
    { "spe_image_open"         , l_spe_image_open         } ,
    { "execute"                , execute                  } ,
    { "init"                   , l_init                   } ,
    { "destroy"                , l_destroy                } ,
    { "runspe"                 , l_runspe                 } ,
    { "spe_out_intr_mbox_read" , l_spe_out_intr_mbox_read } ,
    { "spe_in_mbox_write"      , l_spe_in_mbox_write      } ,
    { NULL                     , NULL                     } 
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

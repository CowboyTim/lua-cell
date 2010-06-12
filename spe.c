#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <libspe2.h>

#include <pthread.h>

#define LUA_LIB
#include "lua.h"
#include "lauxlib.h"

static int spe_cache_map = LUA_REFNIL;

static int l_spe_image_open(lua_State *L) {
    int res;

    luaL_checktype(L, 1, LUA_TSTRING);
    const char *fn = lua_tostring(L, 1);
    spe_program_handle_t* program = spe_image_open(fn);

    lua_pushlightuserdata(L, program);
    spe_cache_map = luaL_ref(L, LUA_REGISTRYINDEX);

    return res;
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
    { NULL              , NULL             }
};

LUA_API int luaopen_cell(lua_State *L)
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

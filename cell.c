#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

#include <pthread.h>

#define LUA_LIB
#include "lua.h"
#include "lauxlib.h"

static pthread_rwlock_t vm_lock;
static lua_State *L_VM = NULL;

typedef struct {
    void *data;
    size_t s;
} aaa_t;

lua_Writer f(lua_State *L, const void* p, size_t sz, void* data){
    aaa_t *a = (aaa_t *)data;
    a->s += sz;
    printf("%d\n", a->s);
    printf("REALLOC: %d\n", a->s);
    a->data = (void *)realloc(a->data, a->s);
    memcpy((a->data + a->s - sz), p, sz);
    return 0;
}

static dump(lua_State *L)
{
    luaL_checktype(L, 1, LUA_TFUNCTION);

    aaa_t s;
    s.s = 0;
    s.data = NULL;
    
    lua_dump(L, f, &s);
    lua_pushlstring(L, s.data, s.s);

    return 1;
}


static const luaL_reg Cell[] = {
    { "dump"  , dump       },
    { NULL    , NULL       }
};

LUA_API int luaopen_cell(lua_State *L)
{
    luaL_openlib( L, "cell", Cell, 0 );

    lua_pushliteral (L, "_COPYRIGHT");
    lua_pushliteral (L, "Copyright (C) 2010 Tim Aerts <aardbeiplantje@gmail.com>");
    lua_settable (L, -3);
    lua_pushliteral (L, "_DESCRIPTION");
    lua_pushliteral (L, "Binding to Cell/BE SPU vector processing");
    lua_settable (L, -3);
    lua_pushliteral (L, "_VERSION");
    lua_pushliteral (L, "LuaCell 0.1");
    lua_settable (L, -3);

    pthread_rwlock_init(&vm_lock, NULL);
    return 1;
}

# makefile for spe library for Lua

# change these to reflect your Lua installation
LUAINC= /usr/include/lua5.1
LUALIB= $(LUA)/lib
LUABIN= $(LUA)/bin

MYNAME= spe

# no need to change anything below here except if your gcc/glibc is not
# standard
CFLAGS= $(INCS) $(DEFS) $(WARN) -O2 -D_FILE_OFFSET_BITS=64 -D_REENTRANT -fPIC -shared
INCS= -I$(LUAINC) -I ~/lua-5.1.4/src
LIBS= -llua5.1 -lpthread

OBJS = spe.so

CC=gcc
SPUCC=spu-gcc

all:    $(OBJS) spe_runner

%.so:	%.c
	$(CC) -o $@ $(CFLAGS) $(WARN) $(LIBS) $< /usr/lib/libspe2.a

spe_runner: spe_runner.c
	$(SPUCC) -o $@ $(INCS) $< /home/tim/lua-5.1.4-spu/src/liblua.a /usr/spu/lib/libm.a


clean:
	rm -f $(OBJS) spe_runner


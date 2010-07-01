# makefile for spe library for Lua

# change these to reflect your Lua installation
LUAINC= /usr/include/lua5.1
LUALIB= $(LUA)/lib
LUABIN= $(LUA)/bin

MYNAME= spe

# no need to change anything below here except if your gcc/glibc is not
# standard
CFLAGS= $(INCS) $(DEFS) $(WARN) -O2 -D_FILE_OFFSET_BITS=64 -D_REENTRANT -fPIC -shared
INCS= -I$(LUAINC)
LIBS= -llua5.1 -lpthread

OBJS = spe.so

CC=gcc

all:    $(OBJS)

%.so:	%.c
	$(CC) -o $@ $(CFLAGS) $(WARN) $(LIBS) $< /usr/lib/libspe2.a

clean:
	rm -f $(OBJS)


# makefile for spe library for Lua

# change these to reflect your Lua installation
LUAINC= /usr/include/lua5.1
LUALIB= $(LUA)/lib
LUABIN= $(LUA)/bin

MYNAME= spe

# no need to change anything below here except if your gcc/glibc is not
# standard
CFLAGS= $(INCS) $(DEFS) $(WARN) -O2 $G -D_FILE_OFFSET_BITS=64 -D_REENTRANT -fPIC
WARN= #-ansi -pedantic -Wall
INCS= -I$(LUAINC) -I$(MD5INC)
LIBS= -llua5.1 -lpthread -lspe2

OBJS = spe.so

CC=gcc

all:    $(OBJS)

%.so:	%.c
	$(CC) -o $@ -shared $(CFLAGS) $(WARN) $(LIBS) $<
	strip $@

clean:
	rm -f $(OBJS)


# $Id: Makefile,v 1.2 2001/06/18 15:26:16 reggiori Exp $
#
INSTDIR=/RDFStore

LINT = lint
LINTFLAGS = -chapbx
CC = gcc
INCLUDES= -I../include
LFLAGS = -g3 
CFLAGS = -g3 -Wall 

CFLAGS += -a -pg

DEFINES = -DDIRKX 
#
# Whether to fork(on BSD) or multitread(on Irix)
# or not at all. You propably want to leave this
# in as the non-tread/non-fork versions have not
# been used in a long time...
#
DEFINES += -DFORKING
#
# General debugging; also, some asserts present
# so should use -NDEBUG :-)
#
# DEFINES += -DDEBUG
# 
# Bit of malloc tracing, basically a
# free check on termination
#
#DEFINES += -DDEBUG_MALLOC
# 
# Wether to malloc once; and keep it on
# a linked list; or contineously malloc/free
# for dbase/child/connect structs, i.e. the
# 'long' lived things (i.e. >= session time)
#
DEFINES += -DSTATIC_BUFF
#
# Same for short (per transact) buffers
#
DEFINES +=  -DSTATIC_CS_BUFF
DEFINES +=  -DSTATIC_SC_BUFF
#
# If your kernel allows it.. *implies a 
# kernel recompile normally*
#
# DEFINES += -DFD_SETSIZE=4048
#

SRCS = deamon.c mymalloc.c handler.c main.c children.c loop.c pathmake.c
OBJS = ${SRCS:c=o}
INCL = dbmsd.h deamon.h handler.h mymalloc.h pathmake.h

# uncomment the following line to use BDB 1.85 compatibility code on platforms such Linux
#LIBS = -ldb1

INSTALL = install -c 

all: dbmsd $(INCL) ../include/dbms.h Makefile

test: dbmsd
	rm -f /tmp/test*db
	rm -f *db
	if [ -f /var/run/dbms.pid ]; then kill `cat /var/run/dbms.pid`; sleep 1; fi
	# killall dbmsd
	@echo -------------
	./dbmsd -x -x -x -x -x -x -x -x -x -x -U -d /usr/tmp

.c.o:	Makefile
	$(CC) $(CFLAGS) $(INCLUDES) $(DEFINES) -c -o $@ $<

version: 
	./version.pl > version.c
	$(CC) $(CFLAGS) $(INCLUDES) $(DEFINES) -c -o version.o version.c

dbmsd:	${OBJS}  version
	${CC} $(CFLAGS) ${LFLAGS} -o $@ ${OBJS} version.o ${LIBS}

clean:
	rm -f version.c dbmsd dbmsd.8.gz
	rm -f *.o gmon* core.* *.core *.db

man: dbmsd.8
	cat dbmsd.8 | gzip > dbmsd.8.gz

install: dbmsd man
	mkdir -p $(INSTDIR)/bin $(INSTDIR)/rc $(INSTDIR)/man/man8 $(INSTDIR)/dbms
	$(INSTALL) -m 0555 -o bin -g bin dbmsd $(INSTDIR)/bin
	$(INSTALL) -m 0555 -o bin -g bin dbmsd.sh $(INSTDIR)/rc
	$(INSTALL) -m 0644 -o bin -g bin dbmsd.8.gz $(INSTDIR)/man/man8

depend:
	makedepend $(INCLUDES) $(DEFINES) $(SRCS)

distclean: clean
	rm -f *% 

lint: 
	$(LINT) $(LINTFLAGS) $(INCLUDES) $(DEFINES) ${SRCS}

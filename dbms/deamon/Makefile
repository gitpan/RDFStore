# $Id: Makefile,v 1.6 1998/12/19 19:43:29 dirkx Exp $
#
INSTDIR=/RDFStore

LINT = lint
LINTFLAGS = -chapbx
CC = gcc
INCLUDES= -I../include
LFLAGS = -g3 
CFLAGS = -g3 -Wall 
# DEFINES = -DDEBUG -DDEBUG_MALLOC -DFORKING -DFD_SETSIZE=4048
#DEFINES = -DDEBUG -DDEBUG_MALLOC -DFORKING -DFORKING
DEFINES = -DFORKING
# DEFINES = -DDEBUG -DDEBUG_MALLOC
#
#
SRCS = deamon.c mymalloc.c handler.c main.c children.c loop.c pathmake.c
OBJS = ${SRCS:c=o}
INCL = dbmsd.h deamon.h handler.h mymalloc.h pathmake.h
LIBS = 
INSTALL = install -c 

all: dbmsd $(INCL) ../include/dbms.h Makefile

test: dbmsd
	rm -f /tmp/test*db
	rm -f *db
	if [ -f /var/run/dbms.pid ]; then kill `cat /var/run/dbms.pid`; fi
	./dbmsd -X -d $(INSTDIR)/tmp

.c.o:	Makefile
	$(CC) $(CFLAGS) $(INCLUDES) $(DEFINES) -c -o $@ $<

version: 
	./version.pl > version.c
	$(CC) $(CFLAGS) $(INCLUDES) $(DEFINES) -c -o version.o version.c

dbmsd:	${OBJS}  version
	${CC} ${LFLAGS} -o $@ ${OBJS} version.o ${LIBS}

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
	
distclean: clean
	rm -f *% 

lint: 
	$(LINT) $(LINTFLAGS) $(INCLUDES) $(DEFINES) ${SRCS}

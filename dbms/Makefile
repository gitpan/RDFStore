#
TFILE=dbms-`date +%Y-%m-%d`

all: 
	( cd DBMS; perl Makefile.PL && make )
	( cd deamon; make )

tar:
	if [ -f DBMS/Makefile ] ; then ( cd DBMS; make clean ); fi
	( cd deamon; make clean )
	mkdir -p ../$(TFILE) 
	cp -r . ../$(TFILE)
	cd ..
	tar zcf $(TFILE).tar.gz $(TFILE)

clean:
	( cd DBMS; perl Makefile.PL && make clean; rm *.old )
	( cd deamon; make clean )

install: all
	( cd DBMS; make install )
	( cd deamon; make install )

#
TFILE=dbms-`date +%Y-%m-%d`

all: 
	( cd deamon; make )
	( cd DBMS; perl Makefile.PL && make )

tar:
	if [ -f DBMS/Makefile ] ; then ( cd DBMS; make clean ); fi
	( cd deamon; make clean )
	mkdir -p ../$(TFILE) 
	cp -r . ../$(TFILE)
	cd ..
	tar zcf $(TFILE).tar.gz $(TFILE)

clean:
	( cd deamon; make clean )
	( cd DBMS; perl Makefile.PL && make clean; rm *.old )

install: all
	( cd deamon; make install )
	( cd DBMS; make install )

depend:
	( cd deamon; make depend )

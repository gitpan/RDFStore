# $Id: Makefile.PL,v 1.1.1.1 2001/01/18 09:53:21 reggiori Exp $
#
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'DBMS',
    VERSION_FROM => 'DBMS.pm',
	 DEFINE => '-DSTATIC_BUFF -DSTATIC_CS_BUFF -DSTATIC_SC_BUFF'
);

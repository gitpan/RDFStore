#!/bin/sh
DIR=/RDFStore

ulimit -d 65000
ulimit -n 2048
ulimit -u 256
ulimit -m 64000

[ -f $DIR/bin/dbmsd ] && $DIR/bin/dbmsd -d $DIR/dbms && echo -n dbmsd

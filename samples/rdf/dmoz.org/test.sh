#!/bin/sh

fetch -q -o - http://dmoz.org/rdf/structure.rdf.u8.gz |gunzip - |sed -f structure.sed|./dump.pl -

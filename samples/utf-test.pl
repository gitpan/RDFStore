#!/usr/local/bin/perl
my $a = shift;

print "---->'",join('',unpack("U*",$a)),"'\n";

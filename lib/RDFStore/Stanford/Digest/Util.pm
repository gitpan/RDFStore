# *
# *	Copyright (c) 2000 Alberto Reggiori <areggiori@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.jrc.it/LICENSE
# *
# * Changes:
# *     version 0.1 - 2000/11/03 at 04:30 CEST
# *     version 0.31
# *             - fixed nusty bug in digestBytes2HashCode() to cast hash code to INTEGER
# *     version 0.4
# *		- fixed stupid/braindead bug when disable warnings- Thanks to Marc Lehmann <pcg@goof.com>
# *             - fixed a few warnings
# *		- added getDigestAlgorithm() method
# *		- Devon Smith <devon@taller.pscl.cwru.edu> changed digestBytes2HashCode() and toHexString() to
# *		  generate digests and hashes that match Stanford java ones exactly
# *     version 0.41
# *		- updated digestBytes2HashCode()
# *

package RDFStore::Stanford::Digest::Util;
{
use vars qw ( $VERSION );
use strict;
 
$VERSION = '0.41';

$RDFStore::Stanford::Digest::Util::perl_version_ok=1;
eval {
	require 5.6.0;
};
if($@) {
	$RDFStore::Stanford::Digest::Util::perl_version_ok=0;
};

use Carp;
use Digest;
use RDFStore::Stanford::Digest::SHA1;
use RDFStore::Stanford::Digest::MD5;
use RDFStore::Stanford::Digest::Generic;

# return default digest algorithm
sub getDigestAlgorithm {
	return "SHA-1";
};

sub computeDigest {
	my ($alg,$str) = @_;

	my $md = Digest->new($alg);

	# **** FIXME!! ****
	#if($RDFStore::Stanford::Digest::Util::perl_version_ok) {
		#eval "no warnings 'utf8';"; #this is memory leaking under perl5.6.0 :(
		#$md->add( unpack("U*",$str) );
	#} else {
		$md->add( unpack("C*",$str) ); # old Perl no utf8
	#};
	my $d = $md->digest; #you want to keep it :-)
	croak "Cannot compute Digest for $str"
		unless(defined $d);
	return createFromBytes($alg,\$d);
};

sub createFromBytes {
	my ($alg,$d) = @_;
	
	if($alg eq "SHA-1") {	
		croak "SHA-1 digest must be 20 bytes long"
			if(length(${$d}) != 20);
		return new RDFStore::Stanford::Digest::SHA1($d);
	} elsif($alg eq "MD5") {
		croak "MD5 digest must be 16 bytes long"
			if(length(${$d}) != 16);
		return new RDFStore::Stanford::Digest::MD5($d);
	};
	return new RDFStore::Stanford::Digest::Generic($alg,$d);
};

sub getHashCode {
	my ($digest) = @_;

	return digestBytes2HashCode(${$digest->getDigestBytes()});
};

sub digestBytes2HashCode {
	my ($d) = @_;

        my @stuff=split(//,$d);

        use integer;
        return ( (  (ord $stuff[0]) & 0xff) |
               (( (ord $stuff[1]) & 0xff) << 8) |
               (( (ord $stuff[2]) & 0xff) << 16) |
               (( (ord $stuff[3]) & 0xff) << 24) );
	#return int(     (unpack("b*",$stuff[0]) & 0xff) |
        #                ((unpack("b*",$stuff[2]) & 0xff) << 8) |
        #                ((unpack("b*",$stuff[4]) & 0xff) << 16) |
        #                ((unpack("b*",$stuff[6]) & 0xff) << 24) );
};

sub xor {
	my ($d1,$d2) = @_;

	croak "Need scalar references"
		unless((ref($d1)=~ /SCALAR/) && (ref($d2)=~ /SCALAR/));

	${$d1} ^= ${$d2};
};

# how to implement it in Perl using untyped vars??
sub xor_n {
	my ($d1,$d2,$shift) = @_;

	croak "Need scalar references"
		unless((ref($d1)=~ /SCALAR/) && (ref($d2)=~ /SCALAR/));

	#warn "RDFStore::Stanford::Digest::Util::xor_n() is not supported using Perl\n";
	my @d1=split(//,${$d1});
	my @d2=split(//,${$d2});
    	for(my $i = 0; $i < $#d1; $i++) {
		$d1[($i +$shift) % $#d1] = pack("b*",(unpack("b*",$d1[($i +$shift) % $#d1]) ^ unpack("b*",$d2[$i])));
	};
};

# The circular left shift by N bits
sub leftShift {
	my ($src,$n) = @_;

	warn "RDFStore::Stanford::Digest::Util::leftShift() is not supported using Perl\n";
};

sub add {
	my ($d1,$d2) = @_;
	
	croak "Need scalar references"
		unless((ref($d1)=~ /SCALAR/) && (ref($d2)=~ /SCALAR/));

	# the Java implementation is using BigInteger to translate the array to int
	#...but this hack should consider big/small endian 2 complement rapresentation
	my $dd = ${$d1}+${$d2};
	return \$dd;
};

sub sha_f_1 {
	my ($b,$c,$d) = @_;

	croak "Need scalar references"
		unless((ref($b)=~ /SCALAR/) && (ref($c)=~ /SCALAR/) && (ref($d)=~ /SCALAR/));

	my $f = (${$b} & ${$c}) | ((~(${$b})) & ${$d});
	return \$f;
};

sub sha_f_2 {
	my ($b,$c,$d) = @_;

	croak "Need scalar references"
		unless((ref($b)=~ /SCALAR/) && (ref($c)=~ /SCALAR/) && (ref($d)=~ /SCALAR/));

	my $f = (${$b} ^ ${$c} ^ ${$d});
	return \$f;
};

sub sha_f_3 {
	my ($b,$c,$d) = @_;

	croak "Need scalar references"
		unless((ref($b)=~ /SCALAR/) && (ref($c)=~ /SCALAR/) && (ref($d)=~ /SCALAR/));

	my $f = ((${$b} & ${$c}) | (${$b} & ${$d}) | (${$c} & ${$d}));
	return \$f;
};

sub and {
	my ($d1,$d2) = @_;
	
	croak "Need scalar references"
		unless((ref($d1)=~ /SCALAR/) && (ref($d2)=~ /SCALAR/));

	${$d1} &= ${$d2};
};

sub or {
	my ($d1,$d2) = @_;
	
	croak "Need scalar references"
		unless((ref($d1)=~ /SCALAR/) && (ref($d2)=~ /SCALAR/));

	${$d1} |= ${$d2};
};

sub not {
	my ($d1) = @_;
	
	croak "Need scalar references"
		unless(ref($d1)=~ /SCALAR/);

	${$d1} = (~(${$d1}));
};

sub equal {
	my ($d1,$d2) = @_;

	if((ref($d1)=~ /SCALAR/) && (ref($d2)=~ /SCALAR/)) {
      		return 0
			if(length(${$d1}) != length(${$d2}));

		#print unpack("h*",${$d1}),"====",unpack("h*",${$d2}),"\n";

		return (${$d1} eq ${$d2}) ? 1 : 0;
	} elsif( ref($d1) && ref($d2) && $d1->isa("RDFStore::Stanford::Digest") && $d2->isa("RDFStore::Stanford::Digest")) {
      		return 1
			if($d1 == $d2);

		if($d1->isa("RDFStore::Stanford::Digest::Abstract") && $d2->isa("RDFStore::Stanford::Digest::Abstract")) {
			return equal($d1->{digest}, $d2->{digest});
		} else { #general case
        		if($d1->getDigestAlgorithm() eq $d2->getDigestAlgorithm()) {
          			return equal($d1->getDigestBytes(),$d2->getDigestBytes());
			} else {
				return 0; #not sure...Java uses try/catch
			};
		};
	} else {
		return 0;
	};
};

sub toHexString {
	my ($buf) = @_;
	
        if( ref($buf) && $buf->isa("RDFStore::Stanford::Digest")) {
                return unpack("H*",$buf->{digest});
        } else {
                return unpack("H*",$buf);
        };
};	

1;
};

__END__

=head1 NAME

RDFStore::Stanford::Digest::Util - implementation of the DigestUtil RDF API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

Digest(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>

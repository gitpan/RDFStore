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
# *     version 0.2
# *             - added getNamespace() getLocalName() methods accordingly to rdf-api-2000-10-30
# *     version 0.3
# *             - fixed bugs when checking references/pointers (defined and ref() )
# *     version 0.4
# *		- changed way to return undef in subroutines
# *		- fixed warning in getDigest()
# *             - updated new() equals() and added hashCode() accordingly to rdf-api-2001-01-19
# *		- updated accordingly to rdf-api-2001-01-19
# *		- Devon Smith <devon@taller.pscl.cwru.edu> changed getDigest to generate digests and hashes 
# *		  that match Stanford java ones exactly
# *     version 0.42
# *		- updated toString() and getDigest()
# *

package RDFStore::Statement;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.42';

use Carp;
use RDFStore::Stanford::Statement;
use RDFStore::Stanford::Resource;


@RDFStore::Statement::ISA = qw( RDFStore::Stanford::Resource RDFStore::Stanford::Statement );

sub new {
	my $self = {};

	croak "Cannot create statement for $_[1], $_[2], $_[3]"
		unless(	( (ref($_[1])) && ($_[1]->isa('RDFStore::Stanford::Resource')) ) &&
			( (ref($_[2])) && ($_[2]->isa('RDFStore::Stanford::Resource')) ) &&
			( (ref($_[3])) && ($_[3]->isa('RDFStore::Stanford::RDFNode')) ) );
	
	$self->{subj} = $_[1];
	$self->{pred} = $_[2];
	$self->{obj} = $_[3];

	bless $self,$_[0];
};

sub subject {
	return $_[0]->{subj};
};

sub predicate {
	return $_[0]->{pred};
};

sub object {
	return $_[0]->{obj};
};

sub node2string {
	croak "Node ".$_[1]." is not instance of RDFStore::Stanford::RDFNode"
                unless(	(defined $_[1]) && 
			(ref($_[1])) && 
			($_[1]->isa('RDFStore::Stanford::RDFNode')) );

	if(	(ref($_[1])) &&
		($_[1]->isa("RDFStore::Stanford::Literal")) ) {
        	return 'literal("'.$_[1]->getLabel() .'")';
	} elsif(	(ref($_[1])) &&
			($_[1]->isa("RDFStore::Stanford::Statement")) ) {
        	return $_[1]->toString();
	} elsif(	(ref($_[1])) &&
			($_[1]->isa("RDFStore::Stanford::Resource")) ) {
		return '"'.$_[1]->getLabel() .'"';
      	} else {
        	return $_[1];
	};
};

sub toString {
        return "triple(". 	$_[0]->node2string($_[0]->subject).", ".
				$_[0]->node2string($_[0]->predicate).", ".
				$_[0]->node2string($_[0]->object).")";
};

sub getNamespace {
        return;
};

sub getLocalName {
        return $_[0]->getLabel();
};

sub getLabel {
        return "urn:rdf:".
			&RDFStore::Stanford::Digest::Util::getDigestAlgorithm()."-".
			RDFStore::Stanford::Digest::Util::toHexString( $_[0]->getDigest() );
};

sub getURI {
	return $_[0]->getLabel();
};

sub hashCode {
	return (($_[0]->subject->hashCode() * 7) + $_[0]->predicate->hashCode()) * 7 + $_[0]->object->hashCode();
};

# Properties: digest can be constructed given the digests of the pred, subj, obj
# Permutations of the s, p, o return different digests
# see http://nestroy.wi-inf.uni-essen.de/rdf/sum_rdf_api/#K31
sub getDigest {
	unless( defined $_[0]->{digest} ) {
		my $s = $_[0]->subject->getDigest()->getDigestBytes();
        	my $p = $_[0]->predicate->getDigest()->getDigestBytes();
        	my $o = $_[0]->object->getDigest()->getDigestBytes();

        	my $b = $$s . $$p;
        	if($_[0]->object->isa("RDFStore::Stanford::Resource")) {
          		$b .= $$o;
        	} else { # rotate by one byte
          		my @torotate = split(//,$$o);
          		unshift @torotate, pop @torotate; # rotate to the right 
          		for ( @torotate ) {
            			$b .= $_;
          		};
        	};
        	$_[0]->{digest} = RDFStore::Stanford::Digest::Util::computeDigest(
			&RDFStore::Stanford::Digest::Util::getDigestAlgorithm(),$b)
			or croak "Cannot compute Digest for statement ",$_[0]->getLabel;
	};
	return $_[0]->{digest};
};

sub equals {
	return 0
		unless(defined $_[1]);

	return	(	($_[0]->subject->getLabel eq $_[1]->subject->getLabel) &&
			($_[0]->predicate->getLabel eq $_[1]->predicate->getLabel) &&
			($_[0]->object->getLabel eq $_[1]->object->getLabel) );
};

1;
};

__END__

=head1 NAME

RDFStore::Statement - implementation of the Statement RDF API

=head1 SYNOPSIS

	use RDFStore::Statement;
	use RDFStore::Literal;
	use RDFStore::Resource;
	my $statement = new RDFStore::Statement(
  				new RDFStore::Resource("http://www.w3.org/Home/Lassila"),
  				new RDFStore::Resource("http://description.org/schema/","Creator"),
  				new RDFStore::Literal("Ora Lassila") );
	my $statement1 = new RDFStore::Statement(
  				new RDFStore::Resource("http://www.w3.org"),
  				new RDFStore::Resource("http://description.org/schema/","Publisher"),
  				new RDFStore::Literal("World Wide Web Consortium") );

	my $subject = $statement->subject;
	my $predicate = $statement->predicate;
	my $object = $statement->object;

	print $statement->toString." is ";
        print "not"
                unless $statement->equals($statement1);
        print " equal to ".$statement1->toString."\n";


=head1 DESCRIPTION

An RDFStore::Stanford::Statement implementation.

=head1 SEE ALSO

RDFStore::Stanford::Statement(3) RDFStore::RDFNode(3) Digest(3) RDFStore::Literal(3) RDFStore::Resource(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>

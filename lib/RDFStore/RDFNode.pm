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
# *
# * Changes:
# *     version 0.1 - 2000/11/03 at 04:30 CEST
# *     version 0.2
# *             - modified getDigest() equals() methods accordingly to rdf-api-2000-10-30
# *     version 0.4
# *             - updated accordingly to rdf-api-2001-01-19
# *		- fixed bug in hashCode() to avoid bulding the digest each time
# *		- added inheritance from RDFStore::Stanford::Digest::Digestable
# *                 

package RDFStore::RDFNode;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.4';

use Carp;
use RDFStore::Stanford::RDFNode;
use RDFStore::Stanford::Digest::Digestable;
use RDFStore::Stanford::Digest::Util;

@RDFStore::RDFNode::ISA = qw ( RDFStore::Stanford::RDFNode RDFStore::Stanford::Digest::Digestable );

sub new {
	my ($pkg) = @_;
	my $self = $pkg->SUPER::new();

	$self->{_hashCode} = 0;
	
	bless $self,$pkg;
};

sub getLabel {
};

sub toString {
	return $_[0]->getLabel();
};

# return the four most significant bytes of the digest
sub hashCode {
	if($_[0]->{_hashCode} == 0) {
		$_[0]->{_hashCode} = RDFStore::Stanford::Digest::Util::getHashCode( $_[0]->getDigest() );
	};
	return $_[0]->{_hashCode};
};

sub getDigest {
	unless(defined $_[0]->{digest}) {
        	$_[0]->{digest} = RDFStore::Stanford::Digest::Util::computeDigest(
				&RDFStore::Stanford::Digest::Util::getDigestAlgorithm(),
				$_[0]->getLabel() )
			or croak "Cannot compute Digest for node $_[0] ",$_[0]->getLabel();
    	};
    	return $_[0]->{digest};
};

sub equals {
	return 0
		unless(	(defined $_[1]) &&
			($_[1]->isa("RDFStore::Stanford::RDFNode")) );

	if($_[1]->can('getDigest')) {
		return RDFStore::Stanford::Digest::Util::equal(
			$_[0]->getDigest()->getDigestBytes(), 
			$_[1]->getDigest()->getDigestBytes() );
	};

	return ($_[0]->getLabel() eq $_[1]->getLabel()) ? 1 : 0;
};

1;
};

__END__

=head1 NAME

RDFStore::RDFNode - implementation of the RDFNode RDF API using Digest(3)

=head1 SYNOPSIS

	package myNode;

	use RDFStore::RDFNode;
	@myNode::ISA = qw ( RDFStore::RDFNode );

	sub new {
		my $self = $_[0]->SUPER::new();
		$self->{mylabel} = $_[1];
		bless $self,$_[0];
	};

	sub getLabel {
		return $_[0]->{mylabel};
	};

	package main;

	my $node = new myNode('My generic node');
	my $node1 = new myNode('Your generic node');

	print $node->toString." is ";
	print "not "
		unless $node->equals($node1);
	print " equal to ".$node1->toString."\n";
	

=head1 DESCRIPTION

An RDFStore::Stanford::RDFNode implementation using Digest(3). It is the basic class inherited by RDFStore::Literal and RDFStore::Resource. It provides general toString(), hashCode(), getDigest() and equals() methods.

=head1 SEE ALSO

RDFStore::Stanford::RDFNode(3) RDFStore::Stanford::Digest::Util(3) Digest(3) RDFStore::Literal(3) RDFStore::Resource(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>

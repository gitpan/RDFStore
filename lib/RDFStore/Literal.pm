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
# *             - modified new() equals(), getLabel() methods accordingly to rdf-api-2000-10-30
# *		- modified toString()
# *     version 0.3
# *             - fixed bugs when checking references/pointers (defined and ref() )
# *     version 0.4
# *		- updated accordingly to rdf-api-2001-01-19
# *		- modified getLabel() and getURI() to return a lebel even if the Literal is a BLOB (using Storable)
# *		- updated equals() method to make a real comparison of BLOBs using Storable module
# *

package RDFStore::Literal;
{
use vars qw ($VERSION);
use strict;

use Carp;
 
$VERSION = '0.4';

use Storable qw ( nfreeze ); #used for BLOBs comparinson
use RDFStore::Stanford::Literal;
use RDFStore::RDFNode;

@RDFStore::Literal::ISA = qw( RDFStore::RDFNode RDFStore::Stanford::Literal );

sub new {
	my $self = $_[0]->SUPER::new();
    	$self->{content} = $_[1];
	bless $self,$_[0];
};

sub getContent {
	return $_[0]->{content};
};

sub getLabel {
        # we are assuming that object can be compared after using FT using $Storable::canonical
	my $label = $_[0]->{content};
	if(ref($label)) {
        	$Storable::canonical=1;
		$label = nfreeze($label); #NOTE: this is done already by Data::MagicTie called in RDFStore::Model
        	$Storable::canonical=0;
	};

	return $label;
};

sub getURI {
	return $_[0]->getLabel;
};

sub equals {
	return 0
                unless(defined $_[1]);

	my $label1 = $_[0]->getLabel();
        my $label2;
	if(ref($_[1])) {
        	$Storable::canonical=1;
		$label2 = ($_[1]->isa("RDFStore::Stanford::Literal")) ? $_[1]->getLabel() : nfreeze($_[1]);
        	$Storable::canonical=0;
	} else {
		$label2 = $_[1];
	};

        return ($label1 eq $label2) ? 1 : 0;
};

1;
};

__END__

=head1 NAME

RDFStore::Literal - An implementation of the Literal RDF API using Storable(3)

=head1 SYNOPSIS

	use RDFStore::Literal;
	my $literal = new RDFStore::Literal('Tim Berners-Lee');
        my $literal1 = new RDFStore::Literal('Dan Brickley');

        print $literal->toString." is ";
        print "not"
                unless $literal->equals($literal1);
        print " equal to ".$literal1->toString."\n";
 
        # or using BLOBs...
	my $literal = new RDFStore::Literal([ a,{ d => 'value'}, [ 1,2,3] ]);
        my $literal1 = new RDFStore::Literal([ a,{ d => 'value'}, [ 1,2,3] ]);
 
        print $literal->toString." is ";
        print "not"
                unless $literal->equals($literal1);
        print " equal to ".$literal1->toString."\n";
 

=head1 DESCRIPTION

An RDFStore::Stanford::Literal implementation using Storable(3). A Literal object can either contain plain (utf8) strings or plain BLOBs. Such an implementation allows to create really generic RDF statements about Perl data-structures or objects.

=head1 SEE ALSO

RDFStore::RDFNode(3) RDFStore::Stanford::Literal(3) Storable(3) Digest(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>

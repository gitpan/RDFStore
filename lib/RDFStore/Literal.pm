# *
# *	Copyright (c) 2000 Alberto Reggiori / <alberto.reggiori@jrc.it>
# *	ISIS/RIT, Joint Research Center Ispra (I)
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://xml.jrc.it/RDFStore/LICENSE
# *
# * Changes:
# *     version 0.1 - 2000/11/03 at 04:30 CEST
# *     version 0.2
# *             - modified new() equals(), getLabel() methods accordingly to rdf-api-2000-10-30
# *		- modified toString()
# *     version 0.3
# *             - fixed bugs when checking references/pointers (defined and ref() )
# *

package RDFStore::Literal;
{
use RDFStore::Stanford::Literal;
use RDFStore::RDFNode;

@RDFStore::Literal::ISA = qw( RDFStore::RDFNode RDFStore::Stanford::Literal );

sub new {
	my $self = $_[0]->SUPER::new();
    	$self->{content} = $_[1];
	bless $self,$_[0];
};

sub getLabel {
        return $_[0]->{content};
};

sub toString {
        return $_[0]->{content};
};

sub equals {
	if ($_[0] == $_[1]) {
      		return 1;
    	};
    	if ( (not(defined $_[1])) || ( (ref($_[1])) && (!($_[1]->isa("RDFStore::Stanford::Literal"))) ) ) {
      		return 0;
    	};
	return ($_[0]->{content} eq $_[1]->getLabel()) ? 1 : 0;
};

1;
};

__END__

=head1 NAME

RDFStore::Literal - An implementation of the Literal RDF API

=head1 SYNOPSIS

  use RDFStore::Literal;
  my $literal = new RDFStore::Literal("Ciao neh!!");

=head1 DESCRIPTION

An RDFStore::Stanford::Literal implementation using Digested URIs.

=head1 SEE ALSO

Digest(3)

=head1 AUTHOR

	Alberto Reggiori <alberto.reggiori@jrc.it>

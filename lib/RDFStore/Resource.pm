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
# *
# * Changes:
# *     version 0.1 - 2000/11/03 at 04:30 CEST
# *     version 0.2
# *             - modified new() getURI() getLabel() and added getNamespace() 
# *		  getLocalName()methods accordingly to rdf-api-2000-10-30
# *             - modified toString()
# *     version 0.3
# *             - fixed bugs when checking references/pointers (defined and ref() )
# *

package RDFStore::Resource;
{
use RDFStore::Stanford::Resource;
use RDFStore::RDFNode;

@RDFStore::Resource::ISA = qw( RDFStore::RDFNode RDFStore::Stanford::Resource );

sub new {
	my $self = $_[0]->SUPER::new();
	if(defined $_[2]) {
		$self->{namespace} = $_[1];
		$self->{localName} = $_[2];
	} else {
		$self->{namespace} = undef;
		$self->{localName} = $_[1];
	};
	bless $self,$_[0];
};

sub getURI {
	return (	(exists $_[0]->{namespace}) && (defined $_[0]->{namespace}) ) ?
			$_[0]->{namespace}.$_[0]->{localName} :
			$_[0]->{localName};
};

sub getNamespace {
	return $_[0]->{namespace};
};

sub getLocalName {
	return $_[0]->{localName};
}; 

sub getLabel {
	return $_[0]->getURI();
};

sub toString {
	return $_[0]->getURI();
};

sub equals {
        if ($_[0] == $_[1]) {
                return 1;
        };
        if ( (not(defined $_[1])) || ( (ref($_[1])) && (!($_[1]->isa("RDFStore::Stanford::Resource"))) ) ) {
                return 0;
        };
        return $_[0]->SUPER::equals($_[1]);

	# resources are equal if this.getURI() == that.getURI()
	# the case distinction below is for optimization only to avoid unnecessary string concatenation
	if(!(defined $_[0]->{namespace})) {
        	if(!($_[1]->getNamespace())) {
			return ($_[0]->{localName} eq $_[1]->getLocalName()) ? 1 : 0;
		} else { # maybe "that" did not detect names
			return ($_[0]->{localName} eq $_[1]->getURI()) ? 1 : 0;
		};
	} else {
        	if($_[1]->getNamespace()) {
			return (	($_[0]->{localName} eq $_[1]->getLocalName()) &&
					($_[0]->{namespace} eq $_[1]->getNamespace()) ) ? 1 : 0;
		} else { # maybe "this" did not detect names
			return ($_[0]->getURI() eq $_[1]->getURI()) ? 1 : 0;
		};
	};
	return 0;
};

1;
};

__END__

=head1 NAME

RDFStore::Resource - implementation of the Resource RDF API

=head1 SYNOPSIS

  use RDFStore::Resource;
  my $resource = new RDFStore::Resource("http://pen.jrc.it/idex.html");

=head1 DESCRIPTION

An RDFStore::Stanford::Resource implementation using Digested URIs.

=head1 SEE ALSO

RDFStore::Stanford::Resource(3) Digest(3) RDFStore::RDFNode(3)

=head1 AUTHOR

	Alberto Reggiori <alberto.reggiori@jrc.it>

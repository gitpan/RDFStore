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
# *             - modified createResource() method accordingly to rdf-api-2000-10-30
# *

package RDFStore::NodeFactory;
{
use Carp;
use RDFStore::Stanford::NodeFactory;
use RDFStore::Literal;
use RDFStore::Resource;
use RDFStore::Statement;
use RDFStore::Stanford::Digest::Util;

@RDFStore::NodeFactory::ISA = qw ( RDFStore::Stanford::NodeFactory );

sub new {
    	bless $_[0]->SUPER::new(@_),shift;
};

# Creates a resource from a URI or from namespace and local name
sub createResource {
	if(defined $_[2]) {
		return new RDFStore::Resource($_[1],$_[2]) or
			return undef;
	} else {
		return (defined $_[1]) ? new RDFStore::Resource($_[1]) : undef;
	};
};

# we do not care about data typing in Perl :)
sub createLiteral {
	return (defined $_[1]) ? new RDFStore::Literal($_[1]) : undef;
};

sub createStatement {
	return ( 	(defined $_[1]) && 
			(defined $_[2]) && 
			(defined $_[3]) ) ? new RDFStore::Statement($_[1],$_[2],$_[3]) :
			undef;
};

# Creates a resource with a unique ID
sub createUniqueResource {
	return new RDFStore::Resource("urn:rdf:" .
				RDFStore::Stanford::Digest::Util::computeDigest("SHA-1",rand)->toString);
};

# Creates an ordinal property (rdf:li, rdf:_N)
# to me does not make send hereish - by AR
sub createOrdinal {
	croak "Why do you want to create Ordinals here?\nCould'nt your application be aware of RDF spec and pass the right URI to createResource() instead? :-)";
};

1;
};

__END__

=head1 NAME

RDFStore::NodeFactory - implementation of the NodeFactory RDF API

=head1 SYNOPSIS

	use RDFStore::NodeFactory;
	my $factory = new RDFStore::NodeFactory();
	my $statement = $factory->createStatement(
				$factory->createResource("http://pen.jrc.it"),
  				$factory->createResource("http://purl.org/schema/1.0#author"),
  				$factory->createLiteral("Alberto Reggiori")
				);


=head1 DESCRIPTION

An RDFStore::Stanford::NodeFactory implementation using RDFStore::RDFNode, RDFStore::Resource and RDFStore::Literal

=head1 SEE ALSO

RDFStore::RDFNode(3) RDFStore::Resource(3) RDFStore::Literal(3)

=head1 AUTHOR

	Alberto Reggiori <alberto.reggiori@jrc.it>

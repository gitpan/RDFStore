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
# *		- pass @_ array to new methods
# *     version 0.3
# *             - fixed bugs when checking references/pointers (defined and ref() )
# *     version 0.31
# *             - updated documentation
# *             - fixed the parameters checking when create Statements 
# *     version 0.4
# *             - fixed a few warnings
# *
package RDFStore::Stanford::NodeFactory;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.4';

use RDFStore::Stanford::Literal;
use RDFStore::Stanford::Resource;
use RDFStore::Stanford::Statement;

use Carp;

sub new {
    bless {}, shift;
};

sub createResource {
	return new RDFStore::Stanford::Resource(@_);
};

sub createLiteral {
	return new RDFStore::Stanford::Literal(@_);
};

sub createStatement {
	croak "Subject ".$_[1]." is not instance of RDFStore::Stanford::Resource"
		unless( (ref($_[1])) && ($_[1]->isa('RDFStore::Stanford::Resource')) );
	croak "Predicate ".$_[2]." is not instance of RDFStore::Stanford::Resource"
		unless( (ref($_[2])) && ($_[2]->isa('RDFStore::Stanford::Resource')) );
	croak "Object ".$_[3]." is not instance of RDFStore::Stanford::RDFNode"
		unless( (ref($_[3])) && ($_[3]->isa('RDFStore::Stanford::RDFNode')) );

	return new RDFStore::Stanford::Statement(@_);
};

sub createUniqueResource {
	return new RDFStore::Stanford::Resource(@_);
};

sub createOrdinal {
	croak "Ordinal ".$_[1]." is not an integer"
		unless(int($_[1]));

	return new RDFStore::Stanford::Resource(@_);
};

1;
};

__END__

=head1 NAME

RDFStore::Stanford::NodeFactory - definiton of the NodeFactory RDF API

=head1 SYNOPSIS

  use RDFStore::Stanford::NodeFactory;
  my $factory = new RDFStore::Stanford::NodeFactory();
  my $statement = $factory->createStatement(
				$factory->createResource("http://pen.jrc.it/idex.html"),
  				$factory->createResource("http://rdf.dev.oclc.org/eor/2000/02/26-dcv#","creator"),
  				$factory->createLiteral("Alberto Reggiori")
				);


=head1 DESCRIPTION

This is just the interface definition. If you are more interested to an example implementation see RDFStore::NodeFactory(3)

=head1 SEE ALSO

RDFStore::NodeFactory(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>

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

package RDFStore::VirtualModel;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.4';

use Carp;
use RDFStore::Model;
use RDFStore::Stanford::VirtualModel;

@RDFStore::VirtualModel::ISA = qw( RDFStore::Model RDFStore::Stanford::VirtualModel );

sub new {
	my ($pkg) = shift;
	bless $pkg->SUPER::new(@_), $pkg;
};

sub getGroundModel {
};

1;
};

__END__

=head1 NAME

RDFStore::VirtualModel - implementation of the VirtualModel RDF API

=head1 SYNOPSIS

	use RDFStore::VirtualModel;
        my $virtual = new RDFStore::VirtualModel( Name => 'triples' );

=head1 DESCRIPTION

An RDFStore::Stanford::VirtualModel implementation using RDFStore::Model and Digested URIs.

=head1 SEE ALSO

RDFStore::Stanford::VirtualModel(3) RDFStore::Model(3) Digest(3) and RDFStore::SchemaModel(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>

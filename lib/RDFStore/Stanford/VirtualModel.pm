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
# *     version 0.4
# *             - fixed a few warnings
# *

package RDFStore::Stanford::VirtualModel;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.4';

use RDFStore::Stanford::Model;

@RDFStore::Stanford::SetModel::ISA = qw( RDFStore::Stanford::Model );

sub new {
    bless $_[0]->SUPER::new(), $_[0];
};

sub getGroundModel {
};

1;
};

__END__

=head1 NAME

RDFStore::Stanford::VirtualModel - definiton of the VirtualModel RDF API

=head1 SYNOPSIS

  use RDFStore::Stanford::VirtualModel;
  my $virtual = new RDFStore::Stanford::VirtualModel();

=head1 DESCRIPTION

This is just the interface definition. If you are more interested to an example implementation see RDFStore::VirtualModel(3) or RDFStore::SchemaModel(3)

=head1 SEE ALSO

RDFStore::VirtualModel(3) RDFStore::SchemaModel(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>

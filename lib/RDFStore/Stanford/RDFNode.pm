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
package RDFStore::Stanford::RDFNode;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.4';

sub new {
    bless {}, shift;
};

sub getLabel {
};

1;
};

__END__

=head1 NAME

RDFStore::Stanford::RDFNode - definiton of the RDFNode RDF API

=head1 SYNOPSIS

  use RDFStore::Stanford::RDFNode
  my $node = new RDFStore::Stanford::RDFNode();

=head1 DESCRIPTION

This is just the interface definition. If you are more interested to an example implementation see RDFStore::RDFNode(3)

=head1 SEE ALSO

RDFStore::RDFNode(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>

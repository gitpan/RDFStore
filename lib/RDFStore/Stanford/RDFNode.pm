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
package RDFStore::Stanford::RDFNode;
{

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

	Alberto Reggiori <alberto.reggiori@jrc.it>

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
# *     version 0.31
# *             - updated documentation
# *     version 0.4
# *             - fixed a few warnings
# *

package RDFStore::Stanford::Statement;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.4';

use RDFStore::Stanford::Resource;

@RDFStore::Stanford::Statement::ISA = qw( RDFStore::Stanford::Resource );

sub new {
    bless $_[0]->SUPER::new(), $_[0];
};

sub subject {
};

sub predicate {
};

sub object {
};

1;
};

__END__

=head1 NAME

RDFStore::Stanford::Statement - definiton of the Statement RDF API

=head1 SYNOPSIS

  use RDFStore::Stanford::Statement;
  use RDFStore::Stanford::Literal;
  use RDFStore::Stanford::Resource;
  my $statement = new RDFStore::Stanford::Statement(
  				new RDFStore::Stanford::Resource("http://pen.jrc.it/idex.html"),
  				new RDFStore::Stanford::Resource("http://rdf.dev.oclc.org/eor/2000/02/26-dcv#","creator"),
  				new RDFStore::Stanford::Literal("Alberto Reggiori")
				);


=head1 DESCRIPTION

This is just the interface definition. If you are more interested to an example implementation see RDFStore::Statement(3)

=head1 SEE ALSO

RDFStore::Statement(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>

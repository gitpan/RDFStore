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
package RDFStore::Stanford::Digest::Generic;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.4';

use RDFStore::Stanford::Digest::Abstract;

@RDFStore::Stanford::Digest::Generic::ISA = qw (RDFStore::Stanford::Digest::Abstract);

sub new {
	my ($pkg,$alg,$digest) = @_;
	my $self = $pkg->SUPER::new($digest);
	$self->{algorithm} = $alg;

	bless $self,$pkg;
};

sub getDigestAlgorithm {
	return $_[0]->{algorithm};
};

1;
};

__END__

=head1 NAME

RDFStore::Stanford::Digest::Generic - implementation of the GenericDigest RDF API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

Digest(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>

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
package RDFStore::Stanford::Digest::Generic;
{
use strict;
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

	Alberto Reggiori <alberto.reggiori@jrc.it>

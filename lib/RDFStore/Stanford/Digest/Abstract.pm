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
# *     version 0.3
# *             - fixed bugs when checking references/pointers (defined and ref() )
# *
package RDFStore::Stanford::Digest::Abstract;
{
use strict;
use RDFStore::Stanford::Digest;
use RDFStore::Stanford::Digest::Util;

@RDFStore::Stanford::Digest::Abstract::ISA = qw ( RDFStore::Stanford::Digest );
	
sub new {
	my ($pkg,$digest) = @_;
	my $self = $pkg->SUPER::new();
	$self->{digest} = undef;

	$self->{digest} = ${$digest}
		if(defined $digest);
	
	bless $self,$pkg;
};

sub getDigestBytes {
	# it might need something like $_[0]->{digest_copy} instead of $copy
	my $copy = $_[0]->{digest};
	return \$copy;
};

sub hashCode {
	return RDFStore::Stanford::Digest::Util::digestBytes2HashCode($_[0]->{digest});
};

sub equals {
	return 0
		unless( (ref($_[1])) && ($_[1]->isa("RDFStore::Stanford::Digest")) );

	return RDFStore::Stanford::Digest::Util::equal(\$_[0]->{digest}, \$_[1]->{digest});
};

sub toString {
	return RDFStore::Stanford::Digest::Util::toHexString($_[0]->{digest});
};

1;
};

__END__

=head1 NAME

RDFStore::Stanford::Digest::Abstract - implementation of the AbstractDigest RDF API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

Digest(3)

=head1 AUTHOR

	Alberto Reggiori <alberto.reggiori@jrc.it>

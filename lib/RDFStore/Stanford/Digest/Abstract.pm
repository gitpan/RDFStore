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
# *     version 0.3
# *             - fixed bugs when checking references/pointers (defined and ref() )
# *     version 0.4
# *             - fixed a few warnings
# *
package RDFStore::Stanford::Digest::Abstract;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.4';

use RDFStore::Stanford::Digest;
use RDFStore::Stanford::Digest::Util;

@RDFStore::Stanford::Digest::Abstract::ISA = qw ( RDFStore::Stanford::Digest );
	
sub new {
	my ($pkg,$digest) = @_;
	my $self = $pkg->SUPER::new();

	#$self->{digest} = undef;
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

 my $digest = new RDFStore::Digest::Abstract();
my $bytes = $digest->getDigestBytes();

=head1 DESCRIPTION
 

This is the basic top class for digest classes
 

=head1 METHODS

These are the public methods of this class
 

=over 4
 
=item B<new()>
 
This is the constructor for RDFStore::Stanford::Vocabulary::Generator.
 
=item B<getDigestBytes()>
 
 
Returns the underlying bytes actually representing the digest. E.g. SHA-1 or MD5 byte-string


=back


=head1 SEE ALSO

Digest(3) RDFStore::Digest::Generic(1) RDFStore::Digest::SHA1(1) RDFStore::Digest::MD5(1)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>

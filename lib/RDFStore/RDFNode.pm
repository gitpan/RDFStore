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
# * Changes:
# *     version 0.1 - 2000/11/03 at 04:30 CEST
# *     version 0.2
# *             - modified getDigest() equals() methods accordingly to rdf-api-2000-10-30
# *                 

package RDFStore::RDFNode;
{
use Carp;
use RDFStore::Stanford::RDFNode;
use RDFStore::Stanford::Digest::Util;

@RDFStore::RDFNode::ISA = qw ( RDFStore::Stanford::RDFNode );

sub new {
	my ($pkg,$label) = @_;
	my $self = $pkg->SUPER::new();

	$self->{_alreadyComputedHashcode} = 0;
	$self->{_hashCode} = 0;
	$self->{label} = $label;
	$self->{algorithm} = "SHA-1";
	
	bless $self,$pkg;
};

sub getLabel {
	return $_[0]->{label};
};

sub toString {
	return $_[0]->{label};
};

sub hashCode {
	if($_[0]->{_alreadyComputedHashcode} == 0) {
		$_[0]->{_hashCode} = RDFStore::Stanford::Digest::Util::getHashCode($_[0]->getDigest());
	};
	return $_[0]->{_hashCode}; #this is the key - must check bitwise operations!!!
};

sub getDigest {
	if(not(defined $_[0]->{digest})) {
        	$_[0]->{digest} = RDFStore::Stanford::Digest::Util::computeDigest($_[0]->{algorithm},$_[0]->getLabel())
			or croak "Cannot compute Digest for node ",$_[0]->getLabel();
    	};
    	return $_[0]->{digest};
};

sub equals {
	my $status;
	if($status = RDFStore::Stanford::Digest::Util::equal($_[0]->getDigest()->getDigestBytes(), $_[1]->getDigest()->getDigestBytes())) {
	} else {
		$status= ($_[0]->getLabel() eq $_[1]->getLabel()) ? 1 : 0;
	};
	return $status;
};

1;
};

__END__

=head1 NAME

RDFStore::RDFNode - implementation of the RDFNode RDF API

=head1 SYNOPSIS

  use RDFStore::RDFNode;
  my $node = new RDFStore::RDFNode();

=head1 DESCRIPTION

An RDFStore::Stanford::RDFNode implementation using Digested URIs.

=head1 SEE ALSO

RDFStore::Stanford::RDFNode(3) Digest(3)

=head1 AUTHOR

	Alberto Reggiori <alberto.reggiori@jrc.it>

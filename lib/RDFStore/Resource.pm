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
# * Changes:
# *     version 0.1 - 2000/11/03 at 04:30 CEST
# *     version 0.2
# *             - modified new() getURI() getLabel() and added getNamespace() 
# *		  getLocalName()methods accordingly to rdf-api-2000-10-30
# *             - modified toString()
# *     version 0.3
# *             - fixed bugs when checking references/pointers (defined and ref() )
# *     version 0.4
# *		- added check on local name when create a new Resource
# *		- updated accordingly to rdf-api-2001-01-19
# *		- allow creation of resources from URI(3) objects or strings using XMLNS LocalPart
# *		- hashCode() and getDigest() return separated values for localName and namespace if requested
# *

package RDFStore::Resource;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.4';

use Carp;
use RDFStore::Stanford::Resource;
use RDFStore::RDFNode;

@RDFStore::Resource::ISA = qw( RDFStore::RDFNode RDFStore::Stanford::Resource );

sub new {
	my $self = $_[0]->SUPER::new();

	if(defined $_[2]) {
		$self->{namespace} = $_[1];
		$self->{localName} = $_[2];
	} else {
		croak "Local name cannot be null"
			unless(defined $_[1]);

		my $ln = $_[1];

		#XMLNS LocalPart (see http://www.w3.org/TR/1999/REC-xml-names-19990114/#NT-LocalPart)
		my $NameStrt = "[A-Za-z_:]|[^\\x00-\\x7F]";
		my $NameChar = "[A-Za-z0-9_:.-]|[^\\x00-\\x7F]";
		my $Name = "(?:$NameStrt)(?:$NameChar)*";
		if(	(ref($_[1])) &&
			($_[1]->isa("URI")) ) {
			$self->{localName} = $_[1]->fragment;
			$self->{namespace} = $_[1]->as_string;
			$self->{namespace} =~ s/$self->{localName}$//g;
		} elsif($ln =~ s/($Name)$//g) {
			$self->{localName} = $1;
			$self->{namespace} = $ln;
		} else {
			$self->{namespace} = undef;
			$self->{localName} = $_[1];
		};
	};

	$self->{_hashCode_Namespace} = 0;
	$self->{_hashCode_LocalName} = 0;

	bless $self,$_[0];
};

sub getURI {
	return ($_[0]->getNamespace()) ?
			$_[0]->getNamespace().$_[0]->getLocalName() :
			$_[0]->getLocalName();
};

sub getNamespace {
	return $_[0]->{namespace};
};

sub getLocalName {
	return $_[0]->{localName};
}; 

sub getLabel {
	return $_[0]->getURI();
};

# return the four most significant bytes of the digest
sub hashCode {
	if(wantarray) {
#print STDERR "hashCode - wantarray",((caller)[1]),((caller)[2]),"\n";
		my ($digest_LocalName,$digest_Namespace)=($_[0]->getDigest());
                $_[0]->{_hashCode_Namespace} = RDFStore::Stanford::Digest::Util::getHashCode( $digest_Namespace )
			if($_[0]->{_hashCode_Namespace} == 0);
                $_[0]->{_hashCode_LocalName} = RDFStore::Stanford::Digest::Util::getHashCode( $digest_LocalName )
			if($_[0]->{_hashCode_LocalName} == 0);
        	return ($_[0]->{_hashCode_LocalName}, $_[0]->{_hashCode_Namespace});
	} else {
        	if($_[0]->{_hashCode} == 0) {
                	$_[0]->{_hashCode} = RDFStore::Stanford::Digest::Util::getHashCode( scalar($_[0]->getDigest()) );
        	};
        	return $_[0]->{_hashCode};
	};
};
 
sub getDigest {
	if(wantarray) {
#print STDERR "getDigest - wantarray",((caller)[1]),((caller)[2]),"\n";
        	unless(defined $_[0]->{digest_Namespace}) {
                	$_[0]->{digest_Namespace} = RDFStore::Stanford::Digest::Util::computeDigest(
                        		        &RDFStore::Stanford::Digest::Util::getDigestAlgorithm(),
                               	 		$_[0]->getNamespace() )
                        	or croak "Cannot compute Namespace Digest for node $_[0] ",$_[0]->getLabel();
        	};
        	unless(defined $_[0]->{digest_LocalName}) {
                	$_[0]->{digest_LocalName} = RDFStore::Stanford::Digest::Util::computeDigest(
                        		        &RDFStore::Stanford::Digest::Util::getDigestAlgorithm(),
                               	 		$_[0]->getLocalName() )
                        	or croak "Cannot compute LocalName Digest for node $_[0] ",$_[0]->getLabel();
        	};
        	return ($_[0]->{digest_LocalName},$_[0]->{digest_Namespace});
	} else {
        	unless(defined $_[0]->{digest}) {
                	$_[0]->{digest} = RDFStore::Stanford::Digest::Util::computeDigest(
                        		        &RDFStore::Stanford::Digest::Util::getDigestAlgorithm(),
                               	 		$_[0]->getLabel() )
                        	or croak "Cannot compute Digest for node $_[0] ",$_[0]->getLabel();
        	};
        	return $_[0]->{digest};
	};
};

sub equals {
	return 0
		unless(	(defined $_[1]) &&
			(ref($_[1])) &&
			($_[1]->isa("RDFStore::Stanford::Resource")) );

	# resources are equal if $_[0]->getURI() eq $_[1]->getURI()
	unless($_[0]->getNamespace()) {
        	unless($_[1]->getNamespace()) {
			return ($_[0]->getLocalName() eq $_[1]->getLocalName()) ? 1 : 0;
		} else { # maybe $_[1] did not detect names
			return ($_[0]->getLocalName() eq $_[1]->getURI()) ? 1 : 0;
		};
	} else {
        	if($_[1]->getNamespace()) {
			return (	($_[0]->getLocalName() eq $_[1]->getLocalName()) &&
					($_[0]->getNamespace() eq $_[1]->getNamespace()) ) ? 1 : 0;
		} else { # maybe $_[1] did not detect names
			return ($_[0]->getURI() eq $_[1]->getURI()) ? 1 : 0;
		};
	};
        return $_[0]->SUPER::equals($_[1]);
};

1;
};

__END__

=head1 NAME

RDFStore::Resource - implementation of the Resource RDF API

=head1 SYNOPSIS

	use RDFStore::Resource;
	my $resource = new RDFStore::Resource("http://pen.jrc.it/index.html");
	my $resource1 = new RDFStore::Resource("http://pen.jrc.it/","index.html");

	print $resource->toString." is ";
        print "not"
        	unless $resource->equals($resource1);
        print " equal to ".$resource1->toString."\n";

	# or from URI object	
	use URI;
	$resource = new RDFStore::Resource("http://www.w3.org/1999/02/22-rdf-syntax-ns#","Description");
	$resource1 = new RDFStore::Resource( new URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#Description") );

	print $resource->toString." is ";
        print "not"
        	unless $resource->equals($resource1);
        print " equal to ".$resource1->toString."\n";

=head1 DESCRIPTION

An RDFStore::Stanford::Resource implementation.

=head1 SEE ALSO

RDFStore::Stanford::Resource(3) RDFStore::RDFNode(3) URI(3) Digest(3) 

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>

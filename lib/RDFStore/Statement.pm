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
# * Changes:
# *     version 0.1 - 2000/11/03 at 04:30 CEST
# *     version 0.2
# *             - added getNamespace() getLocalName() methods accordingly to rdf-api-2000-10-30
# *     version 0.3
# *             - fixed bugs when checking references/pointers (defined and ref() )
# *

package RDFStore::Statement;
{
use Carp;
use RDFStore::Stanford::Statement;
use RDFStore::Resource;

@RDFStore::Statement::ISA = qw( RDFStore::Resource RDFStore::Stanford::Statement );

sub new {
    my $self = $_[0]->SUPER::new();
	
    croak "Subject ".$_[1]." is not instance of RDFStore::Stanford::Resource"
                unless( (not(defined $_[1])) ||
                        ( (ref($_[1])) && ($_[1]->isa('RDFStore::Stanford::Resource')) ) );
    croak "Predicate ".$_[2]." is not instance of RDFStore::Stanford::Resource"
                unless( (not(defined $_[2])) ||
                        ( (ref($_[2])) && ($_[2]->isa('RDFStore::Stanford::Resource')) ) );
    croak "Object ".$_[3]." is not instance of RDFStore::Stanford::RDFNode"
                unless( (not(defined $_[3])) ||
                        ( (ref($_[3])) && ($_[3]->isa('RDFStore::Stanford::RDFNode')) ) );

    $self->{subj} = $_[1];
    $self->{pred} = $_[2];
    $self->{obj} = $_[3];

    bless $self,$_[0];
};

sub subject {
	return $_[0]->{subj};
};

sub predicate {
	return $_[0]->{pred};
};

sub object {
	return $_[0]->{obj};
};

# Properties: digest can be constructed given the digests of the pred, subj, obj
# Permutations of the s, p, o return different digests
# see http://nestroy.wi-inf.uni-essen.de/rdf/sum_rdf_api/#K31
sub getDigest {
	if(not(defined $_[0]->{digest})) {
		my $s = $_[0]->{subj}->getDigest()->getDigestBytes();
		my $p = $_[0]->{pred}->getDigest()->getDigestBytes();
		my $o = $_[0]->{obj}->getDigest()->getDigestBytes();

		my $b = ${$s} . ${$p};
		if($_[0]->{obj}->isa("RDFStore::Stanford::Resource")) {
			$b .= ${$o};
                } else { # rotate by one byte
			my @torotate = split(//,${$o});
			push @torotate,shift @torotate; #rotate
			$b .= join(//,@torotate);
                };

                $_[0]->{digest} = RDFStore::Stanford::Digest::Util::computeDigest($_[0]->{algorithm},$b)
                        or croak "Cannot compute Digest for statement ",$_[0]->{label};
        };
        return $_[0]->{digest};
};

sub getURI {
        return "uuid:rdf:".$_[0]->{algorithm}."-".RDFStore::Stanford::Digest::Util::toHexString($_[0]->getDigest());
};

sub getNamespace {
        return undef;
};

sub getLocalName {
        return $_[0]->getURI();
};

sub getLabel {
        return $_[0]->getURI();
};

sub node2string {
	croak "Node ".$_[1]." is not instance of RDFStore::Stanford::RDFNode"
                unless((defined $_[1]) && (ref($_[1])) && ($_[1]->isa('RDFStore::Stanford::RDFNode')));

	if($_[1]->isa("RDFStore::Stanford::Literal")) {
        	return "literal(\"".$_[1]->getLabel() ."\")";
	} elsif($_[1]->isa("RDFStore::Stanford::Statement")) {
        	return $_[1]->toString();
      	} else { # Resource
        	return "\"".$_[1]->getLabel() ."\"";
	};
};

sub toString {
        return "triple(". 	$_[0]->node2string($_[0]->{subj}).", ".
				$_[0]->node2string($_[0]->{pred}).", ".
				$_[0]->node2string($_[0]->{obj}).")";
};

sub equals {
        if ($_[0] == $_[1]) {
                return 1;
        };
        if ( (not(defined $_[1])) || ( (ref($_[1])) && (!($_[1]->isa("RDFStore::Stanford::Statement"))) )  ) {
                return 0;
        };

	# we alwasy assume that is Digestible
        return $_[0]->SUPER::equals($_[1]);
};

1;
};

__END__

=head1 NAME

RDFStore::Statement - implementation of the Statement RDF API from Sergey Melnik (see http://www-db.stanford.edu/~melnik/rdf/api.html)

=head1 SYNOPSIS

  use RDFStore::Statement;
  use RDFStore::Literal;
  use RDFStore::Resource;
  my $statement = new RDFStore::Statement(
  				new RDFStore::Resource("http://pen.jrc.it/idex.html"),
  				new RDFStore::Resource("author","http://purl.org/schema/1.0#"),
  				new RDFStore::Literal("Alberto Reggiori")
				);


=head1 DESCRIPTION

An RDFStore::Stanford::Statement implementation using Digested URIs.

=head1 SEE ALSO

RDFStore::Stanford::Statement(3) Digest(3) RDFStore::RDFNode(3)

=head1 AUTHOR

	Alberto Reggiori <alberto.reggiori@jrc.it>

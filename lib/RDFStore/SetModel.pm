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
# *		- fixed bug in intersect()
# *		- now all methods return the modified model
# *     version 0.3
# *		- fixed bug in intersect() when checking parameter
# *		- fixed bugs when checking references/pointers (defined and ref() )
# *

package RDFStore::SetModel;
{
use RDFStore::Model;
use RDFStore::Stanford::SetModel;
use Carp;

@RDFStore::SetModel::ISA = qw( RDFStore::Model RDFStore::Stanford::SetModel );

sub new {
        my ($pkg) = shift;
        bless $pkg->SUPER::new(@_), $pkg;
};                                

sub intersect {
	croak "Model ".$_[1]." is not instance of RDFStore::Stanford::Model"
		unless( (defined $_[1]) && (ref($_[1])) &&
			($_[1]->isa('RDFStore::Stanford::Model')) );

	# this operation should atomic (use a "monitor"/lock thingie)
	my $tmp = $_[0]->duplicate();

	my $k;
	my $v;
	while (($k,$v) = each %{$tmp->elements()}) {
		$_[0]->remove($v)
			if(!($_[1]->contains($v)));
	};
	return $_[0];
};

sub subtract {
	croak "Model ".$_[1]." is not instance of RDFStore::Stanford::Model"
		unless( (defined $_[1]) && (ref($_[1])) &&
			($_[1]->isa('RDFStore::Stanford::Model')) );

	# this operation should atomic (use a "monitor"/lock thingie)
	my $k;
	my $v;
	while (($k,$v) = each %{$_[1]->elements()}) {
		$_[0]->remove($v);
	};
	return $_[0];
};

sub unite {
	croak "Model ".$_[1]." is not instance of RDFStore::Stanford::Model"
		unless( (defined $_[1]) && (ref($_[1])) &&
			($_[1]->isa('RDFStore::Stanford::Model')) );

	# this operation should atomic (use a "monitor"/lock thingie)
	my $k;
	my $v;
	while (($k,$v) = each %{$_[1]->elements()}) {
		$_[0]->add($v);
	};
	return $_[0];
};

1;
};

__END__

=head1 NAME

RDFStore::SetModel - implementation of the SetModel RDF API

=head1 SYNOPSIS

	use RDFStore::SetModel;
        use RDFStore::NodeFactory;
        use RDFStore::FindIndex;
        use Data::MagicTie;

        my $factory= new RDFStore::NodeFactory();
        my $index_db={};
        tie %{$index_db},"Data::MagicTie",'index/triples',(Q => 20);
        my $index=new RDFStore::FindIndex($index_db);
	my $set = new RDFStore::SetModel($factory,undef,$index,undef);

=head1 DESCRIPTION

An RDFStore::Stanford::SetModel implementation using RDFStore::Model and Digested URIs.

=head1 SEE ALSO

RDFStore::Stanford::SetModel(3) RDFStore::Model(3) Digest(3)

=head1 AUTHOR

	Alberto Reggiori <alberto.reggiori@jrc.it>

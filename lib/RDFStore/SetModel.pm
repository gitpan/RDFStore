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
# *		- fixed bug in intersect()
# *		- now all methods return the modified model
# *     version 0.3
# *		- fixed bug in intersect() when checking parameter
# *		- fixed bugs when checking references/pointers (defined and ref() )
# *     version 0.4
# *		- updated accordingly to new RDFStore::Model
# *     version 0.42
# *		- updated accordingly to new RDFStore::Model
# *

package RDFStore::SetModel;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.42';

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

	# this operation should atomic (use a monitor/lock thingie)
	my($tmp)= $_[0]->duplicate();
	($tmp)=$tmp->elements;

	return 
		unless(	(defined $tmp) &&
			(ref($tmp)=~/ARRAY/) );

	my $fetch;
	foreach( @{$tmp} ) {
		$fetch=$_; #we avoid too many fetches from RDFStore::Model::Statements
		$_[0]->remove($fetch)
			if(!($_[1]->contains($fetch)));
	};
	return $_[0];
};

sub subtract {
	croak "Model ".$_[1]." is not instance of RDFStore::Stanford::Model"
		unless( (defined $_[1]) && (ref($_[1])) &&
			($_[1]->isa('RDFStore::Stanford::Model')) );

	my($m)= $_[1]->elements;

	return 
		unless(	(defined $m) &&
			(ref($m)=~/ARRAY/) );

	my $fetch;
	foreach ( @{$m} ) {
		$fetch=$_; #we avoid too many fetches from RDFStore::Model::Statements
		$_[0]->remove($fetch);
	};
	return $_[0];
};

sub unite {
	croak "Model ".$_[1]." is not instance of RDFStore::Stanford::Model"
		unless( (defined $_[1]) && (ref($_[1])) &&
			($_[1]->isa('RDFStore::Stanford::Model')) );

	my($m)= $_[1]->elements;

	return 
		unless(	(defined $m) &&
			(ref($m)=~/ARRAY/) );

	my $fetch;
	foreach( @{$m} ) {
		$fetch=$_; #we avoid too many fetches from RDFStore::Model::Statements
		$_[0]->add($fetch);
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
        my $factory= new RDFStore::NodeFactory();
	my $set = new RDFStore::SetModel( Name => 'triples', Split => 9 );

	$set=$set->interset($other_model);
	$set=$set->unite($other_model);
	$set=$set->subtract($other_model);

=head1 DESCRIPTION

An RDFStore::Stanford::SetModel implementation using RDFStore::Model.

=head1 SEE ALSO

RDFStore::Stanford::SetModel(3) RDFStore::Model(3) Digest(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>

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
# *		- fixed miss-spelling bug in remove()
# *		- added indirect indexing support to be de-referenced by the caller Model object.
# *		  i.e. the FindIndex structure does not store Statements BLOBs but just their digested keys
# *		  This solution should save a lot of disk space :-)
# *		  NOTE: such an approach assumes that FindIndex indexes Statements by using the same 
# *		  key-function of the Model actually using the index.
# *     version 0.3
# *             - fixed bugs when checking references/pointers (defined and ref() )
# *     version 0.31
# *		- added new index storage method. Does not use Freezed/Thawed arrays  if possible
# *

package RDFStore::FindIndex;
{
use Carp;
use Data::MagicTie;
use RDFStore::Stanford::Digest::Util;

sub new {
	my ($pkg,$indexesToTreemapsOfStatements)=@_;

	my $self={};

	if(	(defined $indexesToTreemapsOfStatements) &&
		(ref($indexesToTreemapsOfStatements) =~ /HASH/) ) {
		$self->{_indexesToTreemapsOfStatements} = $indexesToTreemapsOfStatements;
	} else {
		#tie them local/remote otherwise in-memory :-)
		$self->{_indexesToTreemapsOfStatements} = {};
	};
	my $istied;
	if($istied=tied %{$self->{_indexesToTreemapsOfStatements}}) {
		my $options = $istied->get_Options();
		if($options->{noft} eq '1' ) {
			$self->{indexisnotFT} = 1;
		} else {
			$self->{indexisnotFT} = 0;
		};
	} else {
		$self->{indexisnotFT} = 0;
	};
	
	bless $self,$pkg;
};

# not really needed - we have tied hashes :)
# this means that in-menory and/or persistent indexes are really transparent to the user
sub size {
};

sub addLookup {
	croak "Statement ".$_[1]." is not an instance of RDFStore::Stanford::Statement"
                unless( (defined $_[1]) && (ref($_[1])) && ($_[1]->isa('RDFStore::Stanford::Statement')) );

	my $subject = $_[1]->subject();
	my $predicate = $_[1]->predicate();
	my $object = $_[1]->object();

	# add look ups here...
	$_[0]->put($_[0]->getLookupValue($subject,undef,undef), $_[1]);
	$_[0]->put($_[0]->getLookupValue(undef,$predicate,undef), $_[1]);
	$_[0]->put($_[0]->getLookupValue(undef,undef,$object), $_[1]);
	$_[0]->put($_[0]->getLookupValue(undef,$predicate,$object), $_[1]);
	$_[0]->put($_[0]->getLookupValue($subject,undef,$object), $_[1]);
	$_[0]->put($_[0]->getLookupValue($subject,$predicate,undef), $_[1]);
	$_[0]->put($_[0]->getLookupValue($subject,$predicate,$object), $_[1]);
};

sub removeLookup {
	croak "Statement ".$_[1]." is not an instance of RDFStore::Stanford::Statement"
                unless((defined $_[1]) && (ref($_[1])) && ($_[1]->isa('RDFStore::Stanford::Statement')));

	my $subject = $_[1]->subject();
	my $predicate = $_[1]->predicate();
	my $object = $_[1]->object();

	#remove it
	$_[0]->remove($_[0]->getLookupValue($subject,undef,undef), $_[1]);
	$_[0]->remove($_[0]->getLookupValue(undef,$predicate,undef), $_[1]);
	$_[0]->remove($_[0]->getLookupValue(undef,undef,$object), $_[1]);
	$_[0]->remove($_[0]->getLookupValue(undef,$predicate,$object), $_[1]);
	$_[0]->remove($_[0]->getLookupValue($subject,undef,$object), $_[1]);
	$_[0]->remove($_[0]->getLookupValue($subject,$predicate,undef), $_[1]);
	$_[0]->remove($_[0]->getLookupValue($subject,$predicate,$object), $_[1]);
};

sub multiget {
	croak "Subject ".$_[1]." is not an instance of RDFStore::Stanford::Resource"
                unless((not(defined $_[1])) || ( (ref($_[1])) && ($_[1]->isa('RDFStore::Stanford::Resource')) ));
	croak "Predicate ".$_[2]." is not an instance of RDFStore::Stanford::Resource"
                unless((not(defined $_[2])) || ( (ref($_[2])) && ($_[2]->isa('RDFStore::Stanford::Resource')) ));
	croak "Object ".$_[3]." is not an instance of RDFStore::Stanford::RDFNode"
                unless((not(defined $_[3])) || ( (ref($_[3])) && ($_[3]->isa('RDFStore::Stanford::RDFNode')) ));

	# return ARRAY reference
	my $stuff = $_[0]->{_indexesToTreemapsOfStatements}->{ 
				$_[0]->getLookupValue($_[1],$_[2],$_[3]) }; #FETCH

	if($_[0]->{indexisnotFT}) {
		my @stuff = split(',',$stuff);
		$stuff = \@stuff;
	};
#print STDERR "multiget('",join(',',map { s/\-//g; $_; } @{$stuff}),"')\n";

	return $stuff;
};

sub put {
	croak "Index ".$_[1]." is not an integer"
		unless(int($_[1]));
	croak "Statement ".$_[2]." is not an instance of RDFStore::Stanford::Statement"
                unless((defined $_[2]) && (ref($_[2])) && ($_[2]->isa('RDFStore::Stanford::Statement')));

	my $code = $_[2]->hashCode();

	my $stuff = $_[0]->{_indexesToTreemapsOfStatements}->{$_[1]}; #FETCH

	my $isarray = (defined $stuff) && (ref($stuff) =~ /ARRAY/);
	if( ($_[0]->{indexisnotFT}) && (!($isarray)) ) {
		my @stuff = split(',',$stuff);
		push @stuff,$code
			unless(grep /$code/,@stuff); # add an indirect reference
        	$_[0]->{_indexesToTreemapsOfStatements}->{$_[1]} = join(',',@stuff); #STORE
	} else {
        	$stuff = []
			unless($isarray);

        	#do it
        	push @{$stuff}, $code
			unless(grep /$code/,@{$stuff}); # add an indirect reference

        	$_[0]->{_indexesToTreemapsOfStatements}->{$_[1]} = $stuff; #STORE
	};
};

sub remove {
	croak "Index ".$_[1]." is not an integer"
		unless(int($_[1]));
	croak "Statement ".$_[2]." is not an instance of RDFStore::Stanford::Statement"
                unless((defined $_[2]) && (ref($_[2])) && ($_[2]->isa('RDFStore::Stanford::Statement')));

	my $code = $_[2]->hashCode();

	my $stuff = $_[0]->{_indexesToTreemapsOfStatements}->{$_[1]}; #FETCH

	my $isarray = (defined $stuff) && (ref($stuff) =~ /ARRAY/);
	if( ($_[0]->{indexisnotFT}) && (!($isarray)) ) {
		my @stuff = split(',',$stuff);
        	@stuff = grep !/$code/,@stuff; # zap indirect reference
        	if(scalar(@stuff)>0) {
        		$_[0]->{_indexesToTreemapsOfStatements}->{$_[1]} = join(',',@stuff); #STORE
        	} else {
                	#zap the list
                	delete $_[0]->{_indexesToTreemapsOfStatements}->{$_[1]};
        	};
	} else {
        	#do it
        	@{$stuff} = grep !/$code/,@{$stuff}; # zap indirect reference

        	if(scalar(@{$stuff})>0) {
                	$_[0]->{_indexesToTreemapsOfStatements}->{$_[1]} = $stuff; #STORE
        	} else {
                	#zap the list
                	delete $_[0]->{_indexesToTreemapsOfStatements}->{$_[1]};
        	};
	};
};

sub getLookupValue {
	croak "Subject ".$_[1]." is not an instance of RDFStore::Stanford::Resource"
                unless((not(defined $_[1])) || ( (ref($_[1])) && ($_[1]->isa('RDFStore::Stanford::Resource')) ));
	croak "Predicate ".$_[2]." is not an instance of RDFStore::Stanford::Resource"
                unless((not(defined $_[2])) || ( (ref($_[2])) && ($_[2]->isa('RDFStore::Stanford::Resource')) ));
	croak "Object ".$_[3]." is not an instance of RDFStore::Stanford::RDFNode"
                unless((not(defined $_[3])) || ( (ref($_[3])) && ($_[3]->isa('RDFStore::Stanford::RDFNode')) ));

	my $s1 = (defined $_[1]) ? $_[1]->hashCode() : 0;
	my $s2 = (defined $_[2]) ? $_[2]->hashCode() : 0;
	my $s3 = (defined $_[3]) ? $_[3]->hashCode() : 0;

	#cool!
  	return int( ($s1 * 37 + $s2) * 37 + $s3 );
};

1;
};

__END__

=head1 NAME

RDFStore::FindIndex - implementation of the FindIndex RDF API

=head1 SYNOPSIS

	use RDFStore::FindIndex;
	my $myindex = new RDFStore::FindIndex({});

	use Data::MagicTie;
	tie %index,"Data::MagicTie",'index';
	my $mypresistentindex = new RDFStore::FindIndex(\%index);

=head1 DESCRIPTION

This modules implement a very simple and dirty indexing for RDFStore::Stanford::Statement(s) using three hashes
one indexing by subject, one by predicate one by object. Each hash contain a copy of the statement
actually containing such a subject, predicate or object. It is not really efficient due the fact that it
requires to keep as value in hashes a copy of the BLOBed statement - see Data::MagicTie(3)

An instance of RDFStore::FindIndex can be passed to RDFStore::Model to help it searching the RDF triplets store.

=head1 SEE ALSO

Data::MagicTie(3) RDFStore::Model(3)

=head1 AUTHOR

	Alberto Reggiori <alberto.reggiori@jrc.it>

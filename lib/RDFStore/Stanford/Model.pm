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
# *     version 0.3
# * 		- fixed bugs when checking references/pointers (defined and ref() )
# *     version 0.31
# *		- updated documentation
# *     version 0.4
# *             - fixed a few warnings
# *
package RDFStore::Stanford::Model;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.4';

use RDFStore::Stanford::RDFNode;
use RDFStore::Stanford::Resource;
use RDFStore::Stanford::Literal;
use RDFStore::Stanford::Statement;

use Carp;

@RDFStore::Stanford::Model::ISA = qw( RDFStore::Stanford::Resource );

sub new {
    bless $_[0]->SUPER::new(), $_[0];
};

sub setSourceURI {
};

sub getSourceURI {
};

sub size {
};

sub isEmpty {
};

sub elements {
};

sub contains {
	croak "Statement ".$_[1]." is not instance of RDFStore::Stanford::Statement"
		unless( (not(defined $_[1])) ||
			( (ref($_[1])) && ($_[1]->isa('RDFStore::Stanford::Statement')) ) );
};

sub add {
	croak "Statement ".$_[1]." is not instance of RDFStore::Stanford::Statement"
		unless( (not(defined $_[1])) ||
			( (ref($_[1])) && ($_[1]->isa('RDFStore::Stanford::Statement')) ) );
};

sub remove {
	croak "Statement ".$_[1]." is not instance of RDFStore::Stanford::Statement"
		unless( (not(defined $_[1])) ||
			( (ref($_[1])) && ($_[1]->isa('RDFStore::Stanford::Statement')) ) );
};

sub isMutable {
};

sub find {
	croak "Subject ".$_[1]." is not instance of RDFStore::Stanford::Resource"
		unless( (not(defined $_[1])) ||
			( (ref($_[1])) && ($_[1]->isa('RDFStore::Stanford::Resource')) ) );
	croak "Predicate ".$_[2]." is not instance of RDFStore::Stanford::Resource"
		unless( (not(defined $_[2])) ||
			( (ref($_[2])) && ($_[2]->isa('RDFStore::Stanford::Resource')) ) );
	croak "Object ".$_[3]." is not instance of RDFStore::Stanford::RDFNode"
		unless( (not(defined $_[3])) ||
			( (ref($_[3])) && ($_[3]->isa('RDFStore::Stanford::RDFNode')) ) );
};

sub duplicate {
};

sub create {
};

sub getNodeFactory {
};

1;
};

__END__

=head1 NAME

RDFStore::Stanford::Model - definiton of the Model RDF API

=head1 SYNOPSIS

	use RDFStore::Stanford::Model;
	use RDFStore::Stanford::Literal;
	use RDFStore::Stanford::Resource;
	use RDFStore::Stanford::Statement;
	my $model = new RDFStore::Stanford::Model();
	my $obj = new RDFStore::Stanford::Literal("foo");
	my $subj = new RDFStore::Stanford::Literal("http://www.foo.com");
	my $pred = new RDFStore::Stanford::Literal("http://rdf.dev.oclc.org/eor/2000/02/26-dcv#","creator");
	my $fact= new RDFStore::Stanford::Statement($subj, $pred, $obj);
	$model->add($fact);
	my $result_model = $model->find($fact);
	

=head1 DESCRIPTION

This is just the interface definition. If you are more interested to an example implementation see RDFStore::Model(3)

=head1 SEE ALSO

RDFStore::Model(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>

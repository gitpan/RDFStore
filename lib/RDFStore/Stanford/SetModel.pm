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
# * Changes:
# *     version 0.1 - 2000/11/03 at 04:30 CEST
# *     version 0.3
# *             - fixed bugs when checking references/pointers (defined and ref() )
# *     version 0.31
# *             - updated documentation 
# *     version 0.4
# *             - fixed a few warnings
# *

package RDFStore::Stanford::SetModel;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.4';

use RDFStore::Stanford::Model;

use Carp;

@RDFStore::Stanford::SetModel::ISA = qw( RDFStore::Stanford::Model );

sub new {
    bless $_[0]->SUPER::new(), $_[0];
};

sub intersect {
	croak "Model ".$_[1]." is not instance of RDFStore::Stanford::Model"
		unless( (not(defined $_[1])) ||
			( (ref($_[1])) && ($_[1]->isa('RDFStore::Stanford::Model')) ) );
};

sub subtract {
	croak "Model ".$_[1]." is not instance of RDFStore::Stanford::Model"
		unless( (not(defined $_[1])) ||
			( (ref($_[1])) && ($_[1]->isa('RDFStore::Stanford::Model')) ) );
};

sub unite {
	croak "Model ".$_[1]." is not instance of RDFStore::Stanford::Model"
		unless( (not(defined $_[1])) ||
			( (ref($_[1])) && ($_[1]->isa('RDFStore::Stanford::Model')) ) );
};

1;
};

__END__

=head1 NAME

RDFStore::Stanford::SetModel - definiton of the SetModel RDF API

=head1 SYNOPSIS

	use RDFStore::Stanford::SetModel;
        use RDFStore::Stanford::Literal;
        use RDFStore::Stanford::Resource;
        use RDFStore::Stanford::Statement;
        my $set = new RDFStore::Stanford::Model();
        my $obj = new RDFStore::Stanford::Literal("foo");
        my $subj = new RDFStore::Stanford::Literal("http://www.foo.com");
        my $subj1 = new RDFStore::Stanford::Literal("http://www.bar.com");
        my $pred = new RDFStore::Stanford::Literal("http://rdf.dev.oclc.org/eor/2000/02/26-dcv#","creator");
        my $fact= new RDFStore::Stanford::Statement($subj, $pred, $obj);
        my $fact1= new RDFStore::Stanford::Statement($subj1, $pred, $obj);
        $set->add($fact);
        my $result_model = $set->find($fact);
	$set->subtract($fact1);
	

=head1 DESCRIPTION

This is just the interface definition. If you are more interested to an example implementation see RDFStore::SetModel(3)

=head1 SEE ALSO

RDFStore::SetModel(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>

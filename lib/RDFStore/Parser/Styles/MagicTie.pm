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
# *     version 0.2
# *             - Init() now setSourceURI() for the model
# *		- now the result set is a SetModel
# *     version 0.3
# *		- fixed bug in Assert() checking if $st is a ref and valid RDFStore::Stanford::Statement
# *     version 0.31
# *		- updated documentation
# *     version 0.4
# *		- modified Assert() to print only new statements
# *		- fixed a few warnings
# *		- updated accordingly to new RDFStore::Model
# *

package RDFStore::Parser::Styles::MagicTie;
{
use strict;
use RDFStore::SetModel;
use Carp;

sub Init {
    my $expat = shift;

	$expat->{RDFStore_model} = new RDFStore::SetModel( 
					nodeFactory => $expat->{PenRDF}->{nodeFactory}, 
					%{$expat->{store}->{options}} );
	$expat->{RDFStore_model}->setSourceURI($expat->{Source})
		if(	(exists $expat->{Source}) && 
			(defined $expat->{Source}) );
};

sub Final {
    my $expat = shift;

	return $expat->{RDFStore_model};
};

# input: either Expat valid QNames or "assertions" (statements)
# output: "assertions" (statements)
# David Megginson saying that this is bad it is better Start/Stop Resource/Property
# anyway it should look like: Assert(subjectType,subject,predicate,objectType,object,lang)
# (see http://lists.w3.org/Archives/Public/www-rdf-interest/1999Dec/0045.html)
sub Assert {
	my ($expat,$st) = @_;

	#if($expat->{RDFStore_model}->add($st)) {
	#	print $st->toString,"\n"
	#		if( (defined $st) && (ref($st)) && ($st->isa("RDFStore::Stanford::Statement")) && (defined $expat->{store}->{seevalues}) );
	#};

	# we should print just the new ones
	print $st->toString,"\n"
                if(	(defined $st) && 
			(ref($st)) && 
			($st->isa("RDFStore::Stanford::Statement")) && 
			(defined $expat->{store}->{seevalues}) );

        $expat->{RDFStore_model}->add($st);
};

# we might use this callback for XSLT tansofrmations of xml-blobs :)
sub Start_XML_Literal {
	my ($expat,$tag,%attlist) = @_;

	return $expat->recognized_string; # cool eh ;-)
};

sub Stop_XML_Literal {
	my ($expat,$tag) = @_;

	return $expat->recognized_string;
};

sub Char_Literal {
	my ($expat,$literal_text) = @_;

	#return $literal_text;
	return $expat->recognized_string;
};

1;
}

package RDFStore::Parser::Styles::Mysql; # any ? ;-)

__END__

=head1 NAME

RDFStore::Parser::Styles::MagicTie - This module is an extension of RDFStore::Parser::SiRPAC(3) that actually use the RDFStore API modules to ingest records into an RDFStore database.

=head1 SYNOPSIS

 
use RDFStore::Parser::SiRPAC;
use RDFStore::Parser::Styles::MagicTie;
use RDFStore::NodeFactory;
my $p=new RDFStore::Parser::SiRPAC(	ErrorContext => 2,
                                Style => 'RDFStore::Parser::Styles::MagicTie',
                                NodeFactory     => new RDFStore::DBMS::NodeFactory()
                                );

if(defined $ENV{GATEWAY_INTERFACE}) {
        print "Content-type: text/html

";
        $p->parsefile($ENV{QUERY_STRING});
} else {
        my $input = shift;
        if($input =~ /^-/) {
                $p->parse(*STDIN);
        } else {
                $p->parsefile($input);
        };
};

=head1 DESCRIPTION

In the samples directory of the distribution you can find a set of a sample scripts to play with :)

=head1 METHODS

=over 4

=item new

This is a class method, the constructor for RDFStore::Parser::SiRPAC. B<Options> are passed as key/value pairs. RDFStore::Parser::Styles::MagicTie supports B<all> the RDFStore::Parser::SiRPAC options plus the following:

=over 5

=item * store

This option if present must point to an HASH reference. Recognized options are:

=item * persistent

This option specify if the RDFStore::Stanford::Statement objects generated during parsing must be stored in some kind of RDFStore. It is a SCALAR with possible values of 0 or 1.

=item * seevalues

This options is a SCALAR with possible values of 0/1 and flags whether the parsing is verbose or not (print triples)

=item * directory

This option specify the output directory where the actual DB files are generated when the I<persistent>
option is set.

=item * options

This option if present must point to an HASH reference and helps the user to specify the
Data::MagicTie options about storage of the RDFStore::Stanford::Statement statements when the I<persistent> option is set. See Data::MagicTie(3)

=head1 BUGS

None known yet

=head1 SEE ALSO

RDFStore::Parser::SiRPAC(3), RDFStore(3), RDFStore::Model(3) Data::MagicTie(3) DBMS(3)

=head1 AUTHOR

Alberto Reggiori <areggiori@webweaving.org>

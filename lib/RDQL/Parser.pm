# *
# *     Copyright (c) 2000-2004 Alberto Reggiori <areggiori@webweaving.org>
# *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *
# * Changes:
# *     version 0.1
# *		- first hacked version: pure perl RDQL/SquishQL top-down LL(1) parser with some extesnions:
# *                  * LIKE operator in AND clause
# *                  * free-text triple matching like (?x, ?y, %"whatever"%)
# *

package RDQL::Parser;
{

use vars qw ( $VERSION );
use strict;
use Carp;

$VERSION = '0.1';

sub parse ($$);
sub MatchAndEat ($$);
sub error ($$);
sub SelectClause ($);
sub SourceClause ($);
sub TriplePatternClause ($);
sub Var ($);
sub URL ($);
sub Literal ($);
sub TriplePattern ($);
sub VarOrURI ($);
sub VarOrURIOrLiteral ($);
sub ConstraintClause ($);
sub PrefixesClause ($);
sub PrefixDecl ($);
sub ConditionalOrExpression ($);
sub ConditionalAndExpression ($);
sub StringEqualityExpression ($);
sub InclusiveOrExpression ($);
sub ExclusiveOrExpression ($);
sub AndExpression ($);
sub EqualityExpression ($);
sub RelationalExpression ($);
sub ShiftExpression ($);
sub AdditiveExpression ($);
sub MultiplicativeExpression ($);
sub UnaryExpression ($);
sub UnaryExpressionNotPlusMinus ($);
sub PrimaryExpression ($);
sub FunctionCall ($);
sub ArgList ($);

sub new {
	bless {
		prefixes	=>	{},
		sources		=>	[],
		resultVars	=>	[],
		triplePatterns	=>	[],
		constraints	=>	[]
	}, shift;
};

sub MatchAndEat ($$) {
	my($lit)=$_[1];
	return s/^\s*\Q$lit\E\s*//i;
};

sub error($$) {
	my($class,$msg)=@_;
	croak "error: $msg: $_\n";
};

sub parse($$) {
	my($class,$query) = @_;

	$_=$query;
	
	if( MatchAndEat $class,'/*') {
		while( ! MatchAndEat $class,'*/' ) {
			s/^\s*(.)\s*//;
		};
	};

	SelectClause $class
		if( MatchAndEat $class,'select');
	SourceClause $class
		if(	MatchAndEat $class,'source' or
			MatchAndEat $class,'from' );
	TriplePatternClause $class
		if( MatchAndEat $class,'where');
	ConstraintClause $class
		if( MatchAndEat $class,'and');
	PrefixesClause $class
		if( MatchAndEat $class,'using');

	error $class,'illegal input'
		if($_ ne '');

	#use Data::Dumper;
	#print Dumper($class);
};

sub SelectClause($) {
	my($class) = @_;

	$class->{select_context}=[];
	if( MatchAndEat $class,'*') {
		push @{$class->{resultVars}},'*';
	} elsif( Var $class ) {
		do {
			MatchAndEat $class,',';
			} while ( Var $class );
	};
	delete($class->{select_context});
};

sub Var($) {
	my($class) = @_;

	if(s/^\s*(\?[a-zA-Z0-9_\$\.]+)\s*//) {
		if(exists $class->{select_context}) {
			push @{$class->{resultVars}},$1
				unless(grep /^\Q$1\E$/,@{$class->{resultVars}});
		};
		if(exists $class->{triples_context}) {
			push @{$class->{triples_context}}, $1;
		} elsif(exists $class->{constraints_context}) {
			push @{$class->{constraints}}, $1;
		};
		return 1;
	};
	return 0;
};

sub SourceClause($) {
	my($class) = @_;

	$class->{source_context}=1;
	if( URL $class ) {
		do {
                        MatchAndEat $class,',';
                        } while ( URL $class );
	} else {
		error $class, "malformed URI";
	};
	delete($class->{source_context});
};

sub URL($) {
	my($class) = @_;

	my $uri;
	# the following covers also RDFStore/RDQL extensions for OR-ing < URL1 , URL2 , URL3 .... > and < "string a" , "literal b" .... >
	#if(s/^\s*((\<[^>]*\>)|([a-zA-Z0-9\-_$\.]+:[a-zA-Z0-9\-_$\.]+)|([a-zA-Z0-9\-_$\.]+:))\s*//) {
	if(s/^\s*(\<[^>]*\>)\s*//) { #not yet the above - but we are NOT RDQL compliant then - no QNames (need to fix all the DBD driver too then)
		if(exists $class->{triples_context}) {
			push @{$class->{triples_context}}, $1;
		} elsif(exists $class->{source_context}) {
			push @{$class->{sources}}, $1;
		} elsif(exists $class->{constraints_context}) {
			push @{$class->{constraints}}, $1;
		};
		return 1;
	};
	return 0;
};

sub Literal($) {
	my($class) = @_;

	if(	(s/^\s*([1-9][0-9]*)\s*//) or
		(s/^\s*(0[xX]([0-9",a-f,A-F])+)\s*//) or
		#(s/^\s*(0[0-7]*)\s*//) or
		(s/^\s*(([0-9]+\.[0-9]*([eE][+-]?[0-9]+)?[fFdD]?)|(\.[0-9]+([eE][+-]?[0-9]+)?[fFdD]?)|([0-9]+[eE][+-]?[0-9]+[fFdD]?)|([0-9]+([eE][+-]?[0-9]+)?[fFdD]))\s*//) or
		#(s/^\s*(%?\'((([^\'\\\n\r])|(\\([ntbrf\\'\"])|([0-7][0-7?)|([0-3][0-7][0-7]))))\'%?)\s*//) or
		(s/^\s*(%?[\"\']((([^\"\'\\\n\r])|(\\([ntbrf\\'\"])|([0-7][0-7?)|([0-3][0-7][0-7])))*)[\"\'](\@([a-z0-9]+(-[a-z0-9]+)?))?%?)\s*//) or
		(s/^\s*(true|false)\s*//) or
		(s/^\s*(null)\s*//) ) {
		if(exists $class->{triples_context}) {
			push @{$class->{triples_context}}, $1;
		} elsif(exists $class->{constraints_context}) {
			push @{$class->{constraints}}, $1;
		};
		return 1;
	};
	return 0;
};

sub TriplePatternClause($) {
	my($class) = @_;

        while ( TriplePattern $class ) {
		MatchAndEat $class,',';
		};
};

sub TriplePattern($) {
	my($class) = @_;

	$class->{triples_context}=[];
	if( MatchAndEat $class,'(' ) {
		error $class,"malformed subject variable or URL"
			unless VarOrURI $class; #subject

		MatchAndEat $class,',';
		error $class,"malformed predicate variable or URL"
			unless VarOrURI $class; #predicate

		MatchAndEat $class,',';
		error $class,"malformed object variable, URL or just literal"
			unless VarOrURIOrLiteral $class; #object

		MatchAndEat $class,',';
		VarOrURIOrLiteral $class; #context

		error $class,"missing right round bracket"
			unless( MatchAndEat $class,')' );

		push @{$class->{triplePatterns}}, $class->{triples_context};
		delete($class->{triples_context});

		return 1;
	} else {
		delete($class->{triples_context});

		return 0;
	};
};

sub VarOrURI($) {
	my($class) = @_;

	return ( Var $class or URL $class );
};

sub VarOrURIOrLiteral($) {
	my($class) = @_;

	return ( Var $class or URL $class or Literal $class );
};

sub PrefixesClause($) {
	my($class) = @_;

	while( PrefixDecl $class ) {
		MatchAndEat $class,',';
		};
};

sub PrefixDecl($) {
	my($class) = @_;

	my $uri;
	if(s/^\s*(\w[\w\d]*)\s+FOR\s+\<([A-Za-z][^>]*)\>\s*//i) {
		$class->{prefixes}->{$1}=$2;
		return 1;
	};
	return 0;
};

sub ConstraintClause($) {
	my($class) = @_;

	$class->{constraints_context}=1;

	ConditionalOrExpression $class;
	while(	MatchAndEat $class,',' or
		MatchAndEat $class,'and') {
		push @{$class->{constraints}}, 'and';
		ConditionalOrExpression $class;
	};

	delete($class->{constraints_context});
};

sub ConditionalOrExpression($) {
	my($class) = @_;

	ConditionalAndExpression $class;
	while( MatchAndEat $class,'||' ) {
		push @{$class->{constraints}}, '||';
		ConditionalAndExpression $class;
	};
};

sub ConditionalAndExpression($) {
	my($class) = @_;

	StringEqualityExpression $class;
	while( MatchAndEat $class,'&&' ) {
		push @{$class->{constraints}}, '&&';
		StringEqualityExpression $class;
	};
};

sub StringEqualityExpression($) {
	my($class) = @_;

	InclusiveOrExpression $class;
	my $true=1;
	while( $true ) {
		if( MatchAndEat $class,'eq' ) {
			push @{$class->{constraints}}, 'eq';
			InclusiveOrExpression $class;
		} elsif( MatchAndEat $class,'ne' ) {
			push @{$class->{constraints}}, 'ne';
			InclusiveOrExpression $class;
		} elsif( MatchAndEat $class,'LIKE' ) {
			push @{$class->{constraints}}, '=~';
			InclusiveOrExpression $class;
		} else {
			$true=0;
		};
	};
};

sub InclusiveOrExpression($) {
	my($class) = @_;

	ExclusiveOrExpression $class;
	while( MatchAndEat $class,'|' ) {
		push @{$class->{constraints}}, '|';
		ExclusiveOrExpression $class;
	};
};

sub ExclusiveOrExpression($) {
	my($class) = @_;

	AndExpression $class;
	while( MatchAndEat $class,'^' ) {
		push @{$class->{constraints}}, '^';
		AndExpression $class;
	};
};

sub AndExpression($) {
	my($class) = @_;

	EqualityExpression $class;
	while( MatchAndEat $class,'&' ) {
		push @{$class->{constraints}}, '&';
		EqualityExpression $class;
	};
};

sub EqualityExpression($) {
	my($class) = @_;

	RelationalExpression $class;
	my $true=1;
	while( $true ) {
		if( MatchAndEat $class,'==' ) {
			push @{$class->{constraints}}, '==';
			RelationalExpression $class;
		} elsif( MatchAndEat $class,'!=' ) {
			push @{$class->{constraints}}, '!=';
			RelationalExpression $class;
		} else {
			$true=0;
		};
	};
};

sub RelationalExpression($) {
	my($class) = @_;

	ShiftExpression $class;
	if( MatchAndEat $class,'>=' or MatchAndEat $class,'=>' ) {
		push @{$class->{constraints}}, '>=';
		ShiftExpression $class;
	} elsif( MatchAndEat $class,'<=' or MatchAndEat $class,'=<' ) {
		push @{$class->{constraints}}, '<=';
		ShiftExpression $class;
	} elsif( MatchAndEat $class,'<' ) {
		push @{$class->{constraints}}, '<';
		ShiftExpression $class;
	} elsif( MatchAndEat $class,'>' ) {
		push @{$class->{constraints}}, '>';
		ShiftExpression $class;
	};
};

sub ShiftExpression($) {
	my($class) = @_;

	AdditiveExpression $class;
	my $true=1;
	while( $true ) {
		if( MatchAndEat $class,'>>>' ) {
			error $class,">>> operator not implemented"
			#AdditiveExpression $class;
		} elsif( MatchAndEat $class,'<<' ) {
			push @{$class->{constraints}}, '<<';
			AdditiveExpression $class;
		} elsif( MatchAndEat $class,'>>' ) {
			push @{$class->{constraints}}, '>>';
			AdditiveExpression $class;
		} else {
			$true=0;
		};
	};
};

sub AdditiveExpression($) {
	my($class) = @_;

	MultiplicativeExpression $class;
	my $true=1;
	while( $true ) {
		if( MatchAndEat $class,'+' ) {
			push @{$class->{constraints}}, '+';
			MultiplicativeExpression $class;
		} elsif( MatchAndEat $class,'-' ) {
			push @{$class->{constraints}}, '-';
			MultiplicativeExpression $class;
		} else {
			$true=0;
		};
	};
};

sub MultiplicativeExpression($) {
	my($class) = @_;

	UnaryExpression $class;
	my $true=1;
	while( $true ) {
		if( MatchAndEat $class,'*' ) {
			push @{$class->{constraints}}, '*';
			UnaryExpression $class;
		} elsif( MatchAndEat $class,'/' ) {
			push @{$class->{constraints}}, '/';
			UnaryExpression $class;
		} elsif( MatchAndEat $class,'%' ) {
			push @{$class->{constraints}}, '%';
			UnaryExpression $class;
		} else {
			$true=0;
		};
	};
};

sub UnaryExpression($) {
	my($class) = @_;

	if( MatchAndEat $class, '+' ) {
		push @{$class->{constraints}}, '+';
		UnaryExpression $class;
	} elsif( MatchAndEat $class, '-' ) {
		push @{$class->{constraints}}, '-';
		UnaryExpression $class;
	} else {
		UnaryExpressionNotPlusMinus $class;
	};
};

sub UnaryExpressionNotPlusMinus($) {
	my($class) = @_;

	if( MatchAndEat $class,'~' ) {
		push @{$class->{constraints}}, '~';
		UnaryExpression $class;
	} elsif ( MatchAndEat $class,'!' ) {
		push @{$class->{constraints}}, '!';
		UnaryExpression $class;
	} else {
		PrimaryExpression $class;
	};
};

sub PrimaryExpression($) {
	my($class) = @_;

	if( MatchAndEat $class,'(' ) {
		push @{$class->{constraints}}, '(';

		ConditionalOrExpression $class;
		error $class,"missing right round bracket"
			unless( MatchAndEat $class,')' );

		push @{$class->{constraints}}, ')';
	} else {
		unless(	Var $class or URL $class or Literal $class ) {
			FunctionCall $class;
		};
	};
};

sub FunctionCall($) {
	my($class) = @_;

	s/^\s*(\w[\w\d]*)\s*//;
	if( MatchAndEat $class,'(' ) {
		push @{$class->{constraints}}, '(';

		ArgList $class;
		error $class,"missing right round bracket"
			unless( MatchAndEat $class,')' );

		push @{$class->{constraints}}, ')';
	};
};

sub ArgList($) {
	my($class) = @_;

	if( Var $class or URL $class or Literal $class ) {
		my $true=1;
		while( $true ) {
			if( MatchAndEat $class,',' ) {
				push @{$class->{constraints}}, ',';
				unless( Var $class or URL $class or Literal $class ) {
					$true=0;
				};
			} else {
				$true=0;
			};
		};
	};
};

sub serialize {
	my($class, $fh, $syntax) = @_;

	if(	(! $syntax ) ||
                ( $syntax =~ m/N-Triples/i) ) {
		# not yet supported ?
                return
			if($#{$class->{constraints}}>=0);
		foreach my $tp ( @{$class->{triplePatterns}} ) {
			return
				if( ($#{$tp}==3) || #Quads not there yet
			            (     ($tp->[2] =~ m/^%/) && #my free-text extensions
                                          ($tp->[2] =~ m/%$/) ) );
			};

		# convert
		my @nt;
		foreach my $tp ( @{$class->{triplePatterns}} ) {
			my @tp;
			map {
				my $ff = $_;
				$ff =~ s/^\?(.+)$/_:$1/;
				if(	($ff =~ m/^<(([^\:]+)\:{1,2}([^>]+))>$/) &&
					(defined $2) &&
					(exists $class->{prefixes}->{$2}) ) {
					push @tp, '<'.$class->{prefixes}->{$2}.$3.'>';
				} else {
					push @tp, $ff;
					};
			} @{$tp};
			push @tp, '.';
			push @nt, join(' ',@tp);
			};
		if($fh) {
			print $fh join("\n",@nt);
			return 1;
		} else {
			return join("\n",@nt);
			};
        } else {
                croak "Unknown serialization syntax '$syntax'";
                };
	};

sub DESTROY {
	my($class) = @_;

};

1;
};

__END__

=head1 NAME

RDQL::Parser - A simple top-down LL(1) RDQL parser - see http://www.hpl.hp.com/semweb/rdql-grammar.html

=head1 SYNOPSIS

	use RDQL::Parser;
	my $parser = RDQL::Parser->new();
	my $query = <<QUERY;

        SELECT
           ?title, ?link
        FROM
           <http://xmlhack.com/rss10.php>
        WHERE
	   (?item, <rdf:type>, <rss:item>),
	   (?item, <rss::title>, ?title),
	   (?item, <rss::link>, ?link)
        USING
	   rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
	   rss for <http://purl.org/rss/1.0/>

        QUERY;

        $parser->parse($query); #parse the query

	# I.e.
	$parser = bless( {
                 'constraints' => [],
                 'resultVars' => [ '?title', '?link' ],
                 'triplePatterns' => [
                                       [ '?item', '<rdf:type>', '<rss:item>' ],
                                       [ '?item', '<rss::title>', '?title' ],
                                       [ '?item', '<rss::link>', '?link' ]
                                     ],
                 'sources' => [ '<file:t/rdql-tests/rdf/rss10.php>' ],
                 'prefixes' => {
                                 'rss' => 'http://purl.org/rss/1.0/',
                                 'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
                               }
               }, 'RDQL::Parser' );

	$parser->serialize(*STDOUT, 'N-Triples'); #print on STDOUT the RDQL query as N-Triples if possible (or an error)

=head1 DESCRIPTION

 RDQL::Parser - A simple top-down LL(1) RDQL parser - see http://www.hpl.hp.com/semweb/rdql-grammar.html

=head1 CONSTRUCTORS

=item $parser = new RDQL::Parser;

=head1 METHODS

=item parse( PARSER, RDQL_QUERY )

 If use Data::Dumper(3) to actually dumpo out the content of the PARSER variable after invoching the parse() method it lokks like:

 $VAR1 = bless( {
                 'constraints' => [],
                 'resultVars' => [
                                   '?title',
                                   '?link'
                                 ],
                 'triplePatterns' => [
                                       [
                                         '?item',
                                         '<rdf:type>',
                                         '<rss:item>'
                                       ],
                                       [
                                         '?item',
                                         '<rss::title>',
                                         '?title'
                                       ],
                                       [
                                         '?item',
                                         '<rss::link>',
                                         '?link'
                                       ]
                                     ],
                 'sources' => [
                                '<file:t/rdql-tests/rdf/rss10.php>'
                              ],
                 'prefixes' => {
                                 'rss' => 'http://purl.org/rss/1.0/',
                                 'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
                               }
               }, 'RDQL::Parser' );


=head1 NOTES

	The following RDQL implementation is actually an extension of the original RDQL spec (http://www.w3.org/Submission/2004/SUBM-RDQL-20040109/)
	to allow more SQL-like Data Manipulation Language (DML) features like DELETE and INSERT - which is much more close to the original rdfdb
	query language which SquishQL/RDQL are inspired to (see http://www.guha.com/rdfdb).

=head1 SEE ALSO

DBD::RDFStore(3)

http://www.w3.org/Submission/2004/SUBM-RDQL-20040109/
http://ilrt.org/discovery/2002/04/query/
http://www.hpl.hp.com/semweb/doc/tutorial/RDQL/
http://rdfstore.sourceforge.net/documentation/papers/HPL-2002-110.pdf

=head1 FAQ

=item I<What's the difference between RDQL and SquishQL?>

=item None :-) The former is a bit of an extension of the original SquishQL proposal defining a proper BNF to the query language; the only practical difference is that triple patterns in the WHERE clause are expressed in a different order s,p,o for RDQL while SquishQL uses '(p s o)' without commas. In addition the URLs are expressed with angle brackets on RDQL while SquishQL do not. For more about differences between the two languages see http://rdfstore.sourceforge.net/documentation/papers/HPL-2002-110.pdf

=item I<Is RDQL::Parser compliant to RDQL BNF?>

=item Yes

=item I<Is RDQL::Parser compliant to SquishQL syntax ?>

=item Not yet :)

=item I<What are RDQL::Parser extensions to RDQL BNF?>

=item RDQL::Parser leverage on RDFStore(3) to run proper free-text UTF-8 queries over literals; the two main extensions are

=item * LIKE operator in AND clause

=item * free-text triple matching like (?x, ?y, %"whatever"%)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>
	Andy Seaborne <andy_seaborne@hp.com> is the original author of RDQL
	Libby Miller <libby.miller@bristol.ac.uk> is the original author of SquishQL

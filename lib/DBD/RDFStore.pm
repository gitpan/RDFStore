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
# *		- first hacked version of DBI driver for RDFStore
# *

package DBD::RDFStore;

use DBI qw(:sql_types);
use strict;
use vars qw($err $errstr $sqlstate $drh $VERSION);

use Carp;
 
$VERSION = '0.1';

$err = 0;             # holds error code   for DBI::err
$errstr = "";         # holds error string for DBI::errstr
$sqlstate = "";       # holds SQL state for    DBI::state

$drh = undef;         # holds driver handle once initialized

sub driver {
        return $drh if $drh;        # already created - return same one
        my($class, $attr) = @_;
        
        $class .= "::dr";
        
        # not a 'my' since we use it above to prevent multiple drivers
        $drh = DBI::_new_drh($class, {
            'Name'    => 'DBD::RDFStore',
            'Version' => "0.1",
            'Err'     => \$DBD::RDFStore::err,
            'Errstr'  => \$DBD::RDFStore::errstr,
            'State'   => \$DBD::RDFStore::state,
            'Attribution' => 'DBD::RDFStore by Alberto Reggiori',
        });
        
        return $drh;
};

package DBD::RDFStore::dr; # ====== DRIVER ======

use vars qw ($VERSION);
use strict;
 
$VERSION = '0.1';

use RDFStore::NodeFactory;
use RDFStore::Model;

$DBD::RDFStore::dr::imp_data_size = 0;
    
sub connect {
        my($drh, $dbname, $user, $auth, $attr)= @_;
        
        # Some database specific verifications, default settings
        # and the like following here. This should only include
        # syntax checks or similar stuff where it's legal to
        # 'die' in case of errors.

	# e.g. DBI:rdfstore:database=cooltest;host=localhost;port=1234
	my %params;
	$params{ Name } = $1
		if ($dbname =~ /database=([^;]+)/);
	$params{ Host } = $1
		if ($dbname =~ /host=([^;]+)/);
	$params{ Port } = $1
		if ($dbname =~ /port=([^;]+)/);
	$params{ Mode } = 'r'; #read-only

	my $factory;
	if(	(exists $attr->{nodeFactory}) &&
		(defined $attr->{nodeFactory}) &&
		(ref($attr->{nodeFactory})) &&
		($attr->{nodeFactory}->isa("RDFStore::NodeFactory")) ) {
		$factory = $attr->{nodeFactory};
	} else {
		$factory = new RDFStore::NodeFactory;
		};

        my $model;
	if(	(exists $attr->{sourceModel}) &&
		(defined $attr->{sourceModel}) &&
		(ref($attr->{sourceModel})) &&
		($attr->{sourceModel}->isa("RDFStore::Model")) ) {
		$model = $attr->{sourceModel};
	} else {
		eval {
        		$model = new RDFStore::Model( nodeFactory => $factory, %params );
		};
		if ($@) {
        		DBI::_new_dbh($drh, {})->DBI::set_err( 1, $@ );
                	return undef;
        		};
		};

        # create a 'blank' dbh (call superclass constructor)
        my %options = (
            'Name' => $dbname,
            'USER' => $user,
            'CURRENT_USER' => $user,
	    'FACTORY' => $factory );

	if(	(exists $attr->{asRDF}) &&
               	(defined $attr->{asRDF}) &&
		(ref($attr->{asRDF}) =~ /HASH/) &&
		(exists $attr->{asRDF}->{syntax}) &&
		(defined $attr->{asRDF}->{syntax}) ) {
		#output syntax
		if($attr->{asRDF}->{syntax} !~ m#(RDF/XML|N-Triples|rdfqr-results|rdf-for-xml)#i) {
        		DBI::_new_dbh($drh, {})->DBI::set_err( 1, "Unrecognized serialization syntax '".$attr->{asRDF}->{syntax}."'" );
                	return undef;
			};
		$attr->{asRDF}->{syntax} = 'RDF/XML'
			unless(exists $attr->{asRDF}->{syntax});

		#output handle
		if(exists $attr->{asRDF}->{output}) {
			$attr->{asRDF}->{output} = \$attr->{asRDF}->{output};
			select($attr->{asRDF}->{output}); $|=1; select(STDOUT);
		} elsif(! exists $attr->{asRDF}->{'output_string'}) {
			$|=1;
			};

		$options{'AS_RDF'} = $attr->{asRDF};
		};

	$options{'MODEL'} = $model
		if($model);

        my $dbh = DBI::_new_dbh($drh, \%options, {});
        
        $dbh;
};

sub disconnect_all {
        # we don't need to tidy up anything
};

sub DESTROY {
};

package DBD::RDFStore::db; # ====== DATABASE ======

use vars qw ($VERSION);
use strict;
 
$VERSION = '0.1';

use RDQL::Parser;
    
$DBD::RDFStore::db::imp_data_size = 0;
    
sub prepare {
        my($dbh, $statement, @attribs)= @_;

print STDERR "STATEMENT='$statement'\n" if($DBD::RDFStore::st::debug>1);

	#parse the RDQL statement (2nd tier thingie :)
        my $parser = RDQL::Parser->new();
	$parser->parse( $statement ); #bear in mind that if we would use cache_prepare() we need to keep a copy (clone) of this!!!!

        # create a 'blank' sth
        my %options = (
            'Statement' => $parser, #bit ugly I know....
	    'FACTORY' => $dbh->{'FACTORY'},
	    'Default_prefixes' => {
			'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
			'rdfs' => 'http://www.w3.org/2000/01/rdf-schema#',
			'rss' => 'http://purl.org/rss/1.0/',
			'daml' => 'http://www.daml.org/2001/03/daml+oil#',
			'dc' => 'http://purl.org/dc/elements/1.1/',
			'dcq' => 'http://purl.org/dc/terms/',
			'foaf' => 'http://xmlns.com/foaf/0.1/',
			'xsd' => 'http://www.w3.org/2001/XMLSchema#',
			'owl' => 'http://www.w3.org/2002/07/owl#'
			}
        	);

	$options{'AS_RDF'} = $dbh->{'AS_RDF'}
		if(exists $dbh->{'AS_RDF'});

        $options{'MODEL'} = $dbh->{'MODEL'}
		if(exists $dbh->{'MODEL'});

        my $sth = DBI::_new_sth($dbh, \%options );

        # Setup module specific data
        $sth->STORE('driver_params', []);

	# if we do not set NUM_OF_PARAMS we could not call bind_param - see DBI::DBD(3)
	#$sth->STORE('NUM_OF_PARAMS', $#{$parser->{resultVars}}+1 ); # what about SELECT '*' ??!!!??
	#$sth->STORE('NUM_OF_PARAMS', ($statement =~ tr/?//)); # RDQL/SquishQL uses '?' for something else?? need to read the DBI docs better....

	if(     ($#{$sth->{'Statement'}->{resultVars}}==0) &&
                ($sth->{'Statement'}->{resultVars}->[0] eq '*') ) {
                my %vars;
                map {
                        @vars{ grep /^(\?.+)$/, @{ $_ } } = ();
                        } @{ $sth->{'Statement'}->{triplePatterns} };
                my @vv = sort keys %vars; # but the order here sucks!!
                $sth->STORE( NAME =>  \@vv );
                $sth->STORE('NUM_OF_FIELDS', $#vv+1 );
        } else {
                $sth->STORE( NAME => $sth->{'Statement'}->{resultVars} );
                $sth->STORE('NUM_OF_FIELDS', $#{$sth->{'Statement'}->{resultVars}}+1 ); # it might be that the resultsing table could have different colums lenghts....
                };

        $sth;
};

sub FETCH {
        my ($dbh, $attrib) = @_;
        # In reality this would interrogate the database engine to
        # either return dynamic values that cannot be precomputed
        # or fetch and cache attribute values too expensive to prefetch.
        return 1 if $attrib eq 'AutoCommit';
        # else pass up to DBI to handle
        return $dbh->SUPER::FETCH($attrib);
};

sub STORE {
        my ($dbh, $attrib, $value) = @_;
        # would normally validate and only store known attributes
        # else pass up to DBI to handle
        if ($attrib eq 'AutoCommit') {
            return 1 if $value; # is already set
            Carp::croak("Can't disable AutoCommit");
        }
        return $dbh->SUPER::STORE($attrib, $value);
};

sub DESTROY {
};

package DBD::RDFStore::st;
    
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.1';

use Carp;
use RDFStore::Parser::SiRPAC; #for RDQL query sources parsing on-the-fly
use RDFStore::Model;
use RDFStore::Serializer;

$DBD::RDFStore::st::serializer = new RDFStore::Serializer(); #fake one for the moment just for xml-escape functionality

$DBD::RDFStore::st::imp_data_size = 0;
$DBD::RDFStore::st::debug = 0;

sub bind_param {
        my($sth, $pNum, $val, $attr) = @_;
        my $type = (ref $attr) ? $attr->{TYPE} : $attr;
        if ($type) {
            my $dbh = $sth->{Database};
            $val = $dbh->quote($sth, $type);
        }
        my $params = $sth->FETCH('driver_params');
        $params->[$pNum-1] = $val;
	1;
};

# XXXXXXXXX here is all the JOIN bottleneck of the RDQL stuff :-((((
sub execute {
        my($sth, @bind_values) = @_;

        $sth->{'driver_data'} = [];

	$sth->{'stop'}=0;
        $sth->{'iterators'} = {};
        $sth->{'binds'} = [];
        $sth->{'result'} = {};
	$sth->{'result_statements'} = {}
		if(exists $sth->{'AS_RDF'} and $sth->{'AS_RDF'}->{syntax} =~ m#(RDF/XML|N-Triples)#i);

	# parse the RDF or pick up the right database
	my $source_model;
	if($#{$sth->{'Statement'}->{sources}}>=0) {
		my $genid=0;
		foreach my $source (@{$sth->{'Statement'}->{sources}}) {
			$source =~ s/^\<([^\>]+)\>$/$1/; #actually Andy wants this a QName :-(
			my $model;

			eval {
				if ( $source =~ m#^rdfstore://([^@]+)@([^:]+):?(\d+)?# ) {
					# connect to remote DB
					$model = new RDFStore::Model (
							Name => $1,
                                                	Host => $2,
                                                	Port => $3,
                                                	nodeFactory => $sth->{'FACTORY'},
                                                	FreeText => 1,
							Mode => 'r'
							);
				} elsif ( $source =~ m#^rdfstore://# ) {
					# connect to local DB
					$model = new RDFStore::Model (
							Name => $source,
                                                	nodeFactory => $sth->{'FACTORY'},
                                                	FreeText => 1,
							Mode => 'r'
							);
				} else {
					#in-memory model
					my $p = new RDFStore::Parser::SiRPAC(
						Style =>        'RDFStore::Parser::Styles::RDFStore::Model',
                                        	NodeFactory =>  $sth->{'FACTORY'},
                                        	GenidNumber =>  $genid,
                                        	store   =>      { options => { FreeText => 1 } } #we should check if we are using LIKE operator here...
						);
					$model= $p->parsefile($source);
					$genid = $p->getReificationCounter();
					};
				};

			if($@) {
print STDERR "parsing error: $@\n" if($DBD::RDFStore::st::debug>1);
                               	$sth->DBI::set_err( 1, $@ ); # correct??!
                               	next;
                               	};

			next 
				unless(defined $model);

			if(defined $source_model) {
				if ( $source_model->isRemote ) {
					$sth->DBI::set_err( 1, "For remote queries can not have more than just one RDF source: $@" );
					return undef;
					};
				# the following will break if you have multiple rdfstore:// URLs as sources because is tied read-only
				# a solution would be to have an in-memory model anyway
				#smush() will be better at some point :)
				my $ee = $model->elements;
				while ( my $ss = $ee->each ) {
					$source_model->add( $ss );
					};
			} else {
				#$model = $model->duplicate #which is bad for the moment but allows "to join distributed searches" :-)
				#	if(	( scalar(@{$sth->{'Statement'}->{sources}}) > 0 ) &&
				#		( $model->isRemote ) );
				$source_model=$model;
				};
			};
		unless(defined $source_model) {
			$sth->DBI::set_err( 1, "Cannot process RDF input: $@" );
			return undef;
			};
	} else {
		$source_model=$sth->{'MODEL'};
                };    

        unless(defined $source_model) {
                $sth->DBI::set_err( 1, "Cannot detect RDF input" );
                return undef;
                };

	#print STDERR $source_model->serialize(undef,'RDF/XML')."\n";

	$sth->{'source_model'} = $source_model;

	# we could eventually further sort the triple-pattern to make the query more efficient (kinds topological order here with the shortest first)

        return '0E0'; #we do *not* want to know the number of rows affected at the moment due to efficency problems :)
	};

# fetch the next result set (row)
# This subroutine runs a depth-first like visit of the graph matching the triple patterns (even if we do not really 
# have an in-memory rep of the query process!)
# i.e. the way we visit the graph (backtrack) is "told" by the triple-patterns in the query
# i.e. $sth->{'result'} = ( '?x' => 1, '?y' => Test1 )
#
sub _nextMatch {
        my( $sth, $tpi, %bind ) = @_;

	return if($sth->{'stop'});

	if($DBD::RDFStore::st::debug>1) {
		print STDERR (" " x $tpi);
		print STDERR "$tpi BEGIN\n";	
		};

	# if we have a previous state try to recover it
	my $bind_state = pop @{ $sth->{'binds'} };

	if(	( $bind_state ) && ($DBD::RDFStore::st::debug>1) ) {
		print STDERR (" " x $tpi);
		print STDERR "RECOVER previous state for $tpi\n";
		};

	_nextMatch( $sth, $tpi+1, %{$bind_state} )
		if( $bind_state );

	#we stop on the way if some result was matched already
	if ( scalar(keys %{$sth->{'result'}}) > 0 ) {
		#save actual state on the stack
		push @{ $sth->{'binds'} }, \%bind
			if(scalar(keys %bind)>0);

		if($DBD::RDFStore::st::debug>1) {
			print STDERR (" " x $tpi);
			print STDERR "$tpi GOT NEW RESULT ready (top)\n";
			};

		return;
		};

	if ( $tpi > $#{$sth->{'Statement'}->{triplePatterns}} ) {
		# actually copy the new result
		map { $sth->{'result'}->{$_} = $bind{$_}; } keys %bind;

		return;
		};

	# we want to keep the current iterator state and avoid to run the same query over and over again
	unless( exists $sth->{'iterators'}->{$tpi} ) {
		$sth->{'iterators'}->{$tpi} = {};

		#substitute %bind into i-esim triple-pattern if possible and needed

		if($DBD::RDFStore::st::debug>1) {
			print STDERR (" " x $tpi);
			print STDERR "$tpi BEFORE substitute: TP( ",join(',',@{ $sth->{'Statement'}->{triplePatterns}->[$tpi] })," )\n";
			};

		my %vars;
		$sth->{'iterators'}->{$tpi}->{vars} = {};
		my $j=0;
		my @tp;
        	foreach ( map { $_ } @{ $sth->{'Statement'}->{triplePatterns}->[$tpi] } ) { # local copy - needed??!?
                      	if(/^(\?.+)$/) {
				my $var = $1;

				if(exists $bind{$var} ) {
                        		if(	($bind{$var}->isa("RDFStore::Literal")) &&
						($j==2) && #do not join in literals on the wrong position
						(s/^\Q$var\E$/$bind{$var}->toString/eg) ) {
                                		$_ = '"'.$_.'"';
						$_ .= '@'.$bind{$var}->getLang
							if($bind{$var}->getLang);
                        		} elsif(	($bind{$var}->isa("RDFStore::Resource")) &&
							(s/^\Q$var\E$/$bind{$var}->toString/eg) ) {
                                		$_ = '<'.( ($bind{$var}->isbNode) ? '_:'.$_ : $_ ).'>';
                                	} else {
						if(	(exists $sth->{'iterators'}->{$tpi}->{vars}->{$var}) &&
							($j==1) ) {
                					$sth->DBI::set_err( 1, "Cannot join query; query variable repeated in the predicate part of the triple-pattern" );
							$sth->{'stop'}=1;
							return;
							};

						$sth->{'iterators'}->{$tpi}->{vars}->{$var} = $j;
                                        	};
				} else {
					if(	(exists $sth->{'iterators'}->{$tpi}->{vars}->{$var}) &&
						($j==1) ) {
                				$sth->DBI::set_err( 1, "Cannot join query; query variable repeated in the predicate part of the triple-pattern" );
						$sth->{'stop'}=1;
						return;
						};

					$sth->{'iterators'}->{$tpi}->{vars}->{$var} = $j;
					};

				};
			$j++;

                	push @tp, $_;
        		};

		if($DBD::RDFStore::st::debug>1) {
			print STDERR (" " x $tpi);
			print STDERR "$tpi AFTER substitute: TP( ",join(',',@tp)," )\n";
			};

		#run i-esim search
		$sth->{'iterators'}->{$tpi}->{itr} = $sth->{'source_model'}->{rdfstore}->search( _prepareTriplepattern( $sth, @tp ) );

		if($DBD::RDFStore::st::debug>1) {
			print STDERR (" " x $tpi);
			print STDERR "$tpi JUST GOT '".($sth->{'iterators'}->{$tpi}->{itr}->size)."' RESULTS\n";
			};
		};

	#for each resulting new vars recursively call itself to solve the others; the i-esim process is over when all vars are bounded
	while ( my $c = $sth->{'iterators'}->{$tpi}->{itr}->each ) {
		if($DBD::RDFStore::st::debug>1) {
			print STDERR (" " x $tpi);
			print STDERR "$tpi GOT TRIPLE MATCH '".$c->toString."'\n";
			};

		#fill-in the bindings for the current match and fetch the properties values
		foreach my $var ( keys %{$sth->{'iterators'}->{$tpi}->{vars}} ) {

                	# get the variable value out
                        my $pp = ($sth->{'iterators'}->{$tpi}->{vars}->{$var} == 0) ? ($c->subject) :
                        	 ($sth->{'iterators'}->{$tpi}->{vars}->{$var} == 1) ? ($c->predicate) :
                        	 ($sth->{'iterators'}->{$tpi}->{vars}->{$var} == 2) ? ($c->object) :
                        	                                                      ($c->context) ;

                        next
                         	unless($pp);

                        $bind{ $var } = $pp; #got result

			if($DBD::RDFStore::st::debug>1) {
				print STDERR (" " x $tpi);
                                print STDERR "$tpi GOT RESULT '$var'='".$bind{ $var }->toString."' and '".$c->toString."'\n";
				};

			if(exists $sth->{'AS_RDF'} and $sth->{'AS_RDF'}->{syntax} =~ m#(RDF/XML|N-Triples)#i) {
				my $label = $c->getLabel;
				$sth->{'result_statements'}->{ $label } = $c
					unless(exists $sth->{'result_statements'}->{ $label });
				};
			};

		if( scalar(keys %{$sth->{'iterators'}->{$tpi}->{vars}}) <= 0 ) { #pure/easy match?
			if(exists $sth->{'AS_RDF'} and $sth->{'AS_RDF'}->{syntax} =~ m#(RDF/XML|N-Triples)#i) {
				my $label = $c->getLabel;
				$sth->{'result_statements'}->{ $label } = $c
					unless(exists $sth->{'result_statements'}->{ $label });
				};
			};

		# we save into local stack the current state for future each() calls
		# i.e. save %bind per call to _nextMatch()
		
		#look for the next bind
		_nextMatch( $sth, $tpi+1, %bind );

		# we could even return the result to the caller using a callback perhaps??!?!? i.e. pull model

		#we stop on the way if some result was matched already
		if ( scalar(keys %{$sth->{'result'}}) > 0 ) {
			#forget the last ones (it is for the @tp substitution above i.e. same as it was called)
			map { delete( $bind{$_} ); } keys %{$sth->{'iterators'}->{$tpi}->{vars}};

			#save actual state on the stack
			push @{ $sth->{'binds'} }, \%bind
				if(scalar(keys %bind)>0);

			if($DBD::RDFStore::st::debug>1) {
				print STDERR (" " x $tpi);
				print STDERR "$tpi GOT NEW RESULT ready (bottom)\n";
				};

			return;
			};
		};

	delete( $sth->{'iterators'}->{$tpi} );

	if($DBD::RDFStore::st::debug>1) {
		print STDERR (" " x $tpi);
		print STDERR "$tpi END\n";
		};
	};

# Each call to _each() goes through the triple patterns and try to bind/solve the next variable; all the iterators (search) are cached and not run twice 
# if not necessary. The whole process could probably be compiled (pre-processed) in the DBI execute() in the future and the _each() will do real iterator 
# style fetch next
#
sub _each {
        my( $sth ) = @_;

	$sth->{'result'} = {};
	$sth->{'result_statements'} = {}
		if(exists $sth->{'AS_RDF'} and $sth->{'AS_RDF'}->{syntax} =~ m#(RDF/XML|N-Triples)#i);

	#start matching
	_nextMatch( $sth, 0, () );

	return
		if($sth->{'stop'});

	if( $DBD::RDFStore::st::debug > 1 ) {       
        	map {
                	print STDERR "NEW RESULT \t$_ = ".($sth->{'result'}->{$_}->toString)."\n";
                        } sort keys %{$sth->{'result'}};
        	};

	if($#{$sth->{'Statement'}->{constraints}}>=0) {
               	my $cexp=join(' ', map {
                       	if(/^<(([^\:]+)\:{1,2}([^>]+))>$/) {
                               	if(exists $sth->{'Statement'}->{prefixes}->{$2}) {
                                       	s/^<(([^\:]+)\:{1,2}([^>]+))>$/<$sth->{'Statement'}->{prefixes}->{$2}$3>/;
				} elsif(exists $sth->{'Default_prefixes'}->{$2}) {
                                       	s/^<(([^\:]+)\:{1,2}([^>]+))>$/<$sth->{'Default_prefixes'}->{$2}$3>/;
                               	};
                       	};
                       	$_;
                       	} @{$sth->{'Statement'}->{constraints}});
               	if(     (defined $cexp) &&
                       	($cexp ne '') ) {
                       	#fix ANDs and ORs
                       	$cexp=~s/\&\s+\&/\&\&/g;
                       	$cexp=~s/\|\s+\|/\|\|/g;
                       	$cexp=~s/\s\=\~\s["']\/?([^\/]+)\/?(\w*)["']/ \=\~ \/$1\/$2/g; #fix LIKE operators

                       	# purge matched positions with constraints
			while (	(!( _eval($sth, $cexp) )) && #got a valid constrained match
				( scalar( keys %{$sth->{'iterators'}}) > 0 ) ) { #there are still nodes to be visitied

				#reset current result set which is not matching the constraints
				$sth->{'result'} = {};
				$sth->{'result_statements'} = {}
					if(exists $sth->{'AS_RDF'} and $sth->{'AS_RDF'}->{syntax} =~ m#(RDF/XML|N-Triples)#i);

				_nextMatch( $sth, 0, () ); #try the next one

				return
					if($sth->{'stop'});
				};
                	};
		};

	# i.e. fetch a row - e.g. [var1.a, var2.a,...varn.a], [var1.b, var2.b,.....varn.b], [var1.c, var2.c,...varn.c], .......
        my @result = map {
                return
                        unless(exists $sth->{'result'}->{$_}); #a requested var is missing from the result set
                $sth->{'result'}->{$_};
                } @{ $sth->FETCH ('NAME') }; # the variables are not of course in order of "execution"

        # i.e [var1.a, var2.a,...varn.a], [var1.b, var2.b,.....varn.b], [var1.c, var2.c,...varn.c], .......
        return \@result;
};

sub _eval {
        my ($sth, $cexp ) = @_;

        map {
                my $val=$sth->{'result'}->{$_};
                $val=$val->toString
                        if(     (defined $val) &&
                                ($val->isa("RDFStore::RDFNode")) ); #perl is un-typed - we use strings
                $val=~s/'/\\\'/g;
                if(defined $val) {
                        if(     (/^\s*([1-9][0-9]*)\s*$/) or
                                (/^\s*(0[xX]([0-9",a-f,A-F])+)\s*$/) or
                                #(/^\s*(0[0-7]*)\s*$/) or
                                (/^\s*(([0-9]+\.[0-9]*([eE][+-]?[0-9]+)?[fFdD]?)|(\.[0-9]+([eE][+-]?[0-9]+)?[fFdD]?)|([0-9]+[eE][+-]?[0-9]+[fFdD]?)|([0-9]+([eE][+-]?[0-9]+)?[fFdD]))\s*$/) ) {
                                $cexp=~s/\Q$_\E/ $val /g;
                        } else {
                                $cexp=~s/\Q$_\E/ \'$val\' /g;
                                };
                        };
                } keys %{$sth->{'result'}};

        #got constraints expression right
        return (        ($cexp=~/\s*(\?\w[\w\d]*)\s*/) || # some unbounded vars left
                        (!(eval $cexp )) ) ? 0 : 1;
        };

sub _prepareTriplepattern {
	my ($sth, @tp) = @_;

print STDERR "TP=".join(',', @tp)."\n" if($DBD::RDFStore::st::debug>1);

	my @query;
	my @ft_query;

	my $search_type=0; #default triple-pattern search
        #                       0 1 2 3 4 5 6 7 8 9 0 1 2 3
        #                       s s p p o o c c l l d d w w
        my @operators_and_nums=(0,0,0,0,0,0,0,0,0,0,0,0,0,0); #all non-words operators are set to 0=OR - will need 1=AND for real RDQL query

        my $node;
        for my $j ( 0..$#tp ) {
		next
			if($tp[$j]=~/^(\?.+)$/);

                if($tp[$j]=~/^<(([^\:]+)\:{1,2}([^>]+))>$/) {
			map {
				my $ored=$_;
                		if($ored=~/^(([^\:]+)\:{1,2}(.*))$/) {
					$operators_and_nums[(2*$j)+1]++;
					if($ored=~/^_:([A-Za-z][A-Za-z0-9]*)$/) {
                        			#bNode joining in
                               			$node = $sth->{'FACTORY'}->createAnonymousResource($1);

						print STDERR "bNode=",$node->toString,"\n"
							if($DBD::RDFStore::st::debug>1);
                        		} elsif(	(defined $2) &&
                        				(	(exists $sth->{'Statement'}->{prefixes}->{$2}) ||
								(exists $sth->{'Default_prefixes'}->{$2}) ) ) {
                                		$node = $sth->{'FACTORY'}->createResource(
						(exists $sth->{'Statement'}->{prefixes}->{$2}) ? 
							$sth->{'Statement'}->{prefixes}->{$2} : 
							$sth->{'Default_prefixes'}->{$2} ,$3);

						print STDERR "NODE=",$node->toString,"\n"
							if($DBD::RDFStore::st::debug>1);
                        		} else {
                        			#no namespace set - see RDFStore::Resource
                               			$node = $sth->{'FACTORY'}->createResource($1);

						print STDERR "NODE1=",$node->toString,"\n"
							if($DBD::RDFStore::st::debug>1);
                                		};
                        		push @query, $node;
					};
			} split(/\s+,\s+/, $1); #hack for OR-ed nodes
                } elsif($tp[$j]=~/^<([^>]+)>$/) {
			map {
				my $ored=$_;
				my $lang=$1
					if($ored =~ s/\@([a-z0-9]+(-[a-z0-9]+)?)\s*$//m); #xml:lang
				if(	($ored=~ s/^\s*["']//) &&
					($ored=~ s/["']\s*$//) ) {
					$operators_and_nums[(2*$j)+1]++;
					# to add rdf:datatype and rdf:parseType too - see RDQL spec
                        		$node = $sth->{'FACTORY'}->createLiteral($ored, undef, $lang);

					print STDERR "LITERAL =".$node->toString,"\n"
						if($DBD::RDFStore::st::debug>1);

                                	push @query, $node;
				} elsif($ored=~/^_:([A-Za-z][A-Za-z0-9]*)$/) {
                        		#bNode joining in
                               		$node = $sth->{'FACTORY'}->createAnonymousResource($1);

					print STDERR "bNode=",$node->toString,"\n"
						if($DBD::RDFStore::st::debug>1);
                                	push @query, $node;
				} elsif($ored=~/^([^>]+)$/) {
					$operators_and_nums[(2*$j)+1]++;
                			$node = $sth->{'FACTORY'}->createResource($1);

					print STDERR "NODE1=",$node->toString,"\n"
						if($DBD::RDFStore::st::debug>1);

                        		push @query, $node;
					};
			} split(/\s+,\s+/, $1); #hack for OR-ed nodes
                } else {
			my $string = $tp[$j];

			my $isft=0;
			$isft=1
                               	if(     ($string =~ s/^%//) && #my free-text extensions
                               		($string =~ s/%$//) );

			my $lang=$1
				if($string =~ s/\@([a-z0-9]+(-[a-z0-9]+)?)\s*//m); #xml:lang

			# for literal or free-text remove quotes
                        $string =~ s/^\s*["']//;
                        $string =~ s/["']\s*$//;

                        # free-text query part
                        if ($isft) {
				# ok we try the clever one:
				#   1 - try to match ANDed words e.g. string1 & string2 & string3
				#   2 - otherwise try to match ORed words e.g. string1 | string2 | string3
				#   3 - otheriwse try NOTed words ~string1 ~string2 ~string3
				my @words = split /\&/, $string;
				if ( $#words > 0 ) {
					my @ww;
					map {
                                		s/^\s+//;
						s/\s+$//;
						s/['"]//;
						s/^\s*$//;
						push @ww, $_ if($_ ne '');
					} @words;
					$operators_and_nums[12]=1; #AND
					$operators_and_nums[13]=$#ww+1;
                                	push @ft_query, (@ww);
				} else {
					@words = split /\|/, $string;
					if ( $#words > 0 ) {
						my @ww;
						map {
                                			s/^\s+//;
							s/\s+$//;
							s/['"]//;
							s/^\s*$//;
							push @ww, $_ if($_ ne '');
						} @words;
						$operators_and_nums[12]=0; #OR
						$operators_and_nums[13]=$#ww+1;
                                		push @ft_query, (@ww);
					} else {
						@words = split /\~/, $string;
						if ( $#words > 0 ) {
							my @ww;
							map {
                                				s/^\s+//;
								s/\s+$//;
								s/['"]//;
								s/^\s*$//;
								push @ww, $_ if($_ ne '');
							} @words;
							$operators_and_nums[12]=2; #NOT
							$operators_and_nums[13]=$#ww+1;
                                			push @ft_query, (@ww);
						} else {
							$operators_and_nums[12]=1; #AND in only one word for the moment
							$operators_and_nums[13]=1;
                                			push @ft_query, ($string);
							};
						};
					};
                        } else {
				$operators_and_nums[(2*$j)+1]++;

				# to add rdf:datatype and rdf:parseType too - see RDQL spec
                        	$node = $sth->{'FACTORY'}->createLiteral($string, undef, $lang);
                                push @query, $node;
                                };

			print STDERR "LITERAL or FREETEXT=".join(',',(@query, @ft_query) )."\n"
				if($DBD::RDFStore::st::debug>1);
                        };
		};

print STDERR "TO SEARCH=".join(',',( @operators_and_nums, ( map { if(ref($_)) { $_->toString; } else { $_ }; } (@query,@ft_query) ) ) )."\n" if($DBD::RDFStore::st::debug>1);

	return ($search_type, @operators_and_nums, @query, @ft_query);
	};

sub rows {
        my $sth = shift;

        #my $data = $sth->FETCH('driver_data');
        #return $#{$data}+1;

        return -1; #we do *not* want to know the number of rows affected at the moment due to efficency problems :)
};

sub fetchrow_arrayref {
        my($sth) = @_;

	return _fetchrow_RDF($sth)
		if(exists $sth->{AS_RDF});

	#reset
	$sth->{'result'} = {};
	$sth->{'result_statements'} = {}
		if(exists $sth->{'AS_RDF'} and $sth->{'AS_RDF'}->{syntax} =~ m#(RDF/XML|N-Triples)#i);

        my $row = _each( $sth );

        return undef
        	unless $row;

        return $sth->_set_fbav( $row );
};

*fetch = \&fetchrow_arrayref; # required alias for fetchrow_arrayref

# should be streaming
sub _fetchrow_RDF {
        my($sth) = @_;

	if(scalar( keys %{$sth->{'result'}} ) <= 0 ) {
		if($sth->{'AS_RDF'}->{syntax} =~ m#(RDF/XML|rdfqr-results|rdf-for-xml)#i) {
			_printRDFContent( $sth, '<?xml version="1.0"?>'."\n");
			_printRDFContent( $sth, "\n<!--\n" . $sth->{'AS_RDF'}->{comment} ."\n-->\n\n")
				if(exists $sth->{'AS_RDF'}->{comment});
		} elsif($sth->{'AS_RDF'}->{syntax} =~ m/N-Triples/i) {
			_printRDFContent( $sth,  join('# ',split(/\n/,$sth->{'AS_RDF'}->{comment})) ."\n\n")
				if(exists $sth->{'AS_RDF'}->{comment});
			};
		if($sth->{'AS_RDF'}->{syntax} =~ m/rdfqr-results/i) {
			# see http://www.w3.org/2003/03/rdfqr-tests/recording-query-results.html
			$sth->{'num_results'}=0;
			_printRDFContent( $sth, "<rdf:RDF\n   xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'   xmlns:rs='http://jena.hpl.hp.com/2003/03/result-set#'>\n<rs:ResultSet rdf:about=''>\n");
			map {
				my $ff = $_;
				$ff =~ s/^\?//;
        			_printRDFContent( $sth, "      <rs:resultVariable>$ff</rs:resultVariable>\n");
			} @{ $sth->FETCH ('NAME') };
		} elsif($sth->{'AS_RDF'}->{syntax} =~ m/rdf-for-xml/i) {
			# see http://jena.hpl.hp.com/~afs/RDF-XML.html
			$sth->{'num_results'}=0;
			_printRDFContent( $sth, "<resultSet>\n");
			_printRDFContent( $sth, "   <vars>\n");
			map {
				my $ff = $_;
				$ff =~ s/^\?//;
				_printRDFContent( $sth, "      <var>$ff</var>\n");
			} @{ $sth->FETCH ('NAME') };
			_printRDFContent( $sth, "   </vars>\n");
		} elsif($sth->{'AS_RDF'}->{syntax} =~ m#RDF/XML#i) {
			_printRDFContent( $sth, "<allsubgraphs xmlns='http://rdfstore.sourceforge.net/rdql/'>\n");
			};
		};

	#reset
	$sth->{'result'} = {};

	$sth->{'result_statements'} = {}
		if(exists $sth->{'AS_RDF'} and $sth->{'AS_RDF'}->{syntax} =~ m#(RDF/XML|N-Triples)#i);

        my $row = _each( $sth );

	if ($row) {
		if($sth->{'AS_RDF'}->{syntax} =~ m/rdfqr-results/i) {
			$sth->{'num_results'}++;
			_printRDFContent( $sth, "\n     <rs:solution>\n   <rs:ResultSolution>\n");
			for my $i (0..$#{$row}) {
				my $ff = $sth->FETCH ('NAME')->[$i];
				$ff =~ s/^\?//;
           			_printRDFContent( $sth, "            <rs:binding rdf:parseType='Resource'>\n");
              			_printRDFContent( $sth, "               <rs:variable>$ff</rs:variable>\n");
              			_printRDFContent( $sth, "               <rs:value");
				if($row->[$i]->isa("RDFStore::Resource")) {
                        		_printRDFContent( $sth, " ");
					if ( $row->[$i]->isbNode ) {
                               			_printRDFContent( $sth, "rdf:nodeID='" . $row->[$i]->getLabel);
                        		} else {
                               			_printRDFContent( $sth, "rdf:resource='" . $DBD::RDFStore::st::serializer->xml_escape( $row->[$i]->getURI,"'" ));
                               			};
                        		_printRDFContent( $sth, "' />\n");
                		} else {
                        		_printRDFContent( $sth, " xml:lang='" . $row->[$i]->getLang . "'")
						if($row->[$i]->getLang);
					_printRDFContent( $sth, " rdf:datatype='" . $row->[$i]->getDataType . "'")
                               			if($row->[$i]->getDataType);
					if($row->[$i]->getParseType) {
						_printRDFContent( $sth, " rdf:parseType='Literal'>");
                               			_printRDFContent( $sth, $row->[$i]->getLabel);
					} else {
						_printRDFContent( $sth, ">" . $DBD::RDFStore::st::serializer->xml_escape( $row->[$i]->getLabel ));
						};
                        		_printRDFContent( $sth, "</rs:value>\n");
                        		};
				_printRDFContent( $sth, "            </rs:binding>\n");
				};

			_printRDFContent( $sth, "\n         </rs:ResultSolution>\n     </rs:solution>\n");
		} elsif($sth->{'AS_RDF'}->{syntax} =~ m/rdf-for-xml/i) {
			$sth->{'num_results'}++;
			_printRDFContent( $sth, "   <solution>\n");
			for my $i (0..$#{$row}) {
				my $ff = $sth->FETCH ('NAME')->[$i];
				$ff =~ s/^\?//;
           			_printRDFContent( $sth, "      <binding>\n");
              			_printRDFContent( $sth, "         <var>$ff</var>\n");
				if($row->[$i]->isa("RDFStore::Resource")) {
					if ( $row->[$i]->isbNode ) {
              					_printRDFContent( $sth, "         <bNode>". $row->[$i]->getLabel ."</bNode>\n");
                        		} else {
              					_printRDFContent( $sth, "         <uri>".$DBD::RDFStore::st::serializer->xml_escape( $row->[$i]->getURI )."</uri>\n");
                               			};
                		} else {
              				_printRDFContent( $sth, "         <value");
                        		_printRDFContent( $sth, " xml:lang='" . $row->[$i]->getLang . "'")
						if($row->[$i]->getLang);
					# no clue how to do this - probably we should have a full blown XSD namespace declared???
					#_printRDFContent( $sth, " rdf:datatype='" . $row->[$i]->getDataType . "'")
                               		#	if($row->[$i]->getDataType);
					if($row->[$i]->getParseType) {
						_printRDFContent( $sth, ">");
                               			_printRDFContent( $sth, $row->[$i]->getLabel);
					} else {
						_printRDFContent( $sth, ">" . $DBD::RDFStore::st::serializer->xml_escape( $row->[$i]->getLabel ));
						};
                        		_printRDFContent( $sth, "</value>\n");
                        		};
           			_printRDFContent( $sth, "      </binding>\n");
				};

			_printRDFContent( $sth, "   </solution>\n");
		} elsif($sth->{'AS_RDF'}->{syntax} =~ m#RDF/XML#i) {
			my $mm = new RDFStore::Model;
			map { $mm->add( $sth->{'result_statements'}->{$_} ); } keys %{$sth->{'result_statements'}};

			if(     exists $sth->{'AS_RDF'}->{output} and
				ref($sth->{'AS_RDF'}->{output}) and
				UNIVERSAL::isa($sth->{'AS_RDF'}->{output}, 'IO::Handle') ) {
				$mm->serialize($sth->{'AS_RDF'}->{output}, $sth->{'AS_RDF'}->{syntax} );
        		} elsif(	exists $sth->{'AS_RDF'}->{'output_string'} and
					ref($sth->{'AS_RDF'}->{'output_string'}) =~ /SCALAR/ ) {
				${ $sth->{'AS_RDF'}->{'output_string'} } .= join('', $mm->serialize(undef, $sth->{'AS_RDF'}->{syntax} ));
			} else {
				$mm->serialize(\*STDOUT, $sth->{'AS_RDF'}->{syntax} );
				};
			_printRDFContent( $sth, "\n");
		} else {
			map { _printRDFContent( $sth, $sth->{'result_statements'}->{$_}->toString."\n"); } keys %{$sth->{'result_statements'}};
			};
	} else {
		if($sth->{'AS_RDF'}->{syntax} =~ m/rdfqr-results/i) {
			_printRDFContent( $sth, "\n<rs:size rdf:datatype='http://www.w3.org/2000/10/XMLSchema#integer'>".$sth->{'num_results'}."</rs:size>\n   </rs:ResultSet>\n</rdf:RDF>\n");
		} elsif($sth->{'AS_RDF'}->{syntax} =~ m/rdf-for-xml/i) {
			_printRDFContent( $sth, "</resultSet>\n");
		} elsif($sth->{'AS_RDF'}->{syntax} =~ m#RDF/XML#i) {
			_printRDFContent( $sth, '</allsubgraphs>');
			};

        	return undef;
		};

        return $sth->_set_fbav( $row );
	};

sub _printRDFContent {
        my ($sth) = shift;

        if(	exists $sth->{'AS_RDF'}->{output} and
		ref($sth->{'AS_RDF'}->{output}) and
		UNIVERSAL::isa($sth->{'AS_RDF'}->{output}, 'IO::Handle') ) {
                print ${ $sth->{'AS_RDF'}->{output} } (@_);
        } elsif(	exists $sth->{'AS_RDF'}->{'output_string'} and
			ref($sth->{'AS_RDF'}->{'output_string'}) =~ /SCALAR/ ) { #DBI interface hack due it forces to use its API ;)
		${ $sth->{'AS_RDF'}->{'output_string'} } .= join('',@_); #even though is dangerous!
        } else {
                print (@_); #STDOUT
                };
        };

sub FETCH {
	my $sth = shift;
        my $key = shift;

	return $sth->{NAME} if $key eq 'NAME';

	return $sth->SUPER::FETCH($key);
	};

sub STORE {
	my $sth = shift;
        my ($key, $value) = @_;

	if ($key eq 'NAME') {
        	$sth->{NAME} = $value;
                return 1;
        	};

	return $sth->SUPER::STORE($key, $value);
	};

sub DESTROY {
};

1;

__END__

=head1 NAME

DBD::RDFStore - Simple DBI driver for RDFStore using RDQL:Parser

=head1 SYNOPSIS

	use DBI;

	# on the local disk
	$dbh = DBI->connect( "DBI:rdfstore:database=cooltest", "user", "password" );

	# on a remote dbmsd(8) server
	$dbh = DBI->connect( "DBI:rdfstore:database=cooltest;host=localhost;port=1234", "user", "password" );

	# or in the fly
	$dbh = DBI->connect( "DBI:rdfstore", "user", "password" );

	$sth = $dbh->prepare(<<QUERY);

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

	my $num_rows = $sth->execute();

	print "news from XMLhack.com\n" if($num_rows == $sth->rows);

	$sth->bind_columns(\$title, \$link);

	while ($sth->fetch()) {
		print "title=$title lin=$link\n";
		};
	$sth->finish();

=head1 DESCRIPTION

TODO

=head1 SEE ALSO

DBI(3) RDQL::Parser(3) RDFStore(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>

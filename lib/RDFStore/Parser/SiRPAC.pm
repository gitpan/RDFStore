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
# *	version 0.1 - 2000/11/03 at 04:30 CEST
# *	version 0.2
# * 		- fixed bug in parsefile() to read URL-less filenames
# *		  (version0.1 was working only with 'file:' URL prefix)
# *		- fixed a lot of bugs/inconsistences in new(), parse(), setSource(), parsestring()
# *		  processXML() in the fetchSchema part, makeAbsolute()
# *		- added parse_start a la XML::parser for no-blocking stream
# *		  parsing using XML::Parser::ExpatNB
# *		- pod documentation updated
# *             - does not use URI::file anymore
# *		- Modified createResource(), RDFStore::Parser::SiRPAC::Element and 
# *		  RDFStore::Parser::SiRPAC::DataElement accordingly to rdf-api-2000-10-30 
# *		- General bug fixing accordingly to rdf-api-2000-10-30
# *		  NOTE: Expat supports well XML Namespaces and SiRPAC could use all the
# *		  XML::Parser Namespace methods (e.g. generate_namespace()) to generate the
# *		  corresponding Qname; it uses arrays and simple operations instead for efficency
# *	version 0.3
# *		- fixed bug in expandAttributes() when expand rdf:value
# *		- Modified addOrder() expandAttributes() accordingly to rdf-api-2000-11-13
# *		- fixed bug in parse() parse_start() to set the Source right
# *		- fixed bug in RDFXML_StartElementHandler() when parseLiteral process attributes also
# *		- fixed bug in processTypedNode() to manage new attlist way
# *		- fixed bug in processPredicate() to manage new attlist way
# *		- fixed bugs due to the modifications due rdf-api-2000-10-30. Now $n->{tag} is either
# *		  $n->name() or $n->localName(); code got more clear also
# *		- fixed addTriple() and reify() - more checking and modified to manage right $subject
# *     version 0.31
# *             - updated documentation
# *		- fixed bug in parse_start() and parse() to check $file_or_uri
# *		  is a reference to an URI object
# *		- changed wget() Socket handle to work with previous Perl versions (not my $handle) and
# *		  do HTTP GET even on HTTP 'Location' redirect header
# *		- fixed bug in RDFXML_CharacterDataHand() when trim text and $preserveWhiteSpace
# *		- fixed bug in processTypedNode() when remove attributes
# *		- commented off croak in expandAttributes() when 'expanding predicate element' for 
# *		  production http://www.w3.org/TR/REC-rdf-syntax/#typedNode for xhtml2rdf stuff
# *     version 0.4
# *		- changed way to return undef in subroutines
# *		- now creation of Bag instances for each Description block is an option
# *		- fixed a few warnings
# *		- fixed bug in getAttributeValue() when check attribute name
# *		- fixed bug in setSource() when add trailing '#' char
# *		- added bug fixing in RDFXML_StartElementHandler(), newReificationID() and processPredicate() by rob@eorbit.net
# *		- fixed warnings in getAttributeValue(), RDFXML_StartElementHandler()
# *		- added GenidNumber parameter
# *		- updated accordingly to http://www.w3.org/RDF/Implementations/SiRPAC/
# *		- bug fix in reify() when generate the subject property triple
# *		- added getReificationCounter()
# *     version 0.41
# *		- fixed bug with XML::Parser 2.30 using expat-1.95.1
# *		     * XMLSCHEMA set to http://www.w3.org/XML/1998/namespace (see http://www.w3.org/TR/1999/REC-xml-names-19990114/#ns-using)
# *		     * added XMLSCHEMA_prefix
# *		- changed RDF_SCHEMA_NS to http://www.w3.org/2000/01/rdf-schema#
# *     version 0.42
# *		- updated accordingly to RDF Core Working Group decisions (see
# *		  http://www.w3.org/2000/03/rdf-tracking/#attention-developers)
# *			* rdf-ns-prefix-confusion (carp if error)
# *			* rdfms-abouteachprefix (removed aboutEachPrefix)
# *			* rdfms-empty-property-elements (updated  processDescription() and processPredicate())
# *			* rdf-containers-formalmodel (updated processListItem())
# *		- added RDFCore_Issues option
# *		- fixed bug when calling setSource() internally
# *		- updated makeAbsolute()
# *		- fixed bug in processListItem() when calling processContainer()
# *		- fixed bug in processPredicate() for empty predicate elements having zero attributes
# *
# *

package RDFStore::Parser::SiRPAC;
{
	use vars qw($VERSION %Built_In_Styles $RDF_SYNTAX_NS $RDF_SCHEMA_NS $RDFX_NS $XMLSCHEMA_prefix $XMLSCHEMA $XML_space $XML_space_preserve $XMLNS $RDFMS_parseType $RDFMS_type $RDFMS_about $RDFMS_bagID $RDFMS_resource $RDFMS_aboutEach $RDFMS_ID $RDFMS_RDF $RDFMS_Description $RDFMS_Seq $RDFMS_Alt $RDFMS_Bag $RDFMS_predicate $RDFMS_subject $RDFMS_object $RDFMS_Statement);
	use strict;
	use Carp qw(carp croak cluck confess);
	use URI;
	use URI::Escape;
	use Socket;

BEGIN
{
	require XML::Parser::Expat;
    	$VERSION = '0.42';
    	croak "XML::Parser::Expat.pm version 2 or higher is needed"
		unless $XML::Parser::Expat::VERSION =~ /^2\./;
}

$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
$RDFStore::Parser::SiRPAC::RDF_SCHEMA_NS="http://www.w3.org/2000/01/rdf-schema#";
$RDFStore::Parser::SiRPAC::RDFX_NS="http://interdataworking.com/vocabulary/order-20000527#";
$RDFStore::Parser::SiRPAC::XMLSCHEMA_prefix="xml";
$RDFStore::Parser::SiRPAC::XMLSCHEMA="http://www.w3.org/XML/1998/namespace";
$RDFStore::Parser::SiRPAC::XML_space=$RDFStore::Parser::SiRPAC::XMLSCHEMA."space";
$RDFStore::Parser::SiRPAC::XML_space_preserve="preserve";
$RDFStore::Parser::SiRPAC::XMLNS="xmlns";
$RDFStore::Parser::SiRPAC::RDFMS_parseType = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "parseType";
$RDFStore::Parser::SiRPAC::RDFMS_type = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "type";
$RDFStore::Parser::SiRPAC::RDFMS_about = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "about";
$RDFStore::Parser::SiRPAC::RDFMS_bagID = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "bagID";
$RDFStore::Parser::SiRPAC::RDFMS_resource = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "resource";
$RDFStore::Parser::SiRPAC::RDFMS_aboutEach = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "aboutEach";
$RDFStore::Parser::SiRPAC::RDFMS_ID = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "ID";
$RDFStore::Parser::SiRPAC::RDFMS_RDF = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "RDF";
$RDFStore::Parser::SiRPAC::RDFMS_Description = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "Description";
$RDFStore::Parser::SiRPAC::RDFMS_Seq = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "Seq";
$RDFStore::Parser::SiRPAC::RDFMS_Alt = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "Alt";
$RDFStore::Parser::SiRPAC::RDFMS_Bag = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "Bag";
$RDFStore::Parser::SiRPAC::RDFMS_predicate = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "predicate";
$RDFStore::Parser::SiRPAC::RDFMS_subject = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "subject";
$RDFStore::Parser::SiRPAC::RDFMS_object = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "object";
$RDFStore::Parser::SiRPAC::RDFMS_Statement = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS . "Statement";

sub new {
    	my ($class, %args) = @_;
    	my $style = $args{Style};

	my $nonexopt = $args{Non_Expat_Options} ||= {};

	$nonexopt->{Style}             = 1;
	$nonexopt->{Non_Expat_Options} = 1;
	$nonexopt->{Handlers}          = 1;
	$nonexopt->{_HNDL_TYPES}       = 1;

	$args{_HNDL_TYPES} = {};
	$args{_HNDL_TYPES}->{Init} = 1;
	$args{_HNDL_TYPES}->{Assert} = 1;
	$args{_HNDL_TYPES}->{Start_XML_Literal} = 1;
	$args{_HNDL_TYPES}->{Stop_XML_Literal} = 1;
	$args{_HNDL_TYPES}->{Char_Literal} = 1;
	$args{_HNDL_TYPES}->{Final} = 1;

	$args{Handlers} ||= {};
    	my $handlers = $args{Handlers};
    	if (defined($style))
	{
		my $stylepkg = $style;
		if ($stylepkg !~ /::/)
		{
	    		$stylepkg = "\u$style";
	    		croak "Undefined style: $style" 
				unless defined($Built_In_Styles{$stylepkg});
	    		$stylepkg = 'RDFStore::Parser::SiRPAC::' . $stylepkg;
		}

		my $htype;
		foreach $htype (keys %{$args{_HNDL_TYPES}})
		{
	    		# Handlers explicity given override
	    		# handlers from the Style package
	    		unless (defined($handlers->{$htype}))
			{
				# A handler in the style package must either have
				# exactly the right case as the type name or a
				# completely lower case version of it.
				my $hname = "${stylepkg}::$htype";
				if (defined(&$hname))
				{
		    			$handlers->{$htype} = \&$hname;
		    			next;
				}
				$hname = "${stylepkg}::\L$htype";
				if (defined(&$hname))
				{
		    			$handlers->{$htype} = \&$hname;
		    			next;
				}
	    		}
		}
	}
    	$args{Pkg} ||= caller;

    	bless \%args, $class;
}

sub setHandlers {
	my ($class, @handler_pairs) = @_;

	croak("Uneven number of arguments to setHandlers method") 
		if (int(@handler_pairs) & 1);

	my @ret;
	while (@handler_pairs) {
		my $type = shift @handler_pairs;
		my $handler = shift @handler_pairs;
		unless (defined($class->{_HNDL_TYPES}->{$type})) {
			my @types = sort keys %{$class->{_HNDL_TYPES}};
	    		croak("Unknown Parser handler type: $type\n Valid types are : @types");
		}
		push(@ret, $type, $class->{Handlers}->{$type});
		$class->{Handlers}->{$type} = $handler;
    	};
	return @ret;
}
sub setSource {
  	my ($file_or_uri)=@_;

	return
		unless(defined $file_or_uri);

	$file_or_uri .= '#'
		unless(	($file_or_uri =~ /#$/) ||
			($file_or_uri =~ /\/$/) ||
			($file_or_uri =~ /:$/) );
	return $file_or_uri;
};

sub parse_start {
	my $class = shift;
	my $file_or_uri = shift;

	my @expat_options = ();
	my ($key, $val);
	while (($key, $val) = each %{$class}) {
		push(@expat_options, $key, $val) 
			unless exists $class->{Non_Expat_Options}->{$key};
      	}

	#Run Expat
	my @parser_parameters=(	@expat_options,
				@_,
				( Namespaces => 1 ) ); #RDF needs Namespaces option on :)
    	my $firstnb = new XML::Parser::ExpatNB(@parser_parameters);

	$firstnb->{SiRPAC} = {};

	#flag whether or not use the latest RDF Core W3C recommandations
  	$firstnb->{SiRPAC}->{RDFCore_Issues} = (	(defined $class->{RDFCore_Issues}) &&
							($class->{RDFCore_Issues} =~ m/(1|yes)/) ) ? 1 : 0;

	#keep me in that list :)
	$firstnb->{SiRPAC}->{parser} = $class;

	#from libwww & SiRPAC
  	$firstnb->{SiRPAC}->{elementStack} = [];
  	$firstnb->{SiRPAC}->{root}='';
  	$firstnb->{SiRPAC}->{EXPECT_Element}='';
  	$firstnb->{SiRPAC}->{iReificationCounter}= ( ($class->{GenidNumber}) && (int($class->{GenidNumber})) ) ? $class->{GenidNumber} : 0;
	$class->{iReificationCounter} = \$firstnb->{SiRPAC}->{iReificationCounter};
	if(	(exists $class->{Source}) && 
			(defined $class->{Source}) &&
			( (!(ref($class->{Source}))) || (!($class->{Source}->isa("URI"))) )	) {
		if(-e $class->{Source}) {
			$class->{Source}=URI->new('file:'.$class->{Source});
		} else {
			$class->{Source}=URI->new($class->{Source});
		};
	} elsif(defined $file_or_uri) {
		if( (ref($file_or_uri)) && ($file_or_uri->isa("URI")) ) {
			$class->{Source}=$file_or_uri;
		} elsif(-e $file_or_uri) {
			$class->{Source}=URI->new('file:'.$file_or_uri);
		} else {
			$class->{Source}=undef; #unknown
		};
	};
	if(	(exists $class->{Source}) &&
		(defined $class->{Source}) ) {
  		$firstnb->{SiRPAC}->{sSource}= setSource(
			(	(ref($class->{Source})) &&
				($class->{Source}->isa("URI")) ) ? $class->{Source}->as_string :
						$class->{Source} );
	};

	# The walk-through of RDF schemas requires two lists
	# shared by all SiRPAC instances
	# 1. s_vNStodo - list of all namespaces SiRPAC should still vist
	# 2. s_vNSdone - list of all namespaces SiRPAC has gone through
  	$firstnb->{SiRPAC}->{vNStodo}=[];
  	$firstnb->{SiRPAC}->{vNSdone}=[];
	push @{$firstnb->{SiRPAC}->{vNSdone}}
		if(defined $firstnb->{SiRPAC}->{sSource});

	# The following two variables may be changed on the fly
	# to change the behaviour of the parser
	#
	# createBags method allows one to determine whether SiRPAC
	# produces Bag instances for each Description block.
	# The default setting is to generate them. - to be checked......
  	$firstnb->{SiRPAC}->{bCreateBags}=( ($class->{bCreateBags}) && (int($class->{bCreateBags})) ) ? $class->{bCreateBags} : 0;
	#
	# Set whether parser recursively fetches and parses
	# every RDF schema it finds in the namespace declarations
  	$firstnb->{SiRPAC}->{bFetchSchemas}=0;

	# The following flag indicates whether the XML markup
	# should be stored into a string as a literal value for RDF
  	$firstnb->{SiRPAC}->{parseElementStack} = [];
  	$firstnb->{SiRPAC}->{parseTypeStack} = [];
  	$firstnb->{SiRPAC}->{scanMode} = 'SKIPPING';
	$firstnb->{SiRPAC}->{sLiteral} = '';
	croak "Missing NodeFactory"
		unless(	(defined $class->{NodeFactory}) && 
			($class->{NodeFactory}->isa("RDFStore::Stanford::NodeFactory")) );
  	$firstnb->{SiRPAC}->{nodeFactory} = $class->{NodeFactory};

    	my %handlers = %{$class->{Handlers}}
		if( (defined $class->{Handlers}) && (ref($class->{Handlers}) =~ /HASH/) );

    	my $init = delete $handlers{Init};
    	my $final = delete $handlers{Final};

    	$firstnb->setHandlers(	Start => \&RDFXML_StartElementHandler,
				End => \&RDFXML_EndElementHandler,
				Char => \&RDFXML_CharacterDataHandler );

	#Trigger 'Init' event
    	&$init($firstnb) 
		if defined($init);

	$firstnb->{_State_} = 1;

	$firstnb->{parser_parameters} = \@parser_parameters;

	#if(defined($final)) {
	#	$firstnb->{FinalHandler} = sub {
	#		my $r= &$final($_[0]);
	#		$_[0]->release;
	#		return $r;
	#	};
	#} else {
	#	$firstnb->{FinalHandler} = sub {
	#		#$_[0]->release;
	#	};
	#};

	return $firstnb;
};

sub parse {
	my $class = shift;
	my $arg  = shift;
	my $file_or_uri = shift;

	my @expat_options = ();
	my ($key, $val);
	while (($key, $val) = each %{$class}) {
		push(@expat_options, $key, $val) 
			unless exists $class->{Non_Expat_Options}->{$key};
      	}

	#Run Expat
	my @parser_parameters=(	@expat_options,
				@_,
				( Namespaces => 1 ) ); #RDF needs Namespaces option on :)
    	my $first = new XML::Parser::Expat(@parser_parameters);

	$first->{SiRPAC} = {};

	#flag whether or not use the latest RDF Core W3C recommandations
  	$first->{SiRPAC}->{RDFCore_Issues} = (	(defined $class->{RDFCore_Issues}) &&
						($class->{RDFCore_Issues} =~ m/(1|yes)/) ) ? 1 : 0;

	#keep me in that list :)
	$first->{SiRPAC}->{parser} = $class;

	#from libwww & SiRPAC
  	$first->{SiRPAC}->{elementStack} = [];
  	$first->{SiRPAC}->{root}='';
  	$first->{SiRPAC}->{EXPECT_Element}='';
  	$first->{SiRPAC}->{iReificationCounter}= ( ($class->{GenidNumber}) && (int($class->{GenidNumber})) ) ? $class->{GenidNumber} : 0;
	$class->{iReificationCounter} = \$first->{SiRPAC}->{iReificationCounter};
	if(	(exists $class->{Source}) && 
			(defined $class->{Source}) &&
			( (!(ref($class->{Source}))) || (!($class->{Source}->isa("URI"))) )	) {
		if(-e $class->{Source}) {
			$class->{Source}=URI->new('file:'.$class->{Source});
		} else {
			$class->{Source}=URI->new($class->{Source});
		};
	} elsif(	(defined $file_or_uri) && (ref($file_or_uri)) &&
		($file_or_uri->isa("URI"))	) {
		$class->{Source}=$file_or_uri;
	};
	if(	(exists $class->{Source}) &&
		(defined $class->{Source}) ) {
  		$first->{SiRPAC}->{sSource}= setSource(
			(	(ref($class->{Source})) &&
				($class->{Source}->isa("URI")) ) ? $class->{Source}->as_string :
						$class->{Source} );
		$first->base($first->{SiRPAC}->{sSource});
	};

	# The walk-through of RDF schemas requires two lists
	# shared by all SiRPAC instances
	# 1. s_vNStodo - list of all namespaces SiRPAC should still vist
	# 2. s_vNSdone - list of all namespaces SiRPAC has gone through
  	$first->{SiRPAC}->{vNStodo}=[];
  	$first->{SiRPAC}->{vNSdone}=[];
	push @{$first->{SiRPAC}->{vNSdone}}
		if(defined $first->{SiRPAC}->{sSource});

	# The following two variables may be changed on the fly
	# to change the behaviour of the parser
	#
	# createBags method allows one to determine whether SiRPAC
	# produces Bag instances for each Description block.
	# The default setting is to generate them. - to be checked......
  	$first->{SiRPAC}->{bCreateBags}=( ($class->{bCreateBags}) && (int($class->{bCreateBags})) ) ? $class->{bCreateBags} : 0;
	#
	# Set whether parser recursively fetches and parses
	# every RDF schema it finds in the namespace declarations
  	$first->{SiRPAC}->{bFetchSchemas}=0;

	# The following flag indicates whether the XML markup
	# should be stored into a string as a literal value for RDF
  	$first->{SiRPAC}->{parseElementStack} = [];
  	$first->{SiRPAC}->{parseTypeStack} = [];
  	$first->{SiRPAC}->{scanMode} = 'SKIPPING';
	$first->{SiRPAC}->{sLiteral} = '';
	croak "Missing NodeFactory"
		unless(	(defined $class->{NodeFactory}) && 
			($class->{NodeFactory}->isa("RDFStore::Stanford::NodeFactory")) );
  	$first->{SiRPAC}->{nodeFactory} = $class->{NodeFactory};

    	my %handlers = %{$class->{Handlers}}
		if( (defined $class->{Handlers}) && (ref($class->{Handlers}) =~ /HASH/) );

    	my $init = delete $handlers{Init};
    	my $final = delete $handlers{Final};

    	$first->setHandlers(	Start => \&RDFXML_StartElementHandler,
				End => \&RDFXML_EndElementHandler,
				Char => \&RDFXML_CharacterDataHandler );

	#Trigger 'Init' event
    	&$init($first) 
		if defined($init);

	my $result;
	my @result=();
	eval {
    		$result = $first->parse($arg);
	};
	my $err = $@;
	if($err) {
		$first->release;
		croak $err;
	};

	$first->{parser_parameters} = \@parser_parameters;

	if ( (defined $result) and (defined $final) ) {
		#Trigger 'Final' event
    		if(wantarray) {
      			@result = &$final($first);
    		} else {
			$result = &$final($first);
    		};
	};
	$first->release;

	return unless defined wantarray;
	return wantarray ? @result : $result;
};

sub getReificationCounter {
	return ${$_[0]->{iReificationCounter}};
};

sub parsestring {
	my $class = shift;
	my $string = shift;

	return $class->parse($string,undef,@_);
}

sub parsefile {
	my $class = shift;
	my $file = shift;

	if( (defined $file) && ($file ne '') ) {
		my $ret;
		my @ret=();
		my $file_uri;
		my $scheme;
		$scheme='file:'
			if( (-e $file) || (!($file =~ /^\w+:/)) );
                $file_uri= URI->new($scheme.$file);
		if (	(defined $file_uri) && (defined $file_uri->scheme)	&&
			($file_uri->scheme ne 'file') ) {
  			my $wget_handle = $class->wget($file_uri);
			if(defined $wget_handle) {
				if (wantarray) { 	
					eval {
						@ret = $class->parse($wget_handle, $file_uri,@_);
    					};
				} else {
					eval {
						$ret = $class->parse($wget_handle, $file_uri,@_);
    					};
				};
    				my $err = $@;
    				croak $err 	
					if $err;
                        } else {
				croak "Cannot fetch '$file_uri'";
			};
    		} else {
			my $filename= $file_uri->file;

			# FIXME: it might be wrong in some cases
			local(*FILE);
			open(FILE, $filename) 
				or  croak "Couldn't open $filename:\n$!";
			binmode(FILE);
			if (wantarray) { 	
				eval {
					@ret = $class->parse(*FILE,$file_uri,@_);
    				};
			} else {
				eval {
					$ret = $class->parse(*FILE,$file_uri,@_);
    				};
			};
    			my $err = $@;
    			close(FILE);
    			croak $err 	
				if $err;
		};
		return unless defined wantarray;
		return wantarray ? @ret : $ret;
  	};
};

sub wget {
	my ($class,$uri) = @_;

	croak "wget: input url is not an instance of URI"
                unless( (defined $uri) && ($uri->isa("URI")) );

	# well, try to be serious here :)
	no strict;

	my $iaddr = inet_aton($uri->host)
		or croak "no host '$uri->host'";
	my $paddr = sockaddr_in($uri->port,$iaddr);
	my $proto = 6;
	socket(S,PF_INET,SOCK_STREAM,$proto)
		or croak "Cannot get my socket: $!";
	connect(S,$paddr)
		or croak " Cannot connect: $!";

	select((select(S), $| = 1)[0]);

        print S "GET ",$uri->as_string," HTTP/1.0\r\nUser-Agent: Alberto.Reggiori\@jrc.it\r\n\r\n";
        my $line = <S>;
        if (!($line =~ m#^HTTP/(\d+)\.(\d+) (\d\d\d) (.+)$#)) {
		close(S);
                warn "Did not get HTTP/X.X header back...$line";
                return;
        };
        my $status = $3;
        my $reason = $4;
	if ( ($status != 200) && ($status != 302) ) {
		close(S);
                warn "Error MSG returned from server: $status $reason\n";
                return;
        };
        while(<S>) {
        	chomp;
		if(m/Location\:\s(.*)$/) {
                        if( ( 	(exists $class->{HTTP_Location}) &&
				(defined $class->{HTTP_Location}) && ($class->{HTTP_Location} ne $1)	) || 
					(!(defined $class->{HTTP_Location})) ) {
                                $class->{HTTP_Location} = $1;
                                *S = $class->wget(new URI($class->{HTTP_Location}));
                                last;
                        };
                };
                last if m/^\s+$/;
        };

	return *S;
};

sub getAttributeValue {
	my ($expat,$attlist, $elName) = @_;

#print STDERR "getAttributeValue(@_): ".(caller)[2]."\n";

  	return
		if( (ref($attlist) =~ /ARRAY/) && (!@{$attlist}) );

	my $n;
	for($n=0; $n<=$#{$attlist}; $n+=2) {
    		my $attname;
		if(ref($attlist->[$n]) =~ /ARRAY/) {
    			#$attname = $attlist->[$n]->[0].$attlist->[$n]->[1];
    			$attname = $attlist->[$n]->[0];
    			$attname .= $attlist->[$n]->[1]
				if(defined $attlist->[$n]->[1]);
		} else {
			$attname = $attlist->[$n];
		};
    		return $attlist->[$n+1]
			if ($attname eq $elName);
  	};
  	return;
}

sub RDFXML_StartElementHandler {
	my $expat = shift;
	my $tag = shift;
	my @attlist = @_;

	my $xml_tag = $tag; # save it for later

	# Stack up the vNStodo namespace list - we could do it with map()
	my $sNamespace = $expat->namespace($tag);

	if(not(defined $sNamespace)) {			
		my ($prefix,$suffix) = split(':',$tag);
		if($prefix eq $RDFStore::Parser::SiRPAC::XMLSCHEMA_prefix) {
			$sNamespace = $RDFStore::Parser::SiRPAC::XMLSCHEMA;
			$tag = $expat->generate_ns_name($suffix,$sNamespace);
		} else {
			$expat->xpcroak("Unresolved namespace prefix '$prefix' for '$suffix'")
				if( (defined $prefix) && (defined $suffix) );
		};
        };
	push @{$expat->{SiRPAC}->{vNStodo}},$sNamespace
		unless( (defined $sNamespace) &&
			($sNamespace ne '') &&
			($#{$expat->{SiRPAC}->{vNStodo}}>=0) &&
			($#{$expat->{SiRPAC}->{vNSdone}}>=0) &&
			(grep /$sNamespace/,@{$expat->{SiRPAC}->{vNStodo}}) &&
			(grep /$sNamespace/,@{$expat->{SiRPAC}->{vNSdone}}) );

	my $newElement;

	my $setScanModeElement = 0;
	if($expat->{SiRPAC}->{scanMode} eq 'SKIPPING') {
		if( $sNamespace.$tag eq $RDFStore::Parser::SiRPAC::RDFMS_RDF ) {
                        $expat->{SiRPAC}->{scanMode} = 'RDF';
                        $setScanModeElement = 1;
                } elsif( $sNamespace.$tag eq $RDFStore::Parser::SiRPAC::RDFMS_Description ) {
                        $expat->{SiRPAC}->{scanMode} = 'TOP_DESCRIPTION';
                        $setScanModeElement = 1;
                };
	} elsif($expat->{SiRPAC}->{scanMode} eq 'RDF') {
		$expat->{SiRPAC}->{scanMode} = 'DESCRIPTION';
		$setScanModeElement = 1;
	};

	# speed up a bit...
	my $parseLiteral = (($expat->{SiRPAC}->{scanMode} ne 'SKIPPING') && (parseLiteral($expat)));
	if($expat->{SiRPAC}->{scanMode} ne 'SKIPPING') {
		my $n;
		for($n=0; $n<=$#attlist; $n+=2) {
    			my $attname = $attlist[$n];
			my $namespace = $expat->namespace($attname);
			unless(	(defined $namespace) &&
				($namespace ne '') ) { #default namespace
				my ($prefix,$suffix) = split(':',$attname);
				if( (defined $prefix) && (defined $suffix) ) {
					if($prefix eq $RDFStore::Parser::SiRPAC::XMLSCHEMA_prefix) {
						$namespace = $RDFStore::Parser::SiRPAC::XMLSCHEMA;
						$attlist[$n] = [$namespace,$suffix];
					} else {
						$expat->xpcroak("Unresolved namespace prefix '$prefix' for '$suffix'");
					};
				} else {
					if(	($attname eq 'resource') 	|| 
						($attname eq 'ID') 		|| 
						($attname eq 'about') 		|| 
						($attname eq 'aboutEach') 	|| 
						($attname eq 'bagID')		||
						($attname eq 'parseType')	||
						($attname eq 'type') ) {
						$expat->xpcroak("'$attname' attribute must be namespace qualified - see http://www.w3.org/2000/03/rdf-tracking/#rdf-ns-prefix-confusion")
							if($expat->{SiRPAC}->{RDFCore_Issues});
						#default to RDFMS
						$namespace = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS;
					} else {
                                                $namespace = undef;
                                        };
					$attlist[$n]=[$namespace,$attname];
				};
			} else {
				$attlist[$n]=[$namespace,$attname];
			};
			push @{$expat->{SiRPAC}->{vNStodo}}, $namespace
				unless( (defined $namespace) &&
					($namespace ne '') &&
					($#{$expat->{SiRPAC}->{vNStodo}}>=0) &&
                        		($#{$expat->{SiRPAC}->{vNSdone}}>=0) &&
					(grep /$namespace/,@{$expat->{SiRPAC}->{vNStodo}}) &&
					(grep /$namespace/,@{$expat->{SiRPAC}->{vNSdone}}) );
  		};
	};

	# If we have parseType="Literal" set earlier, this element
        # needs some additional attributes to make it stand-alone
        # piece of XML
	if($parseLiteral) {
		#ignored for the moment
		$newElement =  RDFStore::Parser::SiRPAC::Element->new($sNamespace,$tag,\@attlist);
	} else {
		#....and probably Expat has already something like this.....
		$newElement =  RDFStore::Parser::SiRPAC::Element->new($sNamespace,$tag,\@attlist);
	};

	$expat->{SiRPAC}->{EXPECT_Element} = $newElement
		if($setScanModeElement);

	my $sLiteralValue;
	if($expat->{SiRPAC}->{scanMode} ne 'SKIPPING') {

		# goes through the attributes of newElement to see
	 	# 1. if there are symbolic references to other nodes in the data model.
		# in which case they must be stored for later resolving with
		# resolveLater method (fix aboutEach on streaming!!!)
		# 2. if there is an identity attribute, it is registered using
		# registerResource or registerID method. 
	
       		my $sResource = getAttributeValue($expat,$newElement->{attlist},
				$RDFStore::Parser::SiRPAC::RDFMS_resource);
       	 	$newElement->{sResource} = makeAbsolute($expat,$sResource)
			if ($sResource);

        	my $sAboutEach = getAttributeValue($expat,$newElement->{attlist},
				$RDFStore::Parser::SiRPAC::RDFMS_aboutEach);
                $sAboutEach = "" if not defined $sAboutEach;
        	$newElement->{sAboutEach} = $sAboutEach
			if ($sAboutEach =~ /^#/);

        	my $sAbout = getAttributeValue($expat,$newElement->{attlist},
				$RDFStore::Parser::SiRPAC::RDFMS_about);
                $sAbout = "" if not defined $sAbout;
        	if($sAbout) {
        		$newElement->{sAbout} = makeAbsolute($expat,$sAbout);
        	};

        	my $sBagID = getAttributeValue($expat,$newElement->{attlist},
				$RDFStore::Parser::SiRPAC::RDFMS_bagID);

                $sBagID = "" if not defined $sBagID;
        	if ($sBagID) {
        		$newElement->{sBagID} = makeAbsolute($expat,$sBagID);
			$sBagID = $newElement->{sBagID};
        	};

        	my $sID = getAttributeValue($expat,$newElement->{attlist},
				$RDFStore::Parser::SiRPAC::RDFMS_ID);
                $sID = "" if not defined $sID;
        	if ($sID) {
        		$newElement->{sID} = makeAbsolute($expat,$sID);
			$sID = $newElement->{sID};
        	};
		if($sAboutEach ne '') {
			#any idea how to support it? caching and backrefs??
			$expat->xpcroak("aboutEach is not supported on stream parsing ");
		};

		if( ($sID ne '') && ($sAbout ne '') ) {
			$expat->xpcroak("A description block cannot use both 'ID' and 'about' attributes - see <a href=\"http://www.w3.org/TR/REC-rdf-syntax/#idAboutAttr\">[6.5]</a>");
		};

		# Check parseType
		$sLiteralValue = getAttributeValue($expat,$newElement->{attlist},
				$RDFStore::Parser::SiRPAC::RDFMS_parseType);

		if ( (defined $sLiteralValue) && ($sLiteralValue ne 'Resource') ) {
			# This is the management of the element where
                	# parseType="Literal" appears
                	#
                	# You should notice RDF V1.0 conforming implementations
                	# must treat other values than Literal and Resource as
                	# Literal. This is why the condition is !equals("Resource")

			if(scalar(@{$expat->{SiRPAC}->{elementStack}})>0) {
				my $e = $expat->{SiRPAC}->{elementStack}->[$#{$expat->{SiRPAC}->{elementStack}}];
				push @{$e->{children}},$newElement;
			};
        		# Place the new element into the stack
			push @{$expat->{SiRPAC}->{elementStack}},$newElement;
			push @{$expat->{SiRPAC}->{parseElementStack}},$newElement;
			$expat->{SiRPAC}->{sLiteral} = '';

                	return;
		};
		if($parseLiteral) {
                	# This is the management of any element nested within
                	# a parseType="Literal" declaration

			#Trigger 'Start_XML_Literal' event
			my $start_literal = $expat->{SiRPAC}->{parser}->{Handlers}->{Start_XML_Literal}
				if(ref($expat->{SiRPAC}->{parser}->{Handlers}) =~ /HASH/);
			$expat->{SiRPAC}->{sLiteral} .= &$start_literal($expat,$xml_tag,@attlist)
				if(defined $start_literal);
			push @{$expat->{SiRPAC}->{elementStack}},$newElement;
			return;
        	};
        };

	# Update the containment hierarchy with the stack
	# Prevent hooking up of 1st level descriptions to the root element
	if (	(scalar(@{$expat->{SiRPAC}->{elementStack}})>0) &&
		(!$setScanModeElement) ) {
		my $e = $expat->{SiRPAC}->{elementStack}->[$#{$expat->{SiRPAC}->{elementStack}}];
		push @{$e->{children}},$newElement;
	};

        # Place the new element into the stack
	push @{$expat->{SiRPAC}->{elementStack}},$newElement;

	if ( (defined $sLiteralValue) && ($sLiteralValue eq 'Resource') ) {
		push @{$expat->{SiRPAC}->{parseElementStack}},$newElement;
		$expat->{SiRPAC}->{sLiteral} = '';

                # Since parseType="Resource" implies the following
                # production must match Description, let's create
                # an additional Description node here in the document tree.
                my $desc = RDFStore::Parser::SiRPAC::Element->new(undef,$RDFStore::Parser::SiRPAC::RDFMS_Description,
								\@attlist);

		if(scalar(@{$expat->{SiRPAC}->{elementStack}})>0) {
                	my $e = $expat->{SiRPAC}->{elementStack}->[$#{$expat->{SiRPAC}->{elementStack}}];
                	push @{$e->{children}},$desc;
        	};
		push @{$expat->{SiRPAC}->{elementStack}},$desc;
	};
};

sub RDFXML_EndElementHandler {
	my $expat = shift;
	my $tag = shift;

    	my $bParseLiteral = parseLiteral($expat);
    	$expat->{SiRPAC}->{root} = pop @{$expat->{SiRPAC}->{elementStack}};

	return
		if($expat->{SiRPAC}->{scanMode} eq 'SKIPPING');

	if ($bParseLiteral) {
                my $pe = $expat->{SiRPAC}->{parseElementStack}->[$#{$expat->{SiRPAC}->{parseElementStack}}];
		if($pe != $expat->{SiRPAC}->{root}) {
			#Trigger 'Stop_XML_Literal' event
			my $stop_literal = $expat->{SiRPAC}->{parser}->{Handlers}->{Stop_XML_Literal}
				if(ref($expat->{SiRPAC}->{parser}->{Handlers}) =~ /HASH/);
			$expat->{SiRPAC}->{sLiteral} .= &$stop_literal($expat,$tag)
				if(defined $stop_literal);
		} else {
			# we would want resource because parseType="Literal" is text/xml (see RFC 2397)
			push @{$expat->{SiRPAC}->{root}->{children}},RDFStore::Parser::SiRPAC::DataElement->new($expat->{SiRPAC}->{sLiteral});
                	pop @{$expat->{SiRPAC}->{parseElementStack}};
		};
	} elsif(parseResource($expat)) {
		# If we are doing parseType="Resource"
         	# we need to explore whether the next element in
         	# the stack is the closing element in which case
         	# we remove it as well (remember, there's an
         	# extra Description element to be removed)
		if(scalar(@{$expat->{SiRPAC}->{elementStack}})>0) {
                	my $pe = $expat->{SiRPAC}->{parseElementStack}->[$#{$expat->{SiRPAC}->{parseElementStack}}];
                	my $e = $expat->{SiRPAC}->{elementStack}->[$#{$expat->{SiRPAC}->{elementStack}}];
            		if ($pe == $e) {
                		$e = pop @{$expat->{SiRPAC}->{elementStack}};
                		pop @{$expat->{SiRPAC}->{parseElementStack}};
            		};
		};
	};

	if($expat->{SiRPAC}->{scanMode} eq 'RDF') {
		$expat->{SiRPAC}->{scanMode} = 'SKIPPING';
		return;
	};

	# we are deep inside - I do not understand this by AR
	return
		if($expat->{SiRPAC}->{EXPECT_Element} != $expat->{SiRPAC}->{root});

	if($expat->{SiRPAC}->{scanMode} eq 'TOP_DESCRIPTION') {
		processXML($expat,$expat->{SiRPAC}->{EXPECT_Element});
		$expat->{SiRPAC}->{scanMode} = 'SKIPPING';
	} elsif($expat->{SiRPAC}->{scanMode} eq 'DESCRIPTION') {
		processXML($expat,$expat->{SiRPAC}->{EXPECT_Element});
		$expat->{SiRPAC}->{scanMode} = 'RDF';
	};
};

sub RDFXML_CharacterDataHandler {
	my $expat = shift;
	my $text = shift;
   
	if(parseLiteral($expat)) {
		#Trigger 'Char_Literal' event
		my $char_literal = $expat->{SiRPAC}->{parser}->{Handlers}->{Char_Literal}
			if(ref($expat->{SiRPAC}->{parser}->{Handlers}) =~ /HASH/);
		$expat->{SiRPAC}->{sLiteral} .= &$char_literal($expat,$text)
			if(defined $char_literal);

        	return;
    	};

     	# Place all characters as Data instance to the containment
     	# hierarchy with the help of the stack.
    	my $e = $expat->{SiRPAC}->{elementStack}->[$#{$expat->{SiRPAC}->{elementStack}}];

	# Determine whether the previous event was for
	# characters. If so, update the Data node contents.
	# A&amp;B would otherwise result in three
	# separate Data nodes in the parse tree
	my $bHasData = 0;
	my $dN;
	my $dataNode;
	foreach $dN (@{$e->{children}}) {
		if($dN->isa('RDFStore::Parser::SiRPAC::DataElement')) {
			$bHasData = 1;
			$dataNode=$dN;
			last;
		};
      	};

     	# Warning: this is not correct procedure according to XML spec.
	# All whitespace matters!

	# trim text
	my $trimtext = $text;
	$trimtext =~ s/^([\s])+//g;
	$trimtext =~ s/([\s])+$//g;

	# FIXME? it seems not really correct $preserveWhiteSpace
	my $preserveWhiteSpace;
	my $size = scalar(@{$expat->{SiRPAC}->{elementStack}});
	if ($size>0) {	
		my $e = $expat->{SiRPAC}->{elementStack}->[$size-1];
    		my $sParseType = getAttributeValue($expat, $e->{attlist},$RDFStore::Parser::SiRPAC::XML_space);
		if( (defined $sParseType) && ($sParseType ne '') ){
			$preserveWhiteSpace=($RDFStore::Parser::SiRPAC::XML_space_preserve eq $sParseType)
		} else {
			$preserveWhiteSpace=0;
		};
	} else {
		$preserveWhiteSpace=0;
	};
	if( (length($trimtext)>0) || ($preserveWhiteSpace) ) {
		if(!$bHasData) {
        		push @{$e->{children}},RDFStore::Parser::SiRPAC::DataElement->new($text);
		} else {
        		$dataNode->{sContent} .= $text;
			#not nice to see it here.....I know ;-)
			$dataNode->{tag} = "[DATA: " . $dataNode->{sContent} . "]";
		};
	};
};

sub processXML {
	my ($expat,$ele) = @_;

	if($ele->name() eq $RDFStore::Parser::SiRPAC::RDFMS_RDF) {
		my $c;
		foreach $c (@{$ele->{children}}) {
			if($c->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Description) {
				processDescription($expat,$c,0,
					$expat->{SiRPAC}->{bCreateBags}, $expat->{SiRPAC}->{bCreateBags});
			} elsif( 	($c->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Seq) ||
					($c->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Alt) ||
					($c->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Bag)	)  {
				processContainer($expat,$c);
			#strange checking here....
			} elsif( 	(!($c->name() eq $RDFStore::Parser::SiRPAC::RDFMS_resource)) && 
					(length($c->name())>0) ) {
				processTypedNode($expat,$c);
			};
		};
	} elsif($ele->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Description) {
		processDescription($expat,$ele,0,
				$expat->{SiRPAC}->{bCreateBags}, $expat->{SiRPAC}->{bCreateBags});
	} else {
		processTypedNode($expat,$ele);
	};

	# Recursively call myself to go through all the schemas
	#....even more similar to the PEN one ;-)
	if ($expat->{SiRPAC}->{bFetchSchemas}) {
		my $sURI;
		while($sURI=shift @{$expat->{SiRPAC}->{vNStodo}}) {
			push @{$expat->{SiRPAC}->{vNSdone}},$sURI;

			# Merge all the schemas :-)
			#
			# There is a problem that the same XML::Parser::Expat instace can not
			# parse different XML chuncks :-( 
			# ...but we need to merge the triples somehow....
			#
			# Run Expat
        		my $third;
			if($expat->isa("XML::Parser::ExpatNB")) {
        			$third = new XML::Parser::ExpatNB(@{$expat->{parser_parameters}});
				$third->{_State_} = 1;
			} else {
        			$third = new XML::Parser::Expat(@{$expat->{parser_parameters}});
			};

			# a bit tricky here....but should work ;-)
        		$third->{SiRPAC} = $expat->{SiRPAC};

			if(defined $sURI) {
				if( (ref($sURI)) && ($sURI->isa("URI")) ) {
					$third->{SiRPAC}->{parser}->{Source}=$sURI;
				} elsif(-e $sURI) {
					$third->{SiRPAC}->{parser}->{Source}=URI->new('file:'.$sURI);
				} else {
					$third->{SiRPAC}->{parser}->{Source}=new URI; #unknown
				};
			} elsif(	(exists $third->{SiRPAC}->{parser}->{Source}) && 
					(defined $third->{SiRPAC}->{parser}->{Source}) &&
					( (!(ref($third->{SiRPAC}->{parser}->{Source}))) || (!($third->{SiRPAC}->{parser}->{Source}->isa("URI"))) )	) {
				if(-e $third->{SiRPAC}->{parser}->{Source}) {
					$third->{SiRPAC}->{parser}->{Source}=URI->new('file:'.$third->{SiRPAC}->{parser}->{Source});
				} else {
					$third->{SiRPAC}->{parser}->{Source}=new URI; #unknown
				};
			};
			if(defined $third->{SiRPAC}->{parser}->{Source}) {
  				$third->{SiRPAC}->{sSource}= setSource(
					(	(ref($third->{SiRPAC}->{parser}->{Source})) &&
						($third->{SiRPAC}->{parser}->{Source}->isa("URI")) ) ? 
						$third->{SiRPAC}->{parser}->{Source}->as_string :
						$third->{SiRPAC}->{parser}->{Source} );
				$third->base($third->{SiRPAC}->{sSource});
			};

        		$third->setHandlers(    Start => \&RDFXML_StartElementHandler,
                        	        	End => \&RDFXML_EndElementHandler,
                               			Char => \&RDFXML_CharacterDataHandler );

			my $ret;
			my $file_uri;
			my $scheme;
			$scheme='file:'
				if( (-e $sURI) || (!($sURI =~ /^\w+:/)) );
                	$file_uri= URI->new($scheme.$sURI);
			if (	(defined $file_uri) && (defined $file_uri->scheme)	&&
				($file_uri->scheme ne 'file') ) {
    				my $uri = new URI($sURI);
  				my $wget_handle = $third->wget($uri);
				if(defined $wget_handle) {
					if($third->isa("XML::Parser::ExpatNB")) {
						eval {
							my $thirdnb = $third->parse(@{$expat->{parser_parameters}});
							while(<$wget_handle>) {
								$thirdnb->parse_more($_,@{$expat->{parser_parameters}});
							};
							$thirdnb->parse_done;
						};
					} else {
						eval {
							$ret = $third->parse($wget_handle,@{$expat->{parser_parameters}});
    						};
					};
    					my $err = $@;
					if($err) {
						$third->release;
    						croak $err;
					};
                        	} else {
					warn "Cannot fetch '$uri'";
				};
    			} else {
				my $filename= $file_uri->file;

				# FIXME: it might be wrong in some cases
				local(*FILE);
				open(FILE, $filename) 
					or  croak "Couldn't open $filename:\n$!";
				binmode(FILE);
				if($third->isa("XML::Parser::ExpatNB")) {
					eval {
						my $thirdnb = $third->parse(@{$expat->{parser_parameters}});
						while(<FILE>) {
							$thirdnb->parse_more($_,@{$expat->{parser_parameters}});
						};
						$thirdnb->parse_done;
					};
				} else {
					eval {
						$ret = $third->parse(*FILE,@{$expat->{parser_parameters}});
    					};
				};
    				my $err = $@;
    				close(FILE);
				if($err) {
					$third->release;
    					croak $err;
				};
			};

			# then trigger the nice thing ;-)
			# in the $first pass streaming the first trigger is on "Description"
			processXML($third->{SiRPAC}->{root});

			#if($expat->isa("XML::Parser::ExpatNB")) {
                	#	$third->{FinalHandler} = sub {
			#		$_[0]->release;
                	#	};
			#};
      		};
    	};
};

sub processDescription {
	my ($expat,$ele,$inPredicate,$reify,$createBag) = @_;

#print STDERR "processDescription($expat,$ele,$inPredicate,$reify,$createBag)",((caller)[2]),"\n";

	# Return immediately if the description has already been managed
	return $ele->{sID}
		if($ele->{bDone});

	my $iChildCount=1;
	my $bOnce=1;
	
	# Determine first all relevant values
	my ($sID,$sBagid,$sAbout,$sAboutEach) = (
									$ele->{sID},
									$ele->{sBagID},
									$ele->{sAbout},
									$ele->{sAboutEach} );
	my $target = (defined $ele->{vTargets}->[0]) ? $ele->{vTargets}->[0] : undef;

	my $targetIsContainer=0;
	my $sTargetAbout='';
	my $sTargetBagid='';
	my $sTargetID='';

	# Determine what the target of the Description reference is
	if (defined $target) {
      		my $sTargetAbout = $target->{sAbout};
      		my $sTargetID    = $target->{sID};
      		my $sTargetBagid = $target->{sBagID};

       		# Target is collection if
       		# 1. it is identified with bagID attribute
       		# 2. it is identified with ID attribute and is a collection
      		if ( ((defined $sTargetBagid) && ($sTargetBagid ne '')) && 
			((defined $sAbout) && ($sAbout ne '')) ) {
			# skip '#' sign??
        		$targetIsContainer = ($sAbout =~ /^.$sTargetBagid/);
      		} else {
        		if (	((defined $sTargetID) && ($sTargetID ne '')) &&
            			((defined $sAbout) && ($sAbout ne '')) &&
				($sAbout =~ /^.$sTargetID/) &&
				( 	($target->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Seq) ||
                                        ($target->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Alt) ||
                                        ($target->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Bag) )	)  {
          			$targetIsContainer = 1;
        		};
      		};
    	};

	# Check if there are properties encoded using the abbreviated syntax
	expandAttributes($expat,$ele,$ele,0);

	# Manage the aboutEach attribute here
	if( ((defined $sAboutEach) && ($sAboutEach ne '')) && (defined $target) ) {
      		if( 	($target->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Seq) ||
                        ($target->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Alt) ||
                        ($target->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Bag) ) {
			my $ele1;
			foreach $ele1 (@{$target->{children}}) {
          			if( 	($ele1->name() =~ /^$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS/) &&
					( ($ele1->localName() =~ /li$/) || ($ele1->localName() =~ /_/) ) ) {
            				my $sResource = $ele1->{sResource};
             				# Manage <li resource="..." /> case
            				if((defined $sResource) && ($sResource ne '')) {
              					my $newDescription =  RDFStore::Parser::SiRPAC::Element->new(undef,$RDFStore::Parser::SiRPAC::RDFMS_Description);
						$newDescription->{sAbout} = $sResource;
					
						my $ele2;
						foreach $ele2 (@{$ele->{children}}) {
							if (defined $newDescription) {
                  						push @{$newDescription->{children}},$ele2;
                					};
              					};
                				processDescription($expat,$newDescription,0,0,0)
							if (defined $newDescription);
            				} else {
               					# Otherwise we have a structured value inside <li>
              					# loop through the children of <li>
              					# (can be only one)
						my $ele2;
						foreach $ele2 (@{$ele1->{children}}) {
                					# loop through the items in the
                					# description with aboutEach
                					# and add them to the target
              						my $newNode =  RDFStore::Parser::SiRPAC::Element->new(undef,$RDFStore::Parser::SiRPAC::RDFMS_Description);
							my $ele3;
							foreach $ele3 (@{$ele->{children}}) {
								if (defined $newNode) {
                  							push @{$newNode->{children}},$ele3;
								};
              						};
                					push @{$newNode->{vTargets}},$ele2;

               						processDescription($expat,$newNode,1,0,0);
       						};
       					};
				} elsif( 	(!($ele1->name() eq $RDFStore::Parser::SiRPAC::RDFMS_resource)) &&
						(length($ele1->name())>0) ) {
              				my $newNode =  RDFStore::Parser::SiRPAC::Element->new(undef,$RDFStore::Parser::SiRPAC::RDFMS_Description);
					my $ele2;
					foreach $ele2 (@{$ele->{children}}) {
						if (defined $newNode) {
                  					push @{$newNode->{children}},$ele2;
						};
              				};
                			push @{$newNode->{vTargets}},$ele1;
                			processDescription($expat,$newNode,1,0,0);
          			};
        		};
		} elsif($target->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Description) {
                	processDescription($expat,$target,0,$reify,$createBag);
			my $ele1;
			foreach $ele1 (@{$target->{children}}) {
              			my $newNode =  RDFStore::Parser::SiRPAC::Element->new(undef,$RDFStore::Parser::SiRPAC::RDFMS_Description);
				my $ele2;
				foreach $ele2 (@{$ele->{children}}) {
					if (defined $newNode) {
                  				push @{$newNode->{children}},$ele2;
					};
              			};
                		push @{$newNode->{vTargets}},$ele1;
                		processDescription($expat,$newNode,1,0,0);
        		};
	 	};
      		return;
    	};

	# Enumerate through the children
	my $paCounter = 1;
	my $n;
	foreach $n (@{$ele->{children}}) {
		if($n->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Description) {
        		$expat->xpcroak("Cannot nest a Description inside another Description");
      		} elsif( 	($n->name() =~ /^$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS/) &&
				( ($n->localName() =~ /li$/) || ($n->localName() =~ /_/) ) &&
				(defined $sID) && ($sID ne '') ) {
        		processListItem($expat,$sID,$n,$paCounter);
        		$paCounter++;
      		} elsif( 	($n->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Seq) ||
                                ($n->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Alt) ||
                                ($n->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Bag) ) {
        		$expat->xpcroak("Cannot nest a container (Bag/Alt/Seq) inside a Description");
      		} elsif( 	(!($n->name() eq $RDFStore::Parser::SiRPAC::RDFMS_resource)) && 
				(length($n->name())>0) ) {
        		my $sChildID;
			if ( (defined $target) && ($targetIsContainer) ) {
          			$sChildID = processPredicate($expat,$n,$ele,
                                       ((defined $target->{sBagID}) ? $target->{sBagID} : $target->{sID}),0);
          			$ele->{sID} = makeAbsolute($expat,$sChildID);
				$createBag=0;
        		} elsif(defined $target) {
          			$sChildID = processPredicate($expat,$n,$ele,
                                       ((defined $target->{sBagID}) ? $target->{sBagID} : $target->{sID}),$reify);
          			$ele->{sID} = makeAbsolute($expat,$sChildID);
        		} elsif( (not(defined $target)) && (!($inPredicate)) ) {
				# added by AR 2001/07/19 accordingly to W3C RDF Core #rdfms-empty-property-elements issue
				# (see http://lists.w3.org/Archives/Public/w3c-rdfcore-wg/2001Jun/0134.html)
				my $pl = getAttributeValue($expat, $n->{attlist},$RDFStore::Parser::SiRPAC::RDFMS_parseType);
				$expat->xpcroak("Can not specify an rdf:parseType of 'Literal' and an rdf:resource attribute at the same time for predicate '".$n->name()."' - see http://lists.w3.org/Archives/Public/w3c-rdfcore-wg/2001Jun/0134.html")
					if(	(defined $pl) &&
						($pl eq 'Literal') &&
						(getAttributeValue($expat, $n->{attlist},$RDFStore::Parser::SiRPAC::RDFMS_resource)) );

          			$ele->{sID} = newReificationID($expat)
          				if(not(((defined $ele->{sID}) && ($ele->{sID} ne ''))));
          			if (not(((defined $sAbout) && ($sAbout ne '')))) {
            				if ((defined $sID) && ($sID ne '')) {
						$sAbout=$sID;
					} else {
						$sAbout=$ele->{sID};
					};
				};
          			$sChildID = processPredicate($expat,$n,$ele,
						$sAbout,
						( ((defined $sBagid) && ($sBagid ne '')) ? 1 : $reify));
        		} elsif( (not(defined $target)) && ($inPredicate) ) {
          			if (not(((defined $sAbout) && ($sAbout ne '')))) {
            				if ((defined $sID) && ($sID ne '')) {
          					$ele->{sID} = makeAbsolute($expat,$sID);
						$sAbout=$sID;
					} else {
          					$ele->{sID} = newReificationID($expat)
          						if(not(((defined $ele->{sID}) && ($ele->{sID} ne ''))));
						$sAbout=$ele->{sID};
					};
				} else {
          				$ele->{sID} = $sAbout;
				};
					
          			$sChildID = processPredicate($expat,$n,$ele,$sAbout,0);
        		};

                        # Each Description block creates also a Bag node which
                        # has links to all properties within the block IF
                        # the bCreateBags variable is true
        		if( ((defined $sBagid) && ($sBagid ne '')) || ($expat->{SiRPAC}->{bCreateBags} && $createBag) ) {
          			my $sNamespace = $RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS;
          			# do only once and only if there is a child
          			if( ($bOnce) && ((defined $sChildID) && ($sChildID ne '')) ) {
            				$bOnce = 0;
              				$ele->{sBagID} = newReificationID($expat)
            					if(not(((defined $ele->{sBagID}) && ($ele->{sBagID} ne ''))));
          				$ele->{sID} = makeAbsolute($expat,$ele->{sBagID})
          					if(not(((defined $ele->{sID}) && ($ele->{sID} ne ''))));

			            	addTriple(	$expat,
							$expat->{SiRPAC}->{nodeFactory}->createResource($sNamespace,'type'),
                       					$expat->{SiRPAC}->{nodeFactory}->createResource($ele->{sBagID}),
							$expat->{SiRPAC}->{nodeFactory}->createResource($sNamespace,'Bag')
						);
          			};
				if ((defined $sChildID) && ($sChildID ne '')) {
			            	addTriple(	$expat,
							$expat->{SiRPAC}->{nodeFactory}->createResource($sNamespace,"_".$iChildCount),
                       					$expat->{SiRPAC}->{nodeFactory}->createResource($ele->{sBagID}),
							$expat->{SiRPAC}->{nodeFactory}->createResource($sChildID)
						 );
            				$iChildCount++;
          			};
        		};
      		} else {
			# n is a propAttr
          		processPredicate($expat,$n,$ele,$sAbout,0);
		};
    	};

	$ele->{bDone} = 1;

	return $ele->{sID};
};

# we could use URI and XPath modules to validate and normalise the subject, predicate, object
# Use XPath/XPointer for literals could be cool to have one unique uri thing
sub addTriple {
	my ($expat,$predicate,$subject,$object) = @_;

#print STDERR "addTriple('".$predicate->toString."','".$subject->toString."','".$object->toString."')",((caller)[2]),"\n";

	# If there is no subject (about=""), then use the URI/filename where
	# the RDF description came from
	carp "Predicate null when subject=".$subject." and object=".$object
		unless(defined $predicate);

	carp "Subject null when predicate=".$predicate." and object=".$object
		unless(defined $subject);

	carp "Object null when predicate=".$predicate." and subject=".$subject
		unless(defined $object);

	$subject = $expat->{SiRPAC}->{nodeFactory}->createResource($expat->{SiRPAC}->{sSource})
		unless( (defined $subject) && ($subject->toString()) && (length($subject->toString())>0) );

	#Trigger 'Assert' event
        my $assert = $expat->{SiRPAC}->{parser}->{Handlers}->{Assert}
		if(ref($expat->{SiRPAC}->{parser}->{Handlers}) =~ /HASH/);
        if (defined($assert)) {
        	return &$assert($expat, 
				$expat->{SiRPAC}->{nodeFactory}->createStatement($subject,$predicate,$object) );
	} else {
		return;
	};
};

sub newReificationID {
	my ($expat) = @_;

#print STDERR "newReificationID($expat): ",((caller)[2]),"\n";

	$expat->{SiRPAC}->{iReificationCounter}++;

	my $reifStr;
	if( (defined $expat->{SiRPAC}->{sSource}) && ($expat->{SiRPAC}->{sSource} ne '') ) {
		$reifStr=makeAbsolute($expat,"genid".$expat->{SiRPAC}->{iReificationCounter});
	} else {
		$reifStr="#genid".$expat->{SiRPAC}->{iReificationCounter};
	};
	return $reifStr;
};

sub processTypedNode {
	my ($expat,$typedNode) = @_;

#print STDERR "processTypedNode($typedNode): ",((caller(1))[2]),"\n";

	my $sID = $typedNode->{sID};
	my $sBagID = $typedNode->{sBagID};
	my $sAbout = $typedNode->{sAbout};

	my $target = (defined $typedNode->{vTargets}->[0]) ? $typedNode->{vTargets}->[0] : undef;

    	my $sAboutEach = $typedNode->{sAboutEach};

	if ( (defined $typedNode->{sResource}) && ($typedNode->{sResource} ne '') ) {
      		$expat->xpcroak("'resource' attribute not allowed for a typedNode '".$typedNode->name()."' - see <a href=\"http://www.w3.org/TR/REC-rdf-syntax/#typedNode\">[6.13]</a>");
	};

	# We are going to manage this typedNode using the processDescription
	# routine later on. Before that, place all properties encoded as
	# attributes to separate child nodes.
	my $n;
	for($n=0; $n<=$#{$typedNode->{attlist}}; $n+=2) {
    		my $sAttribute = $typedNode->{attlist}->[$n]->[0].$typedNode->{attlist}->[$n]->[1];
    		my $sValue = getAttributeValue($expat, $typedNode->{attlist},$sAttribute);
		$sValue =~ s/^([ ])+//g;
		$sValue =~ s/([ ])+$//g;

		if ( 	(!($sAttribute =~ /^$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS/)) &&
			(!($sAttribute =~ m|^$RDFStore::Parser::SiRPAC::XMLSCHEMA|)) ) {
        		if(length($sValue) > 0) {
              			my $newPredicate =  RDFStore::Parser::SiRPAC::Element->new($typedNode->{attlist}->[$n]->[0],
							$typedNode->{attlist}->[$n]->[1],[
						[undef,$RDFStore::Parser::SiRPAC::RDFMS_ID], 
						(((defined $sAbout) && ($sAbout ne '')) ? $sAbout : $sID),
						[undef,$RDFStore::Parser::SiRPAC::RDFMS_bagID], 
						$sBagID
								]);
				
				my $newData =  RDFStore::Parser::SiRPAC::DataElement->new($sValue);
				push @{$newPredicate->{children}},$newData;
				push @{$typedNode->{children}},$newPredicate;

				# removeAttribute
				my @rr;
				my $i;
				for($i=0; $i<=$#{$typedNode->{attlist}}; $i+=2) {
					my $a = $typedNode->{attlist}->[$i]->[0].$typedNode->{attlist}->[$i]->[1];
					if($a eq $sAttribute) {
						next;
					} else {
						push @rr,$typedNode->{attlist}->[$i];
					};
				};
				$typedNode->{attlist} = \@rr;
        		};
      		};
    	};

	my $sObject;
    	if(defined $target) {
		$sObject = ( (((defined $target->{sBagID}) && ($target->{sBagID} ne ''))) ? $target->{sBagID} : $target->{sID});
	} elsif((defined $sAbout) && ($sAbout ne '')) {
      		$sObject = $sAbout;
    	} elsif((defined $sID) && ($sID ne '')) {
      		$sObject = $sID;
    	} else {
      		$sObject = newReificationID($expat);
	};

	$typedNode->{sID} = makeAbsolute($expat,$sObject);

	# special case: should the typedNode have aboutEach attribute,
	# the type predicate should distribute to pointed
	# collection also -> create a child node to the typedNode
	if ( 	((defined $sAboutEach) && ($sAboutEach ne '')) &&
        	(scalar(@{$typedNode->{vTargets}})>0) ) {
              		my $newPredicate =  RDFStore::Parser::SiRPAC::Element->new($RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'type');
			my $newData = RDFStore::Parser::SiRPAC::DataElement->new($typedNode->name());
			push @{$newPredicate->{children}},$newData;
			push @{$typedNode->{children}},$newPredicate;
    	} else {
      		addTriple(	$expat,
				$expat->{SiRPAC}->{nodeFactory}->createResource($RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'type'),
				$expat->{SiRPAC}->{nodeFactory}->createResource($typedNode->{sID}),
				$expat->{SiRPAC}->{nodeFactory}->createResource($typedNode->namespace,$typedNode->localName)
			);
    	};

    	my $sDesc = processDescription($expat,$typedNode, 0, $expat->{SiRPAC}->{bCreateBags}, 0);

    	return $sObject;
};

sub processContainer {
	my ($expat,$n) = @_;

#print STDERR "processContainer($n)",((caller)[2]),"\n";

	my $sID = $n->{sID};
      	$sID = $n->{sAbout}
    		unless((defined $sID) && ($sID ne ''));
      	$sID = newReificationID($expat)
    		unless((defined $sID) && ($sID ne ''));

     	# Do the instantiation only once
	if(!($n->{bDone})) {
      		if($n->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Seq) {
			addTriple(	$expat,
					$expat->{SiRPAC}->{nodeFactory}->createResource($RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'type'),
                       			$expat->{SiRPAC}->{nodeFactory}->createResource($sID),
					$expat->{SiRPAC}->{nodeFactory}->createResource($RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'Seq') 
				);
      		} elsif($n->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Alt) {
			addTriple(	$expat,
					$expat->{SiRPAC}->{nodeFactory}->createResource($RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'type'),
                       			$expat->{SiRPAC}->{nodeFactory}->createResource($sID),
					$expat->{SiRPAC}->{nodeFactory}->createResource($RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'Alt') 
				);
      		} elsif($n->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Bag) {
			addTriple(	$expat,
					$expat->{SiRPAC}->{nodeFactory}->createResource($RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'type'),
                       			$expat->{SiRPAC}->{nodeFactory}->createResource($sID),
					$expat->{SiRPAC}->{nodeFactory}->createResource($RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'Bag') 
				);
      		};
		$n->{bDone} = 1;
    	};

	expandAttributes($expat,$n,$n,0);

	if( 	(scalar(@{$n->{children}})<=0) &&
      		($n->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Alt) ) {
      		$expat->xpcroak("An RDF:Alt container must have at least one nested listitem");
    	};

	my $iCounter = 1;
	my $n2;
	foreach $n2 (@{$n->{children}}) {
		if (	($n2->name() =~ /^$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS/) &&
			( ($n2->localName() =~ /li$/) || ($n2->localName() =~ /_/) ) ) {
			processListItem($expat,$sID, $n2, $iCounter);
        		$iCounter++;
      		} else {
        		$expat->xpcroak("Cannot nest ".$n2->name()." inside a container (Bag/Alt/Seq)");
      		};
    	};
	return $sID;
};

sub processListItem {
	my ($expat,$sID,$listitem,$iCounter) = @_;

#print STDERR "processListItem($expat,$sID,".$listitem->{tag}.",$iCounter)",((caller)[2]),"\n";

	# added by AR 2001/07/20 accordingly to W3C RDF Core #rdf-containers-formalmodel issue
	# (see http://lists.w3.org/Archives/Public/w3c-rdfcore-wg/2001Jul/0039.html)
	$iCounter=$1
		if($listitem->localName() =~ m/_(\d+)$/);

	# Two different cases for
     	# 1. LI element without content (resource available)
     	# 2. LI element with content (resource unavailable)

	my $sResource = $listitem->{sResource};
    	if((defined $sResource) && ($sResource ne '')) {
		addTriple(	$expat,
				$expat->{SiRPAC}->{nodeFactory}->createResource($RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS."_".$iCounter),
                       		$expat->{SiRPAC}->{nodeFactory}->createResource($sID),
				$expat->{SiRPAC}->{nodeFactory}->createResource($sResource)
			 );
      		# validity checking
      		if (scalar(@{$listitem->{children}})>0) {
        		$expat->xpcroak("Listitem with 'resource' attribute cannot have child nodes - see <a href=\"http://www.w3.org/TR/REC-rdf-syntax/#referencedItem\">[6.29]</a>");
      		};
      		$listitem->{sID} = makeAbsolute($expat,$sResource);
    	} else {
		my $n;
		foreach $n (@{$listitem->{children}}) {
        		if($n->isa('RDFStore::Parser::SiRPAC::DataElement')) { #isData?
				addTriple(	$expat,
						$expat->{SiRPAC}->{nodeFactory}->createResource($RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS."_".$iCounter),
                       				$expat->{SiRPAC}->{nodeFactory}->createResource($sID),
						$expat->{SiRPAC}->{nodeFactory}->createLiteral($n->{sContent})
					 ); #here is Literal - how to handle it???
        		} elsif($n->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Description) {
          			my $sNodeID = processDescription($expat,$n, 0,1, 0);
				addTriple(	$expat,
						$expat->{SiRPAC}->{nodeFactory}->createResource($RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS."_".$iCounter),
                       				$expat->{SiRPAC}->{nodeFactory}->createResource($sID),
						$expat->{SiRPAC}->{nodeFactory}->createResource($sNodeID)
					) ;

				$listitem->{sID} = makeAbsolute($expat,$sNodeID);
        		} elsif (     ($n->name() =~ /^$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS/) &&
                                        ( ($n->localName() =~ /li$/) || ($n->localName() =~ /_/) ) ) {
        			$expat->xpcroak("Cannot nest a listitem inside another listitem");
        		} elsif( 	($n->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Seq) ||
                                	($n->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Alt) ||
                                	($n->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Bag) ) {
				processContainer($expat,$n);
				addTriple(	$expat,
						 $expat->{SiRPAC}->{nodeFactory}->createResource($RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS."_".$iCounter),
                       				$expat->{SiRPAC}->{nodeFactory}->createResource($sID),
						$expat->{SiRPAC}->{nodeFactory}->createResource($n->{sID})
					);
      			} elsif( 	(!($n->name() eq $RDFStore::Parser::SiRPAC::RDFMS_resource)) && 
					(length($n->name())>0) ) {
				my $sNodeID = processTypedNode($expat,$n);
				addTriple(	$expat,
						$expat->{SiRPAC}->{nodeFactory}->createResource($RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS."_".$iCounter),
                       				$expat->{SiRPAC}->{nodeFactory}->createResource($sID),
						$expat->{SiRPAC}->{nodeFactory}->createResource($sNodeID)
					);
        		};
      		};
	};
};

# processPredicate handles all elements not defined as special
# RDF elements. <tt>predicate</tt> has either <tt>resource()</tt> or a single child
sub processPredicate {
	my ($expat,$predicate,$description,$sTarget,$reify) = @_;

#print STDERR "processPredicate($predicate->{tag},$description->{tag},$sTarget,$reify)",((caller)[2]),"\n";

	my $sStatementID = $predicate->{sID};
	my $sBagID       = $predicate->{sBagID};
    	my $sResource    = $predicate->{sResource};

     	# If a predicate has other attributes than rdf:ID, rdf:bagID,
     	# or xmlns... -> generate new triples according to the spec.
     	# (See end of Section 6)

	# this new element may not be needed
        my $d = RDFStore::Parser::SiRPAC::Element->new(undef,$RDFStore::Parser::SiRPAC::RDFMS_Description);
    	if(expandAttributes($expat,$d,$predicate,1,$sResource)) {
      		# error checking
      		if(scalar(@{$predicate->{children}})>0) {
        		$expat->xpcroak($predicate->name()." must be an empty element since it uses propAttr grammar production - see <a href=\"http://www.w3.org/TR/REC-rdf-syntax/#propertyElt\">[6.12]</a>");
        		#cluck($predicate->name()." must be an empty element since it uses propAttr grammar production - see <a href=\"http://www.w3.org/TR/REC-rdf-syntax/#propertyElt\">[6.12]</a>");
        		return;
      		};

      		# determine the 'about' part for the new statements
      		if ((defined $sStatementID) && ($sStatementID ne '')) {
        		push @{$d->{attlist}},[undef,$RDFStore::Parser::SiRPAC::RDFMS_about];
        		push @{$d->{attlist}},$sStatementID;

                        # make rdf:ID the value of the predicate
			push @{$predicate->{children}}, RDFStore::Parser::SiRPAC::DataElement->new($sStatementID);
      		} elsif ((defined $sResource) && ($sResource ne '')) {
        		push @{$d->{attlist}},[undef,$RDFStore::Parser::SiRPAC::RDFMS_about];
        		push @{$d->{attlist}},$sResource;
      		} else {
			$sStatementID = newReificationID($expat);
        		push @{$d->{attlist}},[undef,$RDFStore::Parser::SiRPAC::RDFMS_about];
        		push @{$d->{attlist}},$sStatementID;
      		};

		if ((defined $sBagID) && ($sBagID ne '')) {
        		push @{$d->{attlist}},[undef,$RDFStore::Parser::SiRPAC::RDFMS_bagID];
        		push @{$d->{attlist}},$sBagID;
        		$d->{sBagID} = $sBagID;
      		};

          	processDescription($expat,$d, 0,0,$expat->{SiRPAC}->{bCreateBags});
    	};
	# Tricky part: if the resource attribute is present for a predicate
	# AND there are no children, the value of the predicate is either
	# 1. the URI in the resource attribute OR
	# 2. the node ID of the resolved #resource attribute
	my $predicate_target = (defined $predicate->{vTargets}->[0]) ? $predicate->{vTargets}->[0] : undef;
    	if( ((defined $sResource) && ($sResource ne '')) && (scalar(@{$predicate->{children}})<=0) ) {
      		if (not(defined $predicate_target)) {
        		if ($reify) {
          			$sStatementID = reify(	$expat,
							$expat->{SiRPAC}->{nodeFactory}->createResource($predicate->namespace,$predicate->localName),
							$expat->{SiRPAC}->{nodeFactory}->createResource($sTarget),
							$expat->{SiRPAC}->{nodeFactory}->createResource($sResource),
							$predicate->{sID});
				$predicate->{sID} = makeAbsolute($expat,$sStatementID);
        		} else {
				addTriple(	$expat,
                     				$expat->{SiRPAC}->{nodeFactory}->createResource($predicate->namespace,$predicate->localName),
                     				$expat->{SiRPAC}->{nodeFactory}->createResource($sTarget),
                     				$expat->{SiRPAC}->{nodeFactory}->createResource($sResource)
					 );
        		};
      		} else {
        		if ($reify) {
          			$sStatementID = reify(	$expat, 
							$expat->{SiRPAC}->{nodeFactory}->createResource($predicate->namespace,$predicate->localName),
							$expat->{SiRPAC}->{nodeFactory}->createResource($sTarget),
							$expat->{SiRPAC}->{nodeFactory}->createResource($predicate_target->{sID}),
							$predicate->{sID});
				$predicate->{sID} = makeAbsolute($expat,$sStatementID);
        		} else {
          			addTriple( 	$expat,
                     				$expat->{SiRPAC}->{nodeFactory}->createResource($predicate->namespace,$predicate->localName),
                     				$expat->{SiRPAC}->{nodeFactory}->createResource($sTarget),
                     				$expat->{SiRPAC}->{nodeFactory}->createResource($predicate_target->{sID})
					);
        		};
      		};
      		return $predicate->{sID};
    	};
                                    
	# Does this predicate make a reference somewhere using the <i>sResource</i> attribute
    	if ( ((defined $sResource) && ($sResource ne '')) && (defined $predicate_target) ) {
      		$sStatementID = processDescription ($expat,$predicate_target,1,0,0);
        	if ($reify) {
          		$sStatementID = reify(	$expat, 
						$expat->{SiRPAC}->{nodeFactory}->createResource($predicate->namespace,$predicate->localName),
						$expat->{SiRPAC}->{nodeFactory}->createResource($sTarget),
						$expat->{SiRPAC}->{nodeFactory}->createResource($sStatementID),
						$predicate->{sID});
			$predicate->{sID} = makeAbsolute($expat,$sStatementID);
        	} else {
          		addTriple( 	$expat,
                     			$expat->{SiRPAC}->{nodeFactory}->createResource($predicate->namespace,$predicate->localName),
                     			$expat->{SiRPAC}->{nodeFactory}->createResource($sTarget),
                     			$expat->{SiRPAC}->{nodeFactory}->createResource($sStatementID)
				 );
        	};
		return $sStatementID;
    	};

	# Before looping through the children, let's check
	# if there are any. If not, the value of the predicate is an anonymous node
	if (scalar(@{$predicate->{children}})<=0) {
		# updated by AR 2001/07/19 accordingly to W3C RDF Core #rdfms-empty-property-elements issue
		# (see http://lists.w3.org/Archives/Public/w3c-rdfcore-wg/2001Jun/0134.html)
		my $sObject = (	(exists $d->{sID}) && 
				(defined $d->{sID}) &&
				($d->{sID} ne '') ) ? 
				$expat->{SiRPAC}->{nodeFactory}->createResource($d->{sID}) : 
				$expat->{SiRPAC}->{nodeFactory}->createLiteral('');
        	if(	($reify) || 
			(	(defined $predicate->{sID}) &&
				($predicate->{sID} ne '') ) ) {
          		$sStatementID = reify(	$expat, 
						$expat->{SiRPAC}->{nodeFactory}->createResource($predicate->namespace,$predicate->localName),
						$expat->{SiRPAC}->{nodeFactory}->createResource($sTarget),
						# updated by AR 2001/07/19 accordingly to W3C RDF Core #rdfms-empty-property-elements issue
						# (see http://lists.w3.org/Archives/Public/w3c-rdfcore-wg/2001Jun/0134.html)
						$sObject,
						$predicate->{sID});
        	} else {
          		addTriple( 	$expat,
                     			$expat->{SiRPAC}->{nodeFactory}->createResource($predicate->namespace,$predicate->localName),
                     			$expat->{SiRPAC}->{nodeFactory}->createResource($sTarget),
					# updated by AR 2001/07/19 accordingly to W3C RDF Core #rdfms-empty-property-elements issue
					# (see http://lists.w3.org/Archives/Public/w3c-rdfcore-wg/2001Jun/0134.html)
					$sObject
				 );
		};
	};
	my $order = 0;
	my $n2;
	foreach $n2 (@{$predicate->{children}}) {
      		# FIXME: we are not requiring this for the sake of experiment
		# $expat->xpcroak("Only one node allowed inside a predicate (Extra node is ". $n2->name() .") - see <a href=\"http://www.w3.org/TR/REC-rdf-syntax/#propertyElt\">[6.12]</a>");

		if(	(defined $n2->name()) &&
			($n2->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Description) ) {
        		my $d2 = $n2;

			# updated by AR 2001/07/19 accordingly to W3C RDF Core #rdfms-empty-property-elements issue
			# (see http://lists.w3.org/Archives/Public/w3c-rdfcore-wg/2001Jun/0134.html)
			my $ss = processDescription ($expat,$d2, 1,0,0);
			if(	(defined $ss) &&
				($ss ne '') ) {
				$sStatementID = $ss;
			} else {
				$sStatementID = newReificationID($expat)
					unless(	(defined $sStatementID) &&
						($sStatementID ne '') );
			};

        		$d2->{sID} = makeAbsolute($expat,$sStatementID);
        		if(	($reify) || 
				# added by AR 2001/07/19 accordingly to W3C RDF Core #rdfms-empty-property-elements issue
				# (see http://lists.w3.org/Archives/Public/w3c-rdfcore-wg/2001Jun/0134.html)
				(	(defined $predicate->{sID}) &&
					($predicate->{sID} ne '') ) ) {
          			$sStatementID = reify(	$expat, 
						$expat->{SiRPAC}->{nodeFactory}->createResource($predicate->namespace,$predicate->localName),
						$expat->{SiRPAC}->{nodeFactory}->createResource($sTarget),
						$expat->{SiRPAC}->{nodeFactory}->createResource($sStatementID),
						$predicate->{sID});
        		} else {
          			addTriple( 	$expat,
                     				$expat->{SiRPAC}->{nodeFactory}->createResource($predicate->namespace,$predicate->localName),
                     				$expat->{SiRPAC}->{nodeFactory}->createResource($sTarget),
                     				$expat->{SiRPAC}->{nodeFactory}->createResource($sStatementID)
					 );
        		};
      		} elsif ($n2->isa('RDFStore::Parser::SiRPAC::DataElement')) {
			# We've got real data
        		my $sValue = $n2->{sContent};

			# If this predicate has an rdf:resource propAttr defined,
			# it should be the target [subject] of the triple
           		$sTarget = $predicate->{sResource}
				if (	(exists $predicate->{sResource}) &&
					(defined $predicate->{sResource}) &&
					($predicate->{sResource} ne '') );

                        # Only if the content is not empty PCDATA (whitespace that is), print the triple
			# NOTE: If predicate has an ID, the spec says it should be reified.
        		if(	($reify) ||
				(	(exists $predicate->{sID}) &&
					(defined $predicate->{sID}) &&
					($predicate->{sID} ne '') ) ) {
          			$sStatementID = reify(	$expat, 
						$expat->{SiRPAC}->{nodeFactory}->createResource($predicate->namespace,$predicate->localName),
						$expat->{SiRPAC}->{nodeFactory}->createResource($sTarget),
						$expat->{SiRPAC}->{nodeFactory}->createLiteral($sValue),
						$predicate->{sID}); #ignore isXML
				$predicate->{sID} = makeAbsolute($expat,$sStatementID);
        		} else {
          			addTriple ( 	$expat,
                     				$expat->{SiRPAC}->{nodeFactory}->createResource($predicate->namespace,$predicate->localName),
                     				$expat->{SiRPAC}->{nodeFactory}->createResource($sTarget),
						$expat->{SiRPAC}->{nodeFactory}->createLiteral($sValue)
						); #ignore isXML
        		};
      		} elsif( 	($n2->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Seq) ||
                            	($n2->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Alt) ||
                                ($n2->name() eq $RDFStore::Parser::SiRPAC::RDFMS_Bag) ) {

			my $sCollectionID = processContainer($expat,$n2);
        		$sStatementID = $sCollectionID;

			# Attach the collection to the current predicate
			my $description_target = (defined $description->{vTargets}->[0]) ? $description->{vTargets}->[0] : undef;
        		if (defined $description_target) {
        			if ($reify) {
          				$sStatementID = reify(	$expat, 
						$expat->{SiRPAC}->{nodeFactory}->createResource($predicate->namespace,$predicate->localName),
						$expat->{SiRPAC}->{nodeFactory}->createResource($description_target->{sAbout}),
						$expat->{SiRPAC}->{nodeFactory}->createResource($sCollectionID),
						$predicate->{sID});
					$predicate->{sID} = makeAbsolute($expat,$sStatementID);
        			} else {
					addTriple(	$expat,
							$expat->{SiRPAC}->{nodeFactory}->createResource($predicate->namespace,$predicate->localName),
							$expat->{SiRPAC}->{nodeFactory}->createResource($description_target->{sAbout}),
							$expat->{SiRPAC}->{nodeFactory}->createResource($sCollectionID)
						 );
        			};
        		} else {
        			if ($reify) {
          				$sStatementID = reify(	$expat, 
						$expat->{SiRPAC}->{nodeFactory}->createResource($predicate->namespace,$predicate->localName),
						$expat->{SiRPAC}->{nodeFactory}->createResource($sTarget),
						$expat->{SiRPAC}->{nodeFactory}->createResource($sCollectionID),
						$predicate->{sID});
					$predicate->{sID} = makeAbsolute($expat,$sStatementID);
        			} else {
					addTriple(	$expat,
							$expat->{SiRPAC}->{nodeFactory}->createResource($predicate->namespace,$predicate->localName),
							$expat->{SiRPAC}->{nodeFactory}->createResource($sTarget),
							$expat->{SiRPAC}->{nodeFactory}->createResource($sCollectionID)
						 );
        			};
        		};
      		} elsif( 	(!($n2->name() eq $RDFStore::Parser::SiRPAC::RDFMS_resource)) && 
				(length($n2->name())>0) ) {
        		$sStatementID = processTypedNode($expat,$n2);
          		addTriple ( 	$expat,
                     			$expat->{SiRPAC}->{nodeFactory}->createResource($predicate->namespace,$predicate->localName),
                     			$expat->{SiRPAC}->{nodeFactory}->createResource($sTarget),
                     			$expat->{SiRPAC}->{nodeFactory}->createResource($sStatementID)
					 );
      		};
    	};
	return $sStatementID;
};

sub reify {
	my ($expat,$predicate,$subject,$object,$sNodeID) = @_;

	$sNodeID = newReificationID($expat)
    		if(not(((defined $sNodeID) && ($sNodeID ne ''))));

#print STDERR "reify('".$predicate->toString."','".$subject->toString."','".$object->toString."','$sNodeID')",((caller)[2]),"\n";

     	# The original statement must remain in the data model
    	addTriple($expat,$predicate, $subject, $object);

	# Do not reify reifyd properties
    	if (	($predicate eq $RDFStore::Parser::SiRPAC::RDFMS_subject) ||
    		($predicate eq $RDFStore::Parser::SiRPAC::RDFMS_predicate) ||
    		($predicate eq $RDFStore::Parser::SiRPAC::RDFMS_object) ||
    		($predicate eq $RDFStore::Parser::SiRPAC::RDFMS_type) ) {
      		return;
    	};

	# Reify by creating 4 new triples
    	addTriple(	$expat,
			$expat->{SiRPAC}->{nodeFactory}->createResource($RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'predicate'),
			$expat->{SiRPAC}->{nodeFactory}->createResource($sNodeID),
			$predicate);

	$subject = (length($subject->toString()) == 0) ? $expat->{SiRPAC}->{sSource} : $subject->toString();
    	addTriple(	$expat,
			$expat->{SiRPAC}->{nodeFactory}->createResource($RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'subject'),
			$expat->{SiRPAC}->{nodeFactory}->createResource($sNodeID),	
			#bug fix by AR 2001/06/10
			$expat->{SiRPAC}->{nodeFactory}->createResource($subject)
			);

    	addTriple(	$expat,
			$expat->{SiRPAC}->{nodeFactory}->createResource($RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'object'),
			$expat->{SiRPAC}->{nodeFactory}->createResource($sNodeID),
			$object);

    	addTriple(	$expat,
			$expat->{SiRPAC}->{nodeFactory}->createResource($RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'type'),
			$expat->{SiRPAC}->{nodeFactory}->createResource($sNodeID),
			$expat->{SiRPAC}->{nodeFactory}->createResource($RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS,'Statement')
			);

	return $sNodeID;
};

# Take an element <i>ele</i> with its parent element <i>parent</i>
# and evaluate all its attributes to see if they are non-RDF specific
# and non-XML specific in which case they must become children of
# the <i>ele</i> node.
sub expandAttributes {
	my ($expat,$parent,$ele,$predicateNode,$resourceValue) = @_;

#print "expandAttributes($parent,$ele->name(),$predicateNode)",((caller)[2]),"\n";

	my $foundAbbreviation = 0;
	my $resourceFound = 0;
	
  	my $count=0;
	while ($count<=$#{$ele->{attlist}}) {
    		my $sAttribute = $ele->{attlist}->[$count++]->[0].$ele->{attlist}->[$count-1]->[1];
    		my $sValue = getAttributeValue($expat, $ele->{attlist},$sAttribute);
		$count++;
      		if ($sAttribute =~ m|^$RDFStore::Parser::SiRPAC::XMLSCHEMA|) {
        		# expands after parsing, that's why it is useless here... :(
           		# because of concatenation without : inbetween
			# ...there was something more here to do....
        		next;
      		};

      		# exception: expand rdf:value
      		if (	($sAttribute =~ /^$RDFStore::Parser::SiRPAC::RDF_SYNTAX_NS/) &&
          		(!($ele->{attlist}->[$count-2]->[1]=~ /^_/)) && #this might be buggy by AR 2001/05/28
          		(!($ele->{attlist}->[$count-2]->[1] =~ /value$/)) &&
          		(!($ele->{attlist}->[$count-2]->[1] =~ /type$/)) ) {

			# If an attribute (e.g. a property that follows the
			# propAttr production) is not qualified but its enclosing
			# (parent) element is from the RDFMS namespace, then the
			# attribute was prefaced with RDFMS in RDFXML_StartElementHandler().
			# This must be handled here so that the propAttr is added to the Model.
        		if(	($ele->{attlist}->[$count-2]->[1] =~ /resource$/) && 
				($predicateNode) ) {
          			$resourceFound = 1;
          			next;
        		};
 
			next
				if(	($ele->{attlist}->[$count-2]->[1] =~ /ID$/) ||
            				($ele->{attlist}->[$count-2]->[1] =~ /bagID$/) ||
            				($ele->{attlist}->[$count-2]->[1] =~ /about$/) ||
            				($ele->{attlist}->[$count-2]->[1] =~ /aboutEach$/) ||
            				($ele->{attlist}->[$count-2]->[1] =~ /parseType$/) );
		};
		
      		# expanding predicate element
      		#if( 	($predicateNode) &&
		#	(!($sAttribute eq $RDFStore::Parser::SiRPAC::RDFMS_resource)) ) {
		#	$expat->xpcroak("Property element ". $ele->name()." has invalid attribute ".$sAttribute.". Only rdf:resource is allowed.");
		#};

      		$foundAbbreviation = 1;
		my $newElement =  RDFStore::Parser::SiRPAC::Element->new($ele->{attlist}->[$count-2]->[0],$ele->{attlist}->[$count-2]->[1]);
		my $newData =  RDFStore::Parser::SiRPAC::DataElement->new($sValue);
        	push @{$newElement->{children}},$newData;
        	push @{$parent->{children}},$newElement;
	};

	# If an rdf:resource propAttr was found in this predicate then
	# cache its value in each of the predicate's elements.  The value
	# of the this propAttr will be the subject of all of the propAttr's triples
    	if(	($resourceFound) && (defined $resourceValue) ) {
		my $i=0;
        	foreach $i (0..$#{$parent->{children}}) {
        		$parent->{children}->[$i]->{sResource}= $resourceValue;
        	}; 
	};

#print STDERR "----".$ele->{tag}."\n";
#map {
#if(ref($_)) {
#	print STDERR $_->[0],$_->[1],"=";
#} else {
#	print STDERR $_,"\n";
#};
#} @{$ele->{attlist}};

	return $foundAbbreviation;
};

sub parseLiteral {
	my ($expat) = @_;

#print STDERR "parseLiteral(): ".(caller)[2]."\n";

	foreach(reverse @{$expat->{SiRPAC}->{elementStack}}) {	
		my $sParseType = getAttributeValue(	$expat,
							$_->{attlist},
							$RDFStore::Parser::SiRPAC::RDFMS_parseType );
		if( (defined $sParseType) && ($sParseType ne "Resource") ) {
			return 1;
    		};
	};
    	return 0;       
};

sub parseResource {
	my ($expat) = @_;

#print STDERR "parseResource($expat)",((caller)[2]),"\n";

	foreach(reverse @{$expat->{SiRPAC}->{elementStack}}) {	
		my $sParseType = getAttributeValue(	$expat,
							$_->{attlist},
							$RDFStore::Parser::SiRPAC::RDFMS_parseType );
		if( (defined $sParseType) && ($sParseType eq "Resource") ) {
			return 1;
    		};
	};
    	return 0;       
};

sub makeAbsolute {
	my ($expat,$sURI) = @_;

#print STDERR "makeAbsolute(['",$expat->{SiRPAC}->{sSource},"'],'$sURI')\n";
	
	my $URL = URI->new($sURI);
        if(defined $URL->scheme) {
                # If sURI is an absolute URI, don't bother
                # with it
		#carp "'$sURI' is already an absolute URI\n";
		return $sURI;
	} elsif(	(defined $sURI) && 
			(	(defined $expat->{SiRPAC}->{sSource}) &&
				($expat->{SiRPAC}->{sSource} ne '') ) ) {
		my $base = URI->new_abs('',$expat->{SiRPAC}->{sSource});
    		my $absoluteURL;
		my $special='';
		if($base->scheme ne 'file') {
			$sURI =~ s/^#//g
				if($base =~ /#$/);
			
			$sURI = uri_escape($sURI);
    			$absoluteURL = URI->new_abs('',$base.$sURI);
		} else {
    			$absoluteURL = $base;
			$special = $sURI;
			$special =~ s/^#//g
				if($base =~ /#$/);
			
			$special = uri_escape($special);
		};
		if(defined $absoluteURL->scheme) {
			return $absoluteURL->as_string.$special;
		} elsif(defined $absoluteURL) {
			return $absoluteURL;
		} else {
			carp "RDF Resource - cannot combine ", $expat->{SiRPAC}->{sSource},
				" with ", $sURI;
	    	};
        } else {
		$sURI = '#'.$sURI
			unless($sURI =~ /^#/);
		return $sURI;
	};
};

package RDFStore::Parser::SiRPAC::Element;
{
	sub new {
		my ($pkg, $namespace, $tag, $attlist) = @_;

		$attlist = []
			unless(defined $attlist);

#print STDERR "RDFStore::Parser::SiRPAC::Element::new(): ".(caller)[2]."\n";

		my $self =  {
				tag		=>	$tag,
				sNamespace	=>	$namespace,
				attlist		=>	$attlist,
				sResource	=>	'',
				sAbout		=>	'',
				sAboutEach	=>	'',
				children	=>	[],
				vTargets	=>	[],
				bDone		=>	0,
				sID		=>	'',
				sBagID		=>	'',
				sPrefix		=>	''
			};
		bless $self,$pkg;
	};

	sub name {
		return (defined $_[0]->{sNamespace}) ?
				$_[0]->{sNamespace}.$_[0]->{tag} :
				$_[0]->{tag};
	};

	sub localName {
		return $_[0]->{tag};
	};

	sub namespace {
		return $_[0]->{sNamespace};
	};
};

package RDFStore::Parser::SiRPAC::DataElement;
{
	@RDFStore::Parser::SiRPAC::DataElement::ISA = qw( RDFStore::Parser::SiRPAC::Element );
	sub new {
		my ($pkg, $text, $attlist) = @_;
		my $self = $pkg->SUPER::new(undef,$text, $attlist);

		delete $self->{sNamespace}; # we do not need it

		$self->{tag} = "[DATA: " . $text . "]";
		$self->{sContent} = $text; #instanceOf Data :-)
		bless $self,$pkg;
	};

	sub name { };
	sub localName { };
	sub namespace { };
};

1;
};

__END__

=head1 NAME

RDFStore::Parser::SiRPAC - This module implements a streaming RDF Parser as a direct implementation of XML::Parser::Expat(3)

=head1 SYNOPSIS

	use RDFStore::Parser::SiRPAC;
        use RDFStore::NodeFactory;
        my $p=new RDFStore::Parser::SiRPAC(
		ErrorContext => 2,
                Handlers        => {
                        Init    => sub { print "INIT\n"; },
                        Final   => sub { print "FINAL\n"; },
                        Assert  => sub { print "STATEMENT - @_\n"; }
                },
                NodeFactory     => new RDFStore::NodeFactory() );

	$p->parsefile('http://www.gils.net/bsr-gils.rdfs');
        $p->parsefile('http://www.gils.net/rdf/bsr-gils.rdfs');
        $p->parsefile('/some/where/my.rdf');
        $p->parsefile('file:/some/where/my.rdf');
	$p->parse(*STDIN);

	use RDFStore;
	my $pstore=new RDFStore::Parser::SiRPAC(
                ErrorContext 	=> 2,
                Style 		=> 'RDFStore::Parser::Styles::MagicTie',
                NodeFactory     => new RDFStore::NodeFactory(),
                Source  	=> 'http://www.gils.net/bsr-gils.rdfs',
                store   =>      {
                                	persistent      =>      1,
                                	directory       =>      '/tmp/',
                                	seevalues       =>      1,
                                	options         =>      { style => 'BerkeleyDB', Q => 20 }
                                }
        );
	$pstore->parsefile('http://www.gils.net/bsr-gils.rdfs');

	#using the Expat no-blocking feature
	my $nbpstore = $pstore->parse_start();
	while (<STDIN>) {
		$nbpstore->parse_more($_);
	};	
	$nbpstore->parse_done();
	

=head1 DESCRIPTION

This module implements a Resource Description Framework (RDF) I<streaming> parser completely in 
Perl using the XML::Parser::Expat(3) module. The actual RDF parsing happens using an instance of XML::Parser::Expat with Namespaces option enabled and start/stop and char handlers set.
The RDF specific code is based on the modified version of SiRPAC of Sergey Melnik in Java; a lot of
changes and adaptations have been done to actually run it under Perl.
Expat options may be provided when the RDFStore::Parser::SiRPAC object is created. These options are then passed on to the Expat object on each parse call.

Exactly like XML::Parser(3) the behavior of the parser is controlled either by the Style entry elsewhere in this document and/or the Handlers entry elsewhere in this document options, or by the setHandlers entry elsewhere in this document method. These all provide mechanisms for RDFStore::Parser::SiRPAC to set the handlers needed by Expat.  If neither Style nor Handlers are specified, then parsing just checks the RDF document syntax against the W3C RDF Raccomandation . When underlying handlers get called, they receive as their first parameter the Expat object, not the Parser object.

To see some examples about how to use it look at the sections below and in the samples and utils directory coming with this software distribution.

E.g.
	With RDFStore::Parser::SiRPAC you can easily write an rdfingest.pl script to do something like this:

	fetch -o - -q http://dmoz.org/rdf/content.rdf.u8.gz | \
		gunzip - | \
		sed -f dmoz.content.sed | rdfingest.pl - 

=head1 METHODS

=over 4

=item new

This is a class method, the constructor for RDFStore::Parser::SiRPAC. B<Options> are passed as keyword value
pairs. Recognized options are:

=over 4

=item * NodeFactory

This option is B<mandatory> to run the RDFStore::Parser::SiRPAC parser correctly and must contain a reference to an object of type RDFStore::Stanford::NodeFactory(3). Such a reference is used during the RDF parsing to create resources, literal and statements to be passed to the registered handlers. A sample implementation is RDFStore::NodeFactory that is provided
with the RDFStore package.

=item * Source

This option can be specified by the user to set a base URI to use for the generation of resource URIs during parsing. If this option is omitted the parser will try to generate a prefix for generated resources using the input filename or URL actually containing the input RDF. In a near future such an option could be obsoleted by use of XMLBase W3C raccomandation.

=item * RDFCore_Issues

Flag whether or not warn the user about syntax errors in the source RDF syntax accordingly to decisions taken by the RDF Core Working Group (see http://www.w3.org/2000/03/rdf-tracking/#attention-developers)

=item * GenidNumber

Seed the genid numbers with the given value

=item * bCreateBags

Flag to generate a Bag for each Description element

=item * Style

This option provides an easy way to set a given style of parser. There is one sample Sylte module
provided with the RDFStore::Parser::SiRPAC distribution called RDFStore::Parser::SiRPAC::RDFStore. Such
a module uses the RDFStore(3) modules together with the Data::MagicTie(3) to implement a simple
RDF storage.
Custom styles can be provided by giving a full package name containing
at least one '::'. This package should then have subs defined for each
handler it wishes to have installed. See L<"WRITE YOUR OWN PARSER"> below
for a discussion on how to build one.

=item * Handlers

When provided, this option should be an anonymous hash containing as
keys the type of handler and as values a sub reference to handle that
type of event. All the handlers get passed as their 1st parameter the
instance of Expat that is parsing the document. Further details on
handlers can be found in L<"HANDLERS">. Any handler set here
overrides the corresponding handler set with the Style option.

=item * ErrorContext

This is an XML::Parser option. When this option is defined, errors are reported
in context. The value should be the number of lines to show on either side
of the line in which the error occurred.

=back

All the other XML::Parser and XML::Parser::Expat options should work freely with RDFStore::Parser::SiRPAC see XML::Parser(3) and XML::Parser::Expat(3).

=item  setHandlers(TYPE, HANDLER [, TYPE, HANDLER [...]])

This method registers handlers for various parser events. It overrides any
previous handlers registered through the Style or Handler options or through
earlier calls to setHandlers. By providing a false or undefined value as
the handler, the existing handler can be unset.

This method returns a list of type, handler pairs corresponding to the
input. The handlers returned are the ones that were in effect prior to
the call.

See a description of the handler types in L<"HANDLERS">.

=item parse(SOURCE, URIBASE [, OPT => OPT_VALUE [...]])

The SOURCE parameter should either be a string containing the whole RDF
document, or it should be an open IO::Handle.
The URIBASE can be specified by the user to set a base URI to use for the generation of resource URIs during parsing. If this option is omitted the parser will try to generate a prefix for generated resources using either the L<Source> option of the constructor, the input filename or URL actually containing the input RDF. In a near future such an option could be obsoleted by use of XMLBase W3C raccomandation.
Constructor options to XML::Parser::Expat given as keyword-value pairs may follow the URIBASE
parameter. These override, for this call, any options or attributes passed
through from the RDFStore::Parser::SiRPAC instance.

A die call is thrown if a parse error occurs. Otherwise it will return 1
or whatever is returned from the B<Final> handler, if one is installed.
In other words, what parse may return depends on the style.

e.g. the RDFStore::Parser::SiRPAC::RDFStore Style module returns an instance of RDFStore::Stanford::Model

=item parsestring(STRING, URIBASE [, OPT => OPT_VALUE [...]])

This is just an alias for parse for backwards compatibility.

=item parsefile(URL_OR_FILE [, OPT => OPT_VALUE [...]])

Open URL_OR_FILE for reading, then call parse with the open handle. If URL_OR_FILE
is a full qualified URL this module uses Socket(3) to actually fetch the content.
The URIBASE L<parse()> parameter is set to URL_OR_FILE.

=item getReificationCounter()

Return the latest genid number generated by the parser

=back

=head1 HANDLERS

As Expat, SiRPAC is an event based parser. As the parser recognizes parts of the
RDF document then any handlers registered for that type of an event are called 
with suitable parameters.
All handlers receive an instance of XML::Parser::Expat as their first
argument. See L<XML::Parser::Expat/"METHODS"> for a discussion of the
methods that can be called on this object.

=head2 Init             (Expat)

This is called just before the parsing of the document starts.

=head2 Final            (Expat)

This is called just after parsing has finished, but only if no errors
occurred during the parse. Parse returns what this returns.

=head2 Assert            (Expat, Statement)

This event is generated when a new RDF statement has been generated by the parseer.start tag is recognized. Statement is of type RDFStore::Stanford::Statement(3) as generated
by the RDFStore::Stanford::NodeFactory(3) passed as argument to the RDFStore::Parser::SiRPAC 
constructor.

=head2 Start_XML_Literal            (Expat, Element [, Attr, Val [,...]])

This event is generated when an XML start tag is recognized within an RDF
property with parseType="Literal". Element is the
name of the XML element type that is opened with the start tag. The Attr &
Val pairs are generated for each attribute in the start tag.

This handler should return a string containing either the original XML chunck or one f its transformations, perhaps using XSLT.

=head2 Stop_XML_Literal              (Expat, Element)

This event is generated when an XML end tag is recognized within an RDF
property with parseType="Literal". Note that an XML empty tag (<foo/>) generates both a Start_XML_Literal and an Stop_XML_Literal event.

=head2 Char_XML_Literal             (Expat, String)

This event is generated when non-markup is recognized within an RDF
property with parseType="Literal". The non-markup sequence of characters is in 
String. A single non-markup sequence of encoding of the string in the original 
document, this is given to the handler in UTF-8.

This handler should return the processed text as a string.

=head1 WRITE YOUR OWN PARSER

Write an extension module for you needs it is as easy as write one for XML::Parser :)
Have a look at http://www.xml.com/xml/pub/98/09/xml-perl.html and http://wwwx.netheaven.com/~coopercc/xmlparser/intro.html.

You can either make you Perl script a parser self by embedding the needed function hooks or write a
custom Style module for RDFStore::Parser::SiRPAC.

=head2 *.pl scripts

	use RDFStore::Parser::SiRPAC;
	use RDFStore::NodeFactory;
	my $p=new RDFStore::Parser::SiRPAC(
		Handlers        => {
			Init    => sub { print "INIT\n"; },
			Final   => sub { print "FINAL\n"; },
			Assert  => sub { print "STATEMENT - @_\n"; }
		},
		NodeFactory     => new RDFStore::NodeFactory() );


or something like:

	use RDFStore::Parser::SiRPAC;
        use RDFStore::NodeFactory;
	my $p=new RDFStore::Parser::SiRPAC( NodeFactory     => new RDFStore::NodeFactory() );
	$p->setHandlers(        Init    => sub { print "INIT\n"; },
                        	Final   => sub { print "FINAL\n"; },
                        	Assert  => sub { print join(",",@_),"\n"; }     );

=head2 Style modules

A more sophisticated solution is to write a complete Perl5 Sytle module for RDFStore::Parser::SiRPAC that
can be easily reused in your code. E.g. a perl script could use this piece of code:

	use RDFStore::Parser::SiRPAC;
	use RDFStore::Parser::SiRPAC::MyStyle;
	use RDFStore::NodeFactory;

	my $p=new RDFStore::Parser::SiRPAC(	Style => 'RDFStore::Parser::SiRPAC::MyStyle',
                			NodeFactory     => new RDFStore::NodeFactory() );
	$p->parsefile('http://www.gils.net/bsr-gils.rdfs');

The Style module self could stored into a file like MyStyle.pm like this:

	package RDFStore::Parser::SiRPAC::MyStyle;

	sub Init { print "INIT\n"; };
	sub Final { print "FINAL\n"; };
	sub Assert {
                print "ASSERT: ",
                                $_[1]->subject()->toString(),
                                $_[1]->predicate()->toString(),
                                $_[1]->object()->toString(), "\n";
	};
	sub Start_XML_Literal { print "STARTAG: ",$_[1],"\n"; };
	sub Stop_XML_Literal { print "ENDTAG: ",$_[1],"\n"; };
	sub Char_XML_Literal { print "UTF8 chrs: ",$_[1],"\n"; };

	1;

For a more complete and useful example see RDFStore::Parser::SiRPAC::RDFStore(3).


=head1 BUGS

This module implements most of the W3C RDF Raccomandation as its Java counterpart SiRPAC from the Stanford University Database Group by Sergey Melnik (see http://www-db.stanford.edu/~melnik/rdf/api.html)
This version is conformant to the latest RDF API Draft on 2000-11-13. It does not support yet:

	* aboutEach

=head1 SEE ALSO

RDFStore::Parser::SiRPAC(3), DBMS(3) and XML::Parser(3) XML::Parser::Expat(3)
RDFStore::Stanford::Model(3) RDFStore::NodeFactory(3)

	RDF Model and Syntax Specification - http://www.w3.org/TR/REC-rdf-syntax
	RDF Schema Specification 1.0 - http://www.w3.org/TR/2000/CR-rdf-schema-20000327
	Benchmarking XML Parsers by Clark Cooper - http://www.xml.com/pub/Benchmark/article.html
	See also http://www.w3.org/RDF/Implementations/SiRPAC/SiRPAC-defects.html
	RDF::Parser(3) from http://www.pro-solutions.com

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>

	Sergey Melnik <melnik@db.stanford.edu> is the original author of the streaming version of SiRPAC in Java
	Clark Cooper is the author of the XML::Parser(3) module together with Larry Wall

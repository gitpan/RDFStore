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
# *             - fixed bug in parsefile() to read URL-less filenames
# *               (version0.1 was working only with 'file:' URL prefix)
# *             - fixed a lot of bugs/inconsistences in new(), parse(), parsestring()
# *             - added parse_start a la XML::parser for no-blocking stream
# *               parsing using XML::Parser::ExpatNB
# *		- does not use URI::file anymore
# *             - Modified createResource(), RDFStore::Parser::SiRPAC::Element and
# *               RDFStore::Parser::SiRPAC::DataElement accordingly to rdf-api-2000-10-30
# *             - General bug fixing accordingly to rdf-api-2000-10-30
# *               NOTE: Expat supports well XML Namespaces and PenRDF could use all the
# *               XML::Parser Namespace methods (e.g. generate_namespace()) to generate the
# *               corresponding Qname; it uses arrays and simple operations instead for efficency
# *		NOTE: OpenHealth.pm could be easily implemented as a kind of subClassOf PenRDF.pm
# *     version 0.31
# *             - updated documentation
# *		- changed wget() Socket handle to work with previous Perl versions (not my $handle) and
# *               do HTTP GET even on HTTP 'Location' redirect header
# *		- little change when checking if a prefix is undefined
# *

package RDFStore::Parser::OpenHealth;
{
	use strict;

	use vars qw($VERSION %Built_In_Styles);
	use Carp qw(carp croak cluck confess);
	use URI;
	use URI::Escape;
	use Socket;

BEGIN
{
	require XML::Parser::Expat;
    	$VERSION = '0.31';
    	croak "XML::Parser::Expat.pm version 2 or higher is needed"
		unless $XML::Parser::Expat::VERSION =~ /^2\./;
}

$RDFStore::Parser::OpenHealth::RDF_SYNTAX_NS="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
$RDFStore::Parser::OpenHealth::RDF_SCHEMA_NS="http://www.w3.org/TR/1999/PR-rdf-schema-19990303#";
$RDFStore::Parser::OpenHealth::XMLSCHEMA="xml";
$RDFStore::Parser::OpenHealth::XMLNS="xmlns";
$RDFStore::Parser::OpenHealth::RDFMS_parseType = $RDFStore::Parser::OpenHealth::RDF_SYNTAX_NS . "parseType";
$RDFStore::Parser::OpenHealth::RDFMS_type = $RDFStore::Parser::OpenHealth::RDF_SYNTAX_NS . "type";
$RDFStore::Parser::OpenHealth::RDFMS_about = $RDFStore::Parser::OpenHealth::RDF_SYNTAX_NS . "about";
$RDFStore::Parser::OpenHealth::RDFMS_bagID = $RDFStore::Parser::OpenHealth::RDF_SYNTAX_NS . "bagID";
$RDFStore::Parser::OpenHealth::RDFMS_resource = $RDFStore::Parser::OpenHealth::RDF_SYNTAX_NS . "resource";
$RDFStore::Parser::OpenHealth::RDFMS_aboutEach = $RDFStore::Parser::OpenHealth::RDF_SYNTAX_NS . "aboutEach";
$RDFStore::Parser::OpenHealth::RDFMS_aboutEachPrefix = $RDFStore::Parser::OpenHealth::RDF_SYNTAX_NS . "aboutEachPrefix";
$RDFStore::Parser::OpenHealth::RDFMS_ID = $RDFStore::Parser::OpenHealth::RDF_SYNTAX_NS . "ID";
$RDFStore::Parser::OpenHealth::RDFMS_RDF = $RDFStore::Parser::OpenHealth::RDF_SYNTAX_NS . "RDF";
$RDFStore::Parser::OpenHealth::RDFMS_Description = $RDFStore::Parser::OpenHealth::RDF_SYNTAX_NS . "Description";
$RDFStore::Parser::OpenHealth::RDFMS_Seq = $RDFStore::Parser::OpenHealth::RDF_SYNTAX_NS . "Seq";
$RDFStore::Parser::OpenHealth::RDFMS_Alt = $RDFStore::Parser::OpenHealth::RDF_SYNTAX_NS . "Alt";
$RDFStore::Parser::OpenHealth::RDFMS_Bag = $RDFStore::Parser::OpenHealth::RDF_SYNTAX_NS . "Bag";
$RDFStore::Parser::OpenHealth::RDFMS_predicate = $RDFStore::Parser::OpenHealth::RDF_SYNTAX_NS . "predicate";
$RDFStore::Parser::OpenHealth::RDFMS_subject = $RDFStore::Parser::OpenHealth::RDF_SYNTAX_NS . "subject";
$RDFStore::Parser::OpenHealth::RDFMS_object = $RDFStore::Parser::OpenHealth::RDF_SYNTAX_NS . "object";
$RDFStore::Parser::OpenHealth::RDFMS_Statement = $RDFStore::Parser::OpenHealth::RDF_SYNTAX_NS . "Statement";

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

	$firstnb->{OpenHealth} = {};

	#keep me in that list :)
	$firstnb->{OpenHealth}->{parser} = $class;
	croak "Missing NodeFactory"
		unless(	(defined $class->{NodeFactory}) && 
			($class->{NodeFactory}->isa("RDFStore::Stanford::NodeFactory")) );
  	$firstnb->{OpenHealth}->{nodeFactory} = $class->{NodeFactory};

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

	$firstnb->{FinalHandler} = $final
		if defined($final);

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

	$first->{OpenHealth} = {};

	#keep me in that list :)
	$first->{OpenHealth}->{parser} = $class;
	croak "Missing NodeFactory"
		unless(	(defined $class->{NodeFactory}) && 
			($class->{NodeFactory}->isa("RDFStore::Stanford::NodeFactory")) );
  	$first->{OpenHealth}->{nodeFactory} = $class->{NodeFactory};

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

sub parsestring {
	my $class = shift;
	my $string = shift;

	return $class->parse($string,undef,@_);
};

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
                return undef;
        };
        my $status = $3;
        my $reason = $4;
        if ( ($status != 200) && ($status != 302) ) {
                close(S);
                warn "Error MSG returned from server: $status $reason\n";
                return undef;
        };
        while(<S>) {
                chomp;
                if(m/Location\:\s(.*)$/) {
                        if( (   (exists $class->{HTTP_Location}) &&
                                (defined $class->{HTTP_Location}) && ($class->{HTTP_Location} ne $1)    ) ||
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

  	return undef
		if(!@{$attlist});

	my $n;
	for($n=0; $n<=$#{$attlist}; $n+=2) {
    		my $attname = $attlist->[$n]->[0].$attlist->[$n]->[1];
    		return $attlist->[$n+1]
			if ($attname eq $elName);
  	};
  	return undef;
}

sub RDFXML_StartElementHandler {
	my $expat = shift;
	my $tag = shift;
	my @attlist = @_;

	my $sNamespace = $expat->namespace($tag);
	if(not(defined $sNamespace)) {			
		my ($prefix,$suffix) = split(':',$tag);
		if($prefix eq $RDFStore::Parser::OpenHealth::XMLSCHEMA) {
			$sNamespace = $RDFStore::Parser::OpenHealth::XMLSCHEMA;
			$tag = $expat->generate_ns_name($suffix,$sNamespace); #xml:lang
		} else {
                        $expat->xpcroak("Unresolved namespace prefix '$prefix' for '$suffix'")
                                if( (defined $prefix) && (defined $suffix) );
		};
	};
	my $n;
	for($n=0; $n<=$#attlist; $n+=2) {
    		my $attname = $attlist[$n];
		my $namespace = $expat->namespace($attname);
		unless(defined $namespace) { #default namespace
			my ($prefix,$suffix) = split(':',$attname);
			if( (defined $prefix) && (defined $suffix) ) {
				if($prefix eq $RDFStore::Parser::OpenHealth::XMLSCHEMA) {
					$namespace = $RDFStore::Parser::OpenHealth::XMLSCHEMA;
					$attlist[$n] = [$namespace.$suffix];
				} else {
					$expat->xpcroak("Unresolved namespace prefix '$prefix' for '$suffix'");
				};
			} else {
				$namespace = undef;
				$attlist[$n]=[$namespace.$attname];
			};
		} else {
			$attlist[$n] = [$namespace.$attname];
		};
  	};

	if( $sNamespace.$tag eq $RDFStore::Parser::OpenHealth::RDFMS_subject ) {
		$expat->{RDF_subject} = $expat->{OpenHealth}->{nodeFactory}->createResource(getAttributeValue($expat,\@attlist,$RDFStore::Parser::OpenHealth::RDFMS_resource));
        } elsif( $sNamespace.$tag eq $RDFStore::Parser::OpenHealth::RDFMS_predicate ) {
		$expat->{RDF_predicate} = $expat->{OpenHealth}->{nodeFactory}->createResource(getAttributeValue($expat,\@attlist,$RDFStore::Parser::OpenHealth::RDFMS_resource));
        } elsif( $sNamespace.$tag eq $RDFStore::Parser::OpenHealth::RDFMS_object ) {
		if(my $att=getAttributeValue($expat,\@attlist,$RDFStore::Parser::OpenHealth::RDFMS_resource)) {
			#create RDFNode if necessary
			$expat->{RDF_object} = $expat->{OpenHealth}->{nodeFactory}->createResource($att);
		} else {
			#reset Literal
			$expat->{RDF_literal}='';
		};
	};
}

sub RDFXML_EndElementHandler {
	my $expat = shift;
	my $tag = shift;

	my $sNamespace = $expat->namespace($tag);
	if(not(defined $sNamespace)) {			
		my ($prefix,$suffix) = split(':',$tag);
		if($prefix eq $RDFStore::Parser::OpenHealth::XMLSCHEMA) {
			$sNamespace = $RDFStore::Parser::OpenHealth::XMLSCHEMA;
			$tag = $expat->generate_ns_name($suffix,$sNamespace); #xml:lang
		} else {
			$expat->xpcroak("Unresolved namespace prefix ",$prefix);
		};
	};


	if( $sNamespace.$tag eq $RDFStore::Parser::OpenHealth::RDFMS_Statement ) {
		#create Statement
		my $st = $expat->{OpenHealth}->{nodeFactory}->createStatement($expat->{RDF_subject},$expat->{RDF_predicate},$expat->{RDF_object});

		#Trigger 'Assert' event
		my $assert = $expat->{OpenHealth}->{parser}->{Handlers}->{Assert};
        	if (defined($assert)) {
        		&$assert($expat, $st);
		};

		#wipe up
		delete $expat->{RDF_subject};
		delete $expat->{RDF_predicate};
		delete $expat->{RDF_object};
		delete $expat->{RDF_literal};
        } elsif(	($sNamespace.$tag eq $RDFStore::Parser::OpenHealth::RDFMS_object ) &&
			(!(defined $expat->{RDF_object})) ) {
		#create Literal if necessary
		$expat->{RDF_object} = $expat->{OpenHealth}->{nodeFactory}->createLiteral($expat->{RDF_literal});
	};
};

sub RDFXML_CharacterDataHandler {
	my $expat = shift;
	my $text = shift;

	if(defined $expat->{RDF_literal}) { #consider just object data
     		# Warning: this is not correct procedure according to XML spec.
		# All whitespace matters!
		# skip preserveWhiteSpace() by checking here....
		#	return
		#		if( ($text =~ /^\s+/) && ($text =~ /\s+$/) && (!$bHasData) );
		# trim text
		my $trimtext = $text;
		$trimtext =~ s/^([ ])+//g;
		$trimtext =~ s/([ ])+$//g;
		if(length($trimtext)>0) {
			#add data to object Literal
			$expat->{RDF_literal} .= $text;
		};
	};
};

1;
};

__END__

=head1 NAME

RDFStore::Parser::OpenHealth - This module implements an RDF strawman parser for the syntax proposed by Jonathan Borden at http://www.openhealth.org/RDF/rdf_Syntax_and_Names.htm

=head1 SYNOPSIS

	use RDFStore::Parser::OpenHealth;
        use RDFStore::NodeFactory;
        my $p=new RDFStore::Parser::OpenHealth(
		ErrorContext => 2,
                Handlers        => {
                        Init    => sub { print "INIT\n"; },
                        Final   => sub { print "FINAL\n"; },
                        Assert  => sub { print "STATEMENT - @_\n"; }
                },
                NodeFactory     => new RDFStore::NodeFactory() );

	$p->parsefile('http://www.openhealth.org/RDF/mns-fig13-result.xml');
        $p->parsefile('/some/where/my.xml');
        $p->parsefile('file:/some/where/my.xml');
	$p->parse(*STDIN);

	use RDFStore;
	my $pstore=new RDFStore::Parser::OpenHealth(
                ErrorContext 	=> 2,
                Style 		=> 'RDFStore::Parser::SiRPAC::RDFStore',
                NodeFactory     => new RDFStore::NodeFactory(),
                store   =>      {
                                	persistent      =>      1,
                                	directory       =>      '/tmp/',
                                	seevalues       =>      1,
                                	options         =>      { style => 'BerkeleyDB', Q => 20 }
                                }
        );
	$pstore->parsefile('http://www.openhealth.org/RDF/mns-sect7.2-result.xml');

=head1 DESCRIPTION

This module implements a Resource Description Framework (RDF) strawman parser compliant to the syntax proposed by Jonathan Borden at http://www.openhealth.org/RDF/rdf_Syntax_and_Names.htm using the XSLT style sheet at http://www.openhealth.org/RDF/extract/rdfExtractity.xsl. Such a syntax is yet another extension/refinement of the original syntax proposed by Dan Connoly at http://www.w3.org/XML/2000/04rdf-parse/rdfp.xsl and already extended by Jason Diamond's at http://www.injektilo.org/rdf/rdf.xsl. The parser has been completely written in Perl using the XML::Parser::Expat(3) module. For the actual explaination see the RDFStore::Parser::SiRPAC(3) man page.

=head1 METHODS

RDFStore::Parser::OpenHealth supports all the RDFStore::Parser::SiRPAC options B<but> I<Source>. See the manual page for RDFStore::Parser::SiRPAC(3)

=head1 BUGS

Although the syntax proposed by Jonathan Borden is quite complete, the style-sheet is not unfortunately compatible with the Sablotron(3) great XSLT engine, that does not support 'exclude-result-prefixes' and functions overriding. A modified version working for Sablotron is available in the samples directory in the file xml2rdf.xsl.

=head1 SEE ALSO

RDFStore::Parser::SiRPAC(3), Sablotron(3) RDFStore::NodeFactory(3)

=item

Mapping namespace qualified element names to URIs - http://www.openhealth.org/RDF/QNameToURI.htm

=item

Jason Diamond's http://injektilo.org/rdf/examples.html

=item

Dan Connoly strawman sytax - http://www.w3.org/XML/2000/04rdf-parse/

=item

TimBL's semantic web toolbox - http://www.w3.org/DesignIssues/Toolbox

=item

RDF Model and Syntax Specification - http://www.w3.org/TR/REC-rdf-syntax

=item

RDF Schema Specification 1.0 - http://www.w3.org/TR/2000/CR-rdf-schema-20000327

=head1 AUTHOR

	Alberto Reggiori <alberto.reggiori@jrc.it>
	Clark Cooper is the author of the XML::Parser(3) module together with Larry wall

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
# *             - added more magic keywords to 'reservedWords' list
# *             - Modified createResource() accordingly to rdf-api-2000-10-30
# *     version 0.3
# *		- fixed bug in toPerlName() and dumpVocabulary() avoid grep regex checking
# *		- fixed bugs when checking references/pointers (defined and ref() )
# *

package RDFStore::Stanford::Vocabulary::Generator;
{
use Carp;

#bit funny Sergey assuems that we have already these pre-generated....
use RDFStore::Vocabulary::RDFS;
use RDFStore::Vocabulary::DC;
use RDFStore::Vocabulary::DAML; #then I added this one :)

sub new {
	my ($pkg) = @_;

    	my $self = {};

	$self->{LICENSE} = qq|# *
# *     Copyright (c) 2000 Alberto Reggiori / <alberto.reggiori\@jrc.it>
# *     ISIS/RIT, Joint Research Center Ispra (I)
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
|;
	$self->{DEFAULT_PACKAGE_CLASS} = "UnspecifiedClass";
	$self->{NS_IMPORT} = "use RDFStore::Model;\nuse Carp;\n";
	$self->{DEFAULT_NODE_FACTORY} = "RDFStore::NodeFactory";
	$self->{NS_COMMENT} = "# \n" .
		"# This package provides convenient access to schema information.\n".
		"# DO NOT MODIFY THIS FILE.\n".
		"# It was generated automatically by RDFStore::Stanford::Vocabulary::Generator\n#\n";
	$self->{NS_NSDEF} = "# Namespace URI of this schema";
	$self->{NS_ID} = "_Namespace";

	# some obvious reserved words
	$self->{reservedWords}=["package","use","require","BEGIN","END","sub","my","local",$self->{NS_ID}];

    	bless $self,$pkg;
};

# Schema as input parameter
sub createVocabulary {
	croak "Model ".$_[2]." is not an instance of RDFStore::Stanford::Model"
		unless( (defined $_[2]) &&
                	(ref($_[2])) && ($_[2]->isa("RDFStore::Stanford::Model")) );

	my $packageName = '';
	my $className = '';

	$_[5] = $_[0]->{DEFAULT_NODE_FACTORY}
		unless(defined $_[5]);

	my @info = split("::",$_[1]);
	$className = pop @info;
	$packageName = join("::",@info);

	print "Creating interface " . $className . " within package ". $packageName .  ( (defined $_[4]) ? " in ". $_[4] : ""),"\n";

	my $packageDirectory;
	if(!(defined $_[4])) {
		$packageDirectory=undef;
	} else {
		$packageName = ""
			if(!(defined $packageName));

		croak "Invalid output directory: ".$_[4]
			unless(-d $_[4]);

		#make it
		$packageDirectory = $packageName;
		$packageDirectory =~ s/\:\:/\//g;
		$packageDirectory = $_[4].$packageDirectory;
		`mkdir -p $packageDirectory`;
	};
    
	my $out;
	if( defined $_[4] ) {
		open(OUT,">".$packageDirectory."/".$className.".pm");
		$out=*OUT;
	} else {
		$out = *STDOUT;
	};

	$_[0]->dumpVocabulary( $out, $packageName, $className, $_[2], $_[3], $_[5] );
	close($out);
};

sub toPerlName {
	my $reserved=0;
	map { $reserverd=1 if($_ eq $_[1]); } @{$_[0]->{reservedWords}};
	return "_".$_[1]
		if($reserved);

	$_[1] =~ s/[\-\.]/_/g;
	$_[1] =~ s/^\d(.*)/_$1/g;
	return $_[1];
};

sub dumpVocabulary {
	my $out=$_[1]; 
	if((defined $_[2]) && ($_[2] ne '')) {
		print $out $_[0]->{LICENSE},"\n";
		print $out "package ".$_[3].";\n{\n";
		print $out $_[0]->{NS_IMPORT},"\n";
		print $out $_[0]->{NS_COMMENT},"\n";
		print $out $_[0]->{NS_NSDEF},"\n";
		print $out '$'.$_[0]->{NS_ID}.'= "'.$_[5].'";'."\n";
	};
	print $out "use $_[6];\n";
	print $out '&setNodeFactory(new '.$_[6]."());\n";

	print $out '
sub createResource {
	croak "Factory ".$_[0]." is not an instance of RDFStore::Stanford::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::Stanford::NodeFactory")) ) );

	return $_[0]->createResource($_Namespace,$_[1]);
};
sub setNodeFactory {
	croak "Factory ".$_[0]." is not an instance of RDFStore::Stanford::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::Stanford::NodeFactory")) ) );
';


	# write resource declarations adn definitions
	my @els;
	my $k;
	my $s;
	while( ($k,$s) = each %{$_[4]->elements} ) {
		next unless(ref($s));
		push @els,$s->subject();
		push @els,$s->object()
			if($s->object->isa("RDFStore::Stanford::Resource"));
	};
	my $r;
	my @v;
	foreach $r ( @els ) {
		my $res = $r->toString();
		if($res =~ /^$_[5]/) {
			my $name=substr($res,length($_[5]));
			if(length($name) > 0) { #NS already included as a string
				my $isthere=0;
				map { $isthere=1 if($_ eq $name); } @v;
				unless($isthere) {
					push @v,$name;
					my $pname = $_[0]->toPerlName($name);
					# comment?
					my ($k,$tComment)= each %{$_[4]->find($r, $RDFS::comment, undef )->elements};
					
					($k,$tComment)= each %{$_[4]->find($r, $DAML::comment, undef )->elements}
						unless(	(defined $tComment) &&
							(ref($tComment)) &&
							($tComment->isa("RDFStore::Stanford::Statement")) );
					($k,$tComment)= each %{$_[4]->find($r, $DC::Description, undef )->elements}
						unless(	(defined $tComment) &&
							(ref($tComment)) &&
							($tComment->isa("RDFStore::Stanford::Statement")) );
					if(defined $tComment) {
						my $it = $tComment->object()->toString;
						$it =~ s/\s/ /g;
						print $out "\t# $it\n";
          				};
					print $out "\t\$".$pname.' = createResource($_[0], "'.$name."\");\n";
				};
          		};
        	};
        };
	print $out "};\n1;\n};";
};

1;
};

__END__

=head1 NAME

RDFStore::Stanford::Vocabulary::Generator - implementation of the Vocabulary Generator RDF API

=head1 SYNOPSIS

	use RDFStore::Stanford::Vocabulary::Generator;
	my $generator = new RDFStore::Stanford::Vocabulary::Generator();
	# see vocabulary-generator.pl
	$generator->createVocabulary($packageClass, $all, $namespace, $outputDirectory, $factoryStr);

=head1 DESCRIPTION

Generate Perl packages with constants for resources defined in an RDF (Schema).

=head1 SEE ALSO

RDFStore::Vocabulary::RDF(3) RDFStore::Vocabulary::RDFS(3) RDFStore::Vocabulary::DC(3) RDFStore::Vocabulary::DAML(3)
RDFStore::SchemaModel(3)

=head1 AUTHOR

	Alberto Reggiori <alberto.reggiori@jrc.it>

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
# *		- fixed warning messages about 'noft' option
# *		- fixed warning in set_parent()
# *		- fixed warning in NEXT()
# *     version 0.31
# *		- added get_Options() method
# *		- updated documentation
# *

package Data::MagicTie;
{
	#Super fast now in C ;-)
	use Storable qw(freeze thaw nfreeze dclone);
	# We do not need sorted hashes.
	$Storable::canonical = 0;

	# Number of databases to split around - none as default
	$Data::MagicTie::Q_default = 1;
	use Carp;

	#To flush the buffer
	sub sync {
		my $class = shift;
		my $id = shift;

                # To flush the buffer
                # NOTE: we must fix for Q=1 here!!
                if( (defined $id) && (int($id)) ) {
                        $class->{db}->{ $id }->sync();
			return;
                };
                my $s;
                foreach $s ( 0 .. ($class->{ Q }-1) )
                {
                        $class->{db}->{ $s }->sync();
                };
		return;
	};

	sub TIEHASH {
		my ($pkg,$filename,%params) = @_;

		confess "Supply at least some DB name ?!"
                        unless($filename =~ m/\w{2}/);

		#default to local
		$params{lr}=0
			unless( (exists $params{lr}) && (defined $params{lr}) );

		#default splitting
		$params{Q}=$Data::MagicTie::Q_default
			unless( (exists $params{Q}) && (defined $params{Q}) && ($params{Q}>=1) );

		my $class={};
		bless $class,$pkg;

                $class->{'db'} = {};
		$class->{'db_stuff'} = {};
                $class->{'Q'} = $params{Q};
                $class->{dbs_count}=0;
                $class->{keys_count}=0;

		#default is to use Storable
		$class->{'noft'} =  ( 	(exists $params{noft}) && 
					(defined $params{noft}) && 
					(int($params{noft})) ) ? $params{noft} : 0;
		$params{noft}=$class->{'noft'};

		my $style;
		if($params{lr} == 1) {
			$style = 'DBMS'; #bit dirty due to $lr already there
			use Data::MagicTie::DBMS;
		} elsif( (exists $params{style}) && (defined $params{style}) && ($params{style} eq 'BerkeleyDB')) {
			use Data::MagicTie::BerkeleyDB;
			$style = 'BerkeleyDB';
		} else {
			use Data::MagicTie::DB_File;
			$style = 'DB_File';
		};
		$params{style}=$style;

		unless($params{lr} == 1) {
			#Create subdirectories if necessary
			my $dir;
                	($dir=$filename) =~ s/([^\/]+)$//g;

                	if($dir) {
                        	`mkdir -p $dir`
					unless -d $dir;
                	};

			$params{directory}=$dir;
			$params{filename}=$filename;
		};

		my $s;
                foreach $s ( 0 .. ($class->{ Q }-1) ) {
                        $class->{'db_stuff'}->{$s} = {};

			my $ffname;
			if($class->{'Q'} == 1) {
				$ffname = $filename.'.db';
			} else {
				$ffname = $filename.'_'.$s.'.db';
			};

                        next
				if( $class->{'db'}->{ $s }  = tie ( %{ $class->{'db_stuff'}->{ $s } }, "Data::MagicTie::".$style, $ffname,(%params) ));

			return undef;
		};

		#save options
		$class->{'db_options'} = \%params;

		return $class;
	};

	# TIEARRAY must be modified like TIEHASH
	sub TIEARRAY {
		my ($pkg,$filename,%params) = @_;

		#default to local
		$params{lr}=0
			unless( (exists $params{lr}) && (defined $params{lr}) );

		#default splitting
		$params{Q}=$Data::MagicTie::Q_default
			unless( (exists $params{Q}) && (defined $params{Q}) );

		my $class={};
		bless $class,$pkg;

                $class->{'db'} = {};
		$class->{'db_stuff'} = {};
                $class->{'Q'} = $params{Q};
                $class->{dbs_count}=0;
                $class->{keys_count}=0;

		#default is to use Storable
		$class->{'noft'} =  ( 	(exists $params{noft}) && 
					(defined $params{noft}) && 
					(int($params{noft})) ) ? $params{noft} : 0;
		$params{noft}=$class->{'noft'};

		my $style;
		if ($params{lr} == 1 ) {
			use Data::MagicTie::DBMS;
			croak"Data::MagicTie::DBMS::TIEARRAY Not impleted yet !\n";
		} elsif( (exists $params{style}) && (defined $params{style}) && ($params{style} eq 'BerkeleyDB')) {
			use Data::MagicTie::BerkeleyDB;
			$style = 'BerkeleyDB';
		} else {
			use Data::MagicTie::DB_File;
			$style = 'DB_File';
		};
		$params{style}=$style;

		unless($params{lr} == 1) {
			#Create subdirectories if necessary
			my $dir;
                	($dir=$filename) =~ s/([^\/]+)$//g;

                	if($dir) {
                        	`mkdir -p $dir`
					unless -d $dir;
                	}

			$params{directory}=$dir;
			$params{filename}=$filename;
		};

		# we should manage Q=0 or undefined Q as normal TIE on DB_File
		my $s;
                foreach $s ( 0 .. ($class->{ Q }-1) ) {
                        $class->{'db_stuff'}->{$s} = [];

			my $ffname;
			if($class->{'Q'} == 1) {
				$ffname = $filename.'.db';
			} else {
				$ffname = $filename.'_'.$s.'.db';
			};

                        next
				if( $class->{'db'}->{ $s }  = tie ( @{ $class->{'db_stuff'}->{ $s } }, "Data::MagicTie::".$style, $ffname,(%params) ));

			return undef;
		};

		#save options
		$class->{'db_options'} = \%params;

		return $class;
	};

	#barebone stupid hash function from $key to $db_id
	sub keyDB {
                my ($class,$db_id) = @_;

                unless($db_id =~ /^\d+/) {
                        #normalise to the ord of 6 chars (should use Unicode too)
                        #my $c = ("c" x length($db_id));
                        #$db_id = unpack($c,$db_id);
                        $db_id = length( $db_id );
                };

                return  $db_id ? ( int($db_id) % $class->{ Q } ) : 0;
        };

	sub get_Options {
		my $class = shift;

		return $class->{'db_options'};
	};

	sub set_parent {
		my $class = shift;
		my ($parent_ref) = @_;

		# Set the parent (if the same type of)
		if( (defined $parent_ref) && ($parent_ref != $class) && (ref($parent_ref) eq ref($class)) ) {
			$class->{'parent'} = $parent_ref;
			return 1;
		} else {
			return undef;
		};
	};

	sub get_parent {
		return $_[0]->{'parent'};
	};

	sub reset_parent {
		delete $_[0]->{'parent'};
	};

	#read methods
	sub FETCH {
		my $class = shift;

		my $id = $class->keyDB($_[0]);
 
		my $value = $class->{'db'}->{ $id }->FETCH(@_);

		# Chain the request to the parent if necessary
		#
		return $class->{'parent'}->FETCH(@_) if ( (not($value)) && ($class->{'parent'}) );

		return $value 
			if $class->{'noft'};

		if(defined $value)
		{
			my ($oldvalue) = thaw($value);
			$value = ref($oldvalue)=~ /SCALAR/ ? ${$oldvalue} : $oldvalue;
		}

		return $value;
	};

	sub EXISTS {
		my $class = shift;
		
		my $id = $class->keyDB($_[0]);

		my $value = $class->{'db'}->{ $id }->EXISTS(@_);

		#Chain the request to the parent if necessary
		if ( (not($value)) && ($class->{'parent'}) )
		{
			return $class->{'parent'}->EXISTS(@_);
		}
		else
		{
			return $value;
		}
	}

	sub FIRSTKEY {
		my $class = shift;
		
		while(  ($class->{dbs_count} < $class->{ Q }) &&
                        (($class->{keys_total}=scalar(keys %{$class->{'db_stuff'}->{$class->{dbs_count}}}))<=0) ) {
                        $class->{keys_count}=0;
                        $class->{dbs_count}++; #go next DB
                };

                if($class->{dbs_count} == $class->{ Q }) {
                        $class->{keys_count}=0;
                        $class->{dbs_count}=0;

			#Chain the request to the parent if necessary
			if($class->{'parent'}) {
				$class->{doing_parent}=1;
				my $value = $class->{'parent'}->FIRSTKEY();
				$class->{doing_parent}=0
					unless(defined $value);
				return $value;
			} else {
                        	return undef;
			};
                };

                my $a = keys %{$class->{'db_stuff'}->{$class->{dbs_count}}};
                my $value = scalar each %{$class->{'db_stuff'}->{$class->{dbs_count}}};

		return $value;
	};

	sub NEXTKEY {
		my $class = shift;
		
		if($class->{keys_count} == $class->{keys_total}-1) {
                        $class->{keys_count}=0;
                        $class->{dbs_count}++; #go next DB

			#Chain the request to the parent if necessary
			if ( ($class->{'parent'}) && ($class->{doing_parent}) ) {
				return $class->{'parent'}->NEXTKEY(@_);
			} else {
                        	return $class->FIRSTKEY();
			};
                } else {
                        $class->{keys_count}++;

			if( ($class->{'parent'}) && ($class->{doing_parent}) ) {
				return $class->{'parent'}->NEXTKEY(@_);
			} else {
                        	my $value = $class->{'db'}->{ $class->{dbs_count} }->NEXTKEY(@_);
				return $value;
			};
                };
	};

	# NOTE: obviously not chaining to parent for these write methods :)
	sub STORE {
		my $class = shift;
		my ($index_or_key,$value) = @_;

		my $id = $class->keyDB($index_or_key);

		$value = (ref($value)) ? freeze( $value ) : freeze( \$value )
			unless $class->{'noft'};
			
		return $class->{'db'}->{ $id }->STORE($index_or_key,$value);
	};

	sub inc {
		my $class = shift;

		croak "Sorry, but you should not do an atomic inc on a frozen DB" unless $class->{'noft'};

		my $id = $class->keyDB($_[0]);
		return $class->{'db'}->{ $id }->inc(@_);
	};

	sub DELETE {
		my $class = shift;
		
		my $id = $class->keyDB($_[0]);
		return $class->{'db'}->{ $id }->DELETE(@_);
	};

	# well it is not nice to clear/delete the parent stuff too ;-)
	sub CLEAR {
		my $class = shift;
		
		my $s;
                for $s ( 0 .. ($class->{ Q }-1) )
                {
                        # XXX no error trapping !
                        $class->{'db'}->{ $s }->CLEAR(@_);
                }

                return 1;
	};
	
	sub DESTROY {
		my $class = shift;

		my $s;
                for $s ( 0 .. ($class->{ Q }-1) )
                {
                        undef $class->{'db'}->{$s};

                        if (ref($class->{'db_stuff'}->{$s}) =~ /ARRAY/)
                        {
                                untie @{$class->{'db_stuff'}->{$s}};
                        }
                        else
                        {
                                untie %{$class->{'db_stuff'}->{$s}};
                        }
                };
	};
1;
}
__END__

=head1 NAME

Data::MagicTie - This module implements a proxy like Perl TIE interface over local and remote Berkeley DB files containing BLOBs 

=head1 SYNOPSIS

  	use Data::MagicTie;
	use Fcntl;

	my $hash = tie %a,'Data::MagicTie','test';
	my $hash = tie %a,'Data::MagicTie','test',( Q => 7, mode => O_RDONLY); #query 7 dbs in one
	my $hash = tie %a,'Data::MagicTie','test',( Q => 1, noft => 1); #normal hash
	my $hash = tie %a,'Data::MagicTie','test',( style => "BerkeleyDB"); #sleepycat-ish :-)
	my $hash = tie %a,'Data::MagicTie','test',( lr => 1, dbms_host => 'me.jrc.it'); #cool way

	$a{mykey} = 'myvalue'; #store
	my $b = $a{mykey}; #fetch
	#iterator
	while (($k,$v) = each %a) {
		my $c = $v;
	};
	#clear
	%a=();

	#basic delegation model - first match %a then %b
	my $hash1 = tie %b,'Data::MagicTie','test1';
	$hash1->set_parent($hash);
	print $b{mykey}; # looks up in %a :)
	untie %b;

	untie %a;

=head1 DESCRIPTION

This module acts as a proxy for the actual implementations of local and remote counterparts 
Data::MagicTie::DBMS(3) Data::MagicTie::DB_File(3) Data::MagicTie::BerkeleyDB(3) modules. 
It allows to an application script to transparently TIE hashes and arrays to either local
or remote Berkeley DB files, containing key/value pairs. The values can be either strings or
in-memory data structures (BLOBs) - see Storable(3); each tie database can then be splitted up on 
several files for eccifency and reduce the size of the actual database files. More, for query
purposes only, tie operations can be "chained" to transparently access different databases; such a
chain feature does not need any additional field in the database, but it is just using in-memory 
Perl OO methods to delegate read operations (FETCH, EXISTS, FIRSTKEY, NETXKEY). I.e. a look up for
a key or value in a database ends up in a read operation in the current database or in one of 
its "delegates".

Each atomic operation using the Perl operators actually trigger either local or remote database 
lookups and freeze/thaw operations on values. Perl constructs such as each, keys and values
can be used to iterate over the content of a tied database; when the file is splitted
over several single files the module iterates over the whole set of files. Even when a parent
(delegate) is set for a database these operators allow to scan the whole set of storages (note: this
feature might be not efficent over large databases).

By using such a Perl TIE model is becoming easy to write simple "cache" systems for example using
the Apache Web server and mod_perl. This could really important for RDF storages and cumbersome and
cpu-consuming queries. (see RDFStore::Model and RDFStore::FindIndex)

=head1 CONSTRUCTORS

The following methods construct/tie Data::MagicTie databases and objects:

=item $db_hash = tie %b, 'Data::MagicTie', $filename, %whateveryoulikeit;

Tie the hash %b to a MagicTie database called $filename. The %whateveryoulikeit hash
contains a set of configuration options about how and where store actual data.
Possible options are the following:

=over 4

=item lr

This is an integer flag 1/0 if a database is going to be stored in the local filesystem or on a 
remote DBMS(3) server - see Data::MagicTie::DBMS(3). Default is 0, local storage

=item Q

An integer about how many files to split around the database. Default to 1 (normal perltie behaviour).
Please note that set a number too high here might exceed you operating system MAX filedescriptors 
threshold (see man dbmsd(8) and DBMS(3) if installed on your system)

=item mode

Some valid predefied constant specifing if the database must be created, opened read/write/readonly.
For Data::MagicTie::DB_File(3) and Data::MagicTie::DBMS(3) possible values are O_CREAT, O_RDWR or 
O_RDONLY. For Data::MagicTie::BerkeleyDB(3) it culd either be DB_CREATE or DB_RDONLY - see DB_File(3)
and BerkeleyDB(3)

=item style

A string identifing if the database is going to be Data::MagicTie::DB_File(3), Data::MagicTie::BerkeleyDB(3) or Data::MagicTie::DBMS(3). Possible values are 'DB_File', 'BerkeleyDB' or 'DBMS'.
Default is 'DB_File'.

=item noft

This is in integer flag 1/0 to tell to the Data::MagicTie module whether or not use Storable(3)
freeze/thaw operations on values. This could be renamed blobs option. See BUGS section below.

=item dbms_host

This option is only valid for Data::MagicTie::DBMS(3) style and tells to the system which is
the IP address or machine name of the DBMS(3) server. Default is 'localhost'. See man dbmsd(8)

=item dbms_port

This option is only valid for Data::MagicTie::DBMS(3) style and tells to the system which is
the TCP/IP port to connect to for the DBMS protocol. Default is '1234'. See man dbmsd(8)
		


=item	$db_array = tie @b, 'Data::MagicTie', $filename, %whateveryoulikeit;

Tie the array @b to a MagicTie database called $filename. The %whateveryoulikeit hash
is the same as above.

=head1 METHODS

Most of the method are common to the standard perltie(3) interface (sync, TIEHASH, TIEARRAY, FETCH,
STORE, EXISTS, FIRSTKEY, NEXTKEY, CLEAR, DELETE, DESTROY)

In addition Data::MagicTie provides additional method that allow to magane a simple delegation or
pass-through model for database for read methods such as FETCH, EXISTS, FIRSTKEY, NEXTKEY. These
are the following:

=over 4

=item get_Options()

Return an hash reference containing all the major I<options> plus the I<directory> and I<filename> of
the database. See B<CONSTRUCTORS>

=item set_parent($ref)

Set the parent delegate to which forward read requests. $ref must be a valid Data::MagicTie blessed
Perl object, othewise the delegate is not set. After this method call any FETCH, EXISTS, FIRSTKEY or
NEXTKEY invocation (normally automagically called by Perl for you :-) starts up a chain of requests
to parents till the result has been found or undef.

=item get_parent()

Return a valid Data::MagicTie blessed Perl object pointing to the parent of a tied database

=item reset_parent()

Remove the parent of the database and the operations are back to normal.

=head1 EXAMPLES

=item delegates

use Data::MagicTie;

my $hash = tie %a,'Data::MagicTie','test';
my $hash1 = tie %b,'Data::MagicTie','test1';
my $hash2 = tie %c,'Data::MagicTie','test2';

for (1..10) {
        $a{"A".$_} = "valueA".$_;
        $b{"B".$_} = "valueB".$_;
        $c{"C".$_} = "valueC".$_;
};

#basic delegation model - first match %a then %a1 then %2
$hash->set_parent($hash1);
$hash1->set_parent($hash2);
print $a{B3}; # looks up in %b
print $a{C9}; # looks up in %c

#I think this one is much cooler :->
my $hash3 = tie %d,'Data::MagicTie','test3',( lr => 1 );
my $hash4 = tie %e,'Data::MagicTie','test4',( style => "BerkeleyDB" );

for (1..10) {
        $d{"D".$_} = "valueD".$_;
        $e{"E".$_} = "valueE".$_;
};

#...and then use local or remote databases transparently
$hash2->set_parent($hash3);
$hash3->set_parent($hash4);
print $a{D1}; # really the Perl way of doing ;-)
print $a{E1},"\n";

#iterator
while (($k,$v) = each %a) {
        print $k,"=",$v,"\n";
};

undef $hash;
untie %a;
undef $hash1;
untie %b;
undef $hash2;
untie %c;
undef $hash3;
untie %d;
undef $hash4;
untie %e;

=head1 BUGS

	- The current implementation of TIE supports only the TIEHASH and TIEARRAY interfaces.
	- Data::MagicTie::DBMS does not support TIEARRAY yet.
	- Data::MagicTie ARRAY support is not complete and probably broken
	- a well-known problem using BLOBs is the following:
		
		tie %a,"Data::MagicTie","test"; #by default is using BLOBs
		$a{key1} = sub { print "test"; }; # works
		$a{key2} = { a => [ 1,2,3], b => { tt => [6,7],zz => "test1234" } }; # it works too
		$a{key3}->{this}->{is}->{not} = sub { "working"; }; #does not always work

	The problem seems to be realated to the fact Perl is "automagically" extending/defining
	hashes (or other in-memory structures). As soon as you start to reference a value it
	gets created "spontaneously" :-( 
	E.g.
		$a = {};
		$a->{a1} = { a2 => [] };

		$b->{a1}->{a2} = []; # this is the same of the two lines above

	In the Data::MagicTie realm this problem affects the Storable freeze/thaw method results.
	Any idea how to fix this?

=head1 SEE ALSO

perltie(3) Storable(3) DBMS(3) 
Data::MagicTie::DBMS(3) Data::MagicTie::DB_File(3) Data::MagicTie::BerkeleyDB(3)

=head1 AUTHOR

Alberto Reggiori <alberto.reggiori@jrc.it>
You can send your postcards and bugfixes to

=head1 Contact Details

               TP270 - Reliable Information Technologies
               Institute for Systems, Informatics and Safety
               Joint Research Center of the European Community
               Ispra VA
               21020 Italy

               Fax +39 332 78 9185

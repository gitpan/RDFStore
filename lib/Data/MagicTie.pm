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
# *		- fixed warning messages about 'noft' option
# *		- fixed warning in set_parent()
# *		- fixed warning in NEXT()
# *     version 0.31
# *		- added get_Options() method
# *		- updated documentation
# *     version 0.4
# *		- complete redesign of Data::MagicTie. Dropped Data::MagicTie::(DBMS|DB_File|BerkeleyDB) modules
# *		  Everything is self contained in one model now.
# *		- changed options labels
# *		- updated documentation
# *		- added checking if DBMS, BerkeleyDB, DB_File or SDBM_File styles can not be loaded
# *		- changed way to return undef in subroutines
# *		- remove db files directory if tie operation fails
# *		- FIRSTKEY() and NEXTKEY() methods optimised
# *		- use File::Path module to create and remove directories to be portable
# *		- dropped lr (local/remote) option
# *		- dropped noft (no freeze/thaw) option
# *		- added in-memory style
# *		- added sharing option
# *		- added SDBM_File default style
# *		- fixed warning in _keyDB()
# *		- added perl version checking for Data::MagicTie::Array methods
# *		- added multiple reader/single writer locking support for DB_File
# *		- does not generate multiple '.db' extensions to files in _tie()
# *     version 0.41
# *		- fixed compilation bug while strict subs
# *		- added a warning in del_dup() if not supported by underlying DB_File library
# *		- updated _untie() to avoid warnings while untie databases
# *     version 0.42
# *		- fixed compilation bug while strict subs when missing DB_File
# *

package Data::MagicTie;
{
	use vars qw ( $VERSION $Split_default $NO_Storable $NO_SDBM_File $NO_DB_File $NO_DBMS $NO_BerkeleyDB $Storable_magicnumber );
	use strict;

	use Carp;
	use Symbol;
	use File::Path;

	my @flock = qw/:DEFAULT O_RDONLY O_RDWR O_CREAT/;
        if ($] >= 5.004) { # should have a complete Fcntl
                push @flock, ':flock';
        } else {
                sub LOCK_SH () { 1 };
                sub LOCK_EX () { 2 };
                sub LOCK_NB () { 4 };
                sub LOCK_UN () { 8 };
        };
        use Fcntl @flock;

	BEGIN {
		eval {
			require Storable;
			import Storable qw(freeze thaw nfreeze dclone);
		};
		$Data::MagicTie::NO_Storable=1
			if $@;
		eval {
			require SDBM_File;
		};
		$Data::MagicTie::NO_SDBM_File=1
			if $@;
		eval {
			require DB_File;
			import DB_File qw ( R_DUP R_NEXT R_CURSOR );
		};
		$Data::MagicTie::NO_DB_File=1
			if $@;
		eval {
			require DBMS;
		};
		$Data::MagicTie::NO_DBMS=1
			if $@;
		eval {
			require BerkeleyDB;
			import BerkeleyDB qw( DB_RDONLY DB_CREATE DB_INIT_CDB DB_INIT_MPOOL DB_DUP DB_NEXT DB_FIRST DB_NEXT_DUP DB_SET_RANGE DB_SET DB_NEXT_DUP );
		};
		$Data::MagicTie::NO_BerkeleyDB=1
			if $@;
	};

	# Number of databases to split around - none as default
	$Data::MagicTie::Split_default = 1;

	$VERSION = '0.42';

        # The lock() and unlock() facilities will be ONLY used inside implicit
        # methods (FETCH,STORE, NEXTKEY etc. etc. - see below)
        #
        sub _lock {
                my ($class,$id) = @_;

                return
                        unless(defined $class->{LOCKMODE});
 
                # Try a shared/exclusive non blocking lock.....
                unless(flock $class->{LOCKFD}->{$id},$class->{LOCKMODE} | LOCK_NB) {
                        # Otherwise try a blocking one.... i.e. wait
                        # effictively until someone else releases
                        # the exclsuive lock.
                        unless(flock $class->{LOCKFD}->{$id},$class->{LOCKMODE}) {
                                croak "flock: $!";
                        };
                };
        };
 
	sub _unlock {
                my ($class,$id) = @_;
 
                return
                        unless(defined $class->{LOCKMODE});
 
		$class->{db}->{$id}->sync()
			if($class->{LOCKMODE} == LOCK_EX);

                unless(flock $class->{LOCKFD}->{$id},LOCK_UN) {
                	croak "flock: $!";
                };
        };

	sub _setup {
		my ($class,%params) = @_;
		
		#default splitting
		$params{Split}=$Data::MagicTie::Split_default
			unless( (exists $params{Split}) && (defined $params{Split}) && ($params{Split}>=1) );

		#default to no duplicates
		$params{Duplicates}=(   (exists $params{Duplicates}) &&
					(defined $params{Duplicates}) &&
					(int($params{Duplicates})) ) ? $params{Duplicates} : 0;

		my $style;
		#default to SDBM_File
		if(	(	(	(!(exists $params{Style})) &&
					(!(defined $params{Style})) ) ||
				($params{Style} !~ m/DB_File|DBMS|BerkeleyDB/) ) &&
			(exists $params{Name})	&&
			(defined $params{Name}) &&
			($params{Name} ne '') &&
			($params{Name} !~ m/^\s+$/) &&
			(!($Data::MagicTie::NO_SDBM_File)) ) {
			$params{Style} = 'SDBM_File';
		} else {
			$params{Split}=1;
		};

		my $org_style = $params{Style};
		if((exists $params{Style}) && (defined $params{Style}) && ($params{Style} eq 'DBMS')) {
			if($Data::MagicTie::NO_DBMS) {
				$params{Style} = 'DB_File';
			} else {
				if(ref($params{type}) =~ /ARRAY/) {
                        		print STDERR "Tied ARRAYs not impleted for DBMS style";
					return;	
				};
				$style = 'DBMS';
			};
		} elsif( (exists $params{Style}) && (defined $params{Style}) && ($params{Style} eq 'BerkeleyDB')) {
			if($Data::MagicTie::NO_BerkeleyDB) {
				$params{Style} = 'DB_File';
			} else {
				$style = 'BerkeleyDB';
			};
		};
		if( (exists $params{Style}) && (defined $params{Style}) && ($params{Style} eq 'DB_File')) {
			if($Data::MagicTie::NO_DB_File) {
				$params{Style} = 'SDBM_File';
			} else {
				$style = 'DB_File';
			};
		};

		if( (exists $params{Style}) && (defined $params{Style}) && ($params{Style} eq 'SDBM_File')) {
			if($Data::MagicTie::NO_SDBM_File) {
				print STDERR "SDBM_File style not available. Transient in-memory style forced.";
				delete $params{Style};
			} else {
				if(ref($params{type}) =~ /ARRAY/) {
                			print STDERR "Tied ARRAYs not impleted for SDBM_File style";
					return;	
				};

				$style = 'SDBM_File';
			};
		};

		$params{Style}=$style
			if(defined $style);

		my $mkdir;
		if(	(exists $params{Style}) && 
			(defined $params{Style}) && 
			($params{Style} ne 'DBMS') ) {
			#Create subdirectories if necessary
			my $dir;
                	($dir=$params{Name}) =~ s/([^\/]+)$//g
				if(exists $params{Name});

                	if($dir) {
				unless(-d $dir) {
					mkpath($dir);
					$mkdir=$dir;
				};
                	};

			$params{directory}=$dir;
		};

		if(     (exists $params{Style}) &&
			(defined $params{Style}) &&
			($params{Style} eq 'DBMS') ) {
                	$params{Host} = 'localhost' #see man dbmsd(8)
                        	unless( (exists $params{Host}) && (defined $params{Host}) );
                	$params{Port} = '1234' #see man dbmsd(8)
                        	unless( (exists $params{Port}) && (defined $params{Port}) );
		};
 
		$params{Open_Mode} = $params{Mode}
			if(	(exists $params{Mode}) &&
				(defined $params{Mode}) );
		$params{Mode}='';
                if($params{Mode} eq 'r') {
			if($params{Style} eq 'BerkeleyDB') {
				{
				no strict;
                        	$params{Mode} = DB_RDONLY;
				};
			} else {
                        	$params{Mode} = O_RDONLY;
			};
                } elsif($params{Mode} eq 'w') {
			if($params{Style} eq 'BerkeleyDB') {
				{
				no strict;
                        	$params{Mode} = DB_CREATE;
				};
			} else {
                        	$params{Mode} = O_WRONLY;
			};
                } elsif(	($params{Mode} eq 'rw') ||
                		($params{Mode} eq 'wr') ) {
			if($params{Style} eq 'BerkeleyDB') {
				{
				no strict;
                        	$params{Mode} = DB_CREATE;
				};
			} else {
                        	$params{Mode} = O_RDWR;
			};
                } else {
			if(     (exists $params{Style}) &&
				(defined $params{Style}) &&
				($params{Style} eq 'BerkeleyDB') ) {
				{
				no strict;
                        	$params{Mode} = DB_CREATE;
				};
			} else {
                        	$params{Mode} = O_CREAT|O_RDWR;
			};
                };

		delete($params{Shared})
			unless(	(exists $params{Shared}) &&
				(defined $params{Shared}) &&
				(ref($params{Shared}) =~ /Data::MagicTie/) &&
				(ref($params{Shared}->{'db_options'}->{type}) eq ref($params{type})) );

		#save options
		$class->{'db_options'} = \%params;

		$class = $class->_tie()
			unless($params{Shared}); #we do it on demand asap first write operation

		return $class;
	};

	sub TIEHASH {
		my ($pkg,%params) = @_;

		my $class={};
		bless $class,$pkg;

		$params{type}={};

		return $class
			if($class->_setup(%params));
		return;
	};

	# TIEARRAY must be modified like TIEHASH
	sub TIEARRAY {
		my ($pkg,%params) = @_;

		my $class={};
		bless $class,$pkg;

		$params{type}=[];

		return $class
			if($class->_setup(%params));
		return;
	};

	# atomic tie - return an instance of an implementation
	sub _tie {
		my ($class) = @_;

		# lock stuff should be added here for DB_File.....

                $class->{db} = {};
		$class->{db_stuff} = {};
		$class->{db_env} = {};
		$class->{cursor}={};
                $class->{dbs_count}=-1;
		$class->{duplicates}={}; #to iterate over duplicate keys
		$class->{duplicates_count}={}; #to iterate over duplicate keys
		$class->{LOCKFD}={}; #keep a list of locks
		my $s;
                foreach $s ( 0 .. ($class->{db_options}->{ Split }-1) ) {
			if(ref($class->{db_options}->{type}) =~ /HASH/) {
                        	$class->{db_stuff}->{$s} = {};
			} elsif(ref($class->{db_options}->{type}) =~ /ARRAY/) {
                        	$class->{db_stuff}->{$s} = [];
			};

			my $ffname;
			$class->{db_options}->{Name} =~ s/\.db$//g
				if($class->{db_options}->{Name});
			if($class->{db_options}->{'Split'} == 1) {
				$ffname = $class->{db_options}->{Name}.'.db'
					if($class->{db_options}->{Name});
			} else {
				$ffname = $class->{db_options}->{Name}.'_'.$s.'.db'
					if($class->{db_options}->{Name});
			};
                	$ffname =~ m#(\/)(.*)(\/)#
				if $ffname;
                	umask 0;

			if(	(exists $class->{db_options}->{Style}) &&
				($class->{db_options}->{Style} eq 'SDBM_File') ) {
                		$class->{db}->{ $s } = tie ( 
					%{ $class->{'db_stuff'}->{$s} }, 
					"SDBM_File", 
					$ffname, 
					$class->{db_options}->{Mode},
					0644 );
			} elsif(	(exists $class->{db_options}->{Style}) &&
					($class->{db_options}->{Style} eq 'DB_File') ) {
				# Enable duplicate records if necessary
				{
                                no strict;
				$DB_File::DB_BTREE->{'flags'} = R_DUP
					if(     ($class->{'db_stuff'}->{$s} =~ /HASH/) &&
						($class->{db_options}->{Duplicates})    );
				};
                		$class->{db}->{ $s } = tie ( 
					( 	($class->{'db_stuff'}->{$s} =~ /HASH/) ? 
						%{ $class->{'db_stuff'}->{$s} } :
						@{ $class->{'db_stuff'}->{$s} } ), 
					"DB_File", 
					$ffname, 
					$class->{db_options}->{Mode},
					0644,
					($class->{'db_stuff'}->{$s} =~ /HASH/) ?
                                        $DB_File::DB_BTREE :
                                        $DB_File::DB_RECNO );
			} elsif(	(exists $class->{db_options}->{Style}) &&
					($class->{db_options}->{Style} eq 'BerkeleyDB') ) {
				{
				no strict;
                		$class->{db_env}->{ $s } = new BerkeleyDB::Env( Flags => DB_INIT_CDB|DB_INIT_MPOOL );
                		$class->{db}->{ $s } = tie ( 
						( 	($class->{'db_stuff'}->{$s} =~ /HASH/) ? 
							%{ $class->{'db_stuff'}->{$s} } :
							@{ $class->{'db_stuff'}->{$s} } ), 
						(       ($class->{'db_stuff'}->{$s} =~ /HASH/) ?
							"BerkeleyDB::Btree" : 
							"BerkeleyDB::Recno" ), 
						(	Env => $class->{db_env}->{ $s }, 
							Filename => $ffname, 
							Flags => $class->{db_options}->{Mode}, 
							Property  => (	($class->{'db_stuff'}->{$s} =~ /HASH/) &&
								($class->{db_options}->{Duplicates})    ) ?
								DB_DUP :
								undef,
							Mode => 0644 ) );
				#get a cursor
				$class->{cursor}->{ $s } = $class->{db}->{ $s }->db_cursor()
					if(	(exists $class->{db}->{ $s }) &&
						(defined $class->{db}->{ $s }) );
				};
			} elsif(	(exists $class->{db_options}->{Style}) &&
					($class->{db_options}->{Style} eq 'DBMS') ) {
                		$class->{db}->{ $s } = tie ( 
					%{ $class->{'db_stuff'}->{$s} }, 
					"DBMS", 
					$ffname, 
					$class->{db_options}->{Mode},
					$class->{db_options}->{Host},
					$class->{db_options}->{Port} );
			} else {
				# do it in-memory
                		$class->{db}->{ $s } = tie ( 
					( 	($class->{'db_stuff'}->{$s} =~ /HASH/) ? 
						%{ $class->{'db_stuff'}->{$s} } :
						@{ $class->{'db_stuff'}->{$s} } ), 
					(       ($class->{'db_stuff'}->{$s} =~ /HASH/) ?
						"Data::MagicTie::Hash" : 
						"Data::MagicTie::Array" ) );
                	};

			if(defined $class->{db}->{ $s }) {
				if(	(exists $class->{db_options}->{Style}) &&
					($class->{db_options}->{Style} eq 'BerkeleyDB') ) {
					$class->{db}->{ $s }->db_sync();
				} else {
                        		$class->{db}->{ $s }->sync()
						unless(	(!(exists($class->{db_options}->{Style}))) ||
                                			($class->{db_options}->{Style} eq 'SDBM_File') );
				};

				#locking stuff
				if(	(exists $class->{db_options}->{Style}) &&
                                        (	#($class->{db_options}->{Style} eq 'SDBM_File') ||
						($class->{db_options}->{Style} eq 'DB_File') ) ) {
					$class->{LOCKFD}->{ $s } = gensym;
                        		unless( open($class->{LOCKFD}->{ $s },"<&=" . $class->{'db'}->{ $s }->fd) ) {
                                		warn "fdopen: $!";
						return;
					};

					# Determine type of locking.
					my $lockmode;
					if ($class->{db_options}->{Mode} == O_RDONLY) {
						$lockmode = LOCK_SH;
					} else {
						$lockmode = LOCK_EX;
					};
					$class->{LOCKMODE} = $lockmode;
				};

				$class->{duplicates}->{ $s }={};
				$class->{duplicates_count}->{ $s }={};
				next;
			};

			warn "Cannot tie '",
				$class->{db_options}->{Name},
				"' with style '",
				($class->{db_options}->{Style} ? 
					$class->{db_options}->{Style} : 
					'in-memory'),
					"' and split '",
					$class->{db_options}->{Split},"': $!";

			rmtree($class->{db_options}->{directory})
				if(	(exists $class->{db_options}->{directory}) &&
					(defined $class->{db_options}->{directory}) );

			return;
		};
		return $class;
	};

	# atomic untie - destroy an instance of an implementation
	sub _untie {
                my ($class) = @_;

		my $s;
                for $s ( 0 .. ($class->{db_options}->{ Split }-1) ) {
			if(	(exists $class->{db_options}->{Style}) &&
                                (	($class->{db_options}->{Style} eq 'SDBM_File') ||
					($class->{db_options}->{Style} eq 'DB_File') ) ) {
					close($class->{LOCKFD}->{ $s })
						if(	(exists $class->{LOCKFD}->{ $s }) &&
							(defined $class->{LOCKFD}->{ $s }) );
			};
			delete $class->{cursor}->{ $s }
				if(	(exists $class->{cursor}->{ $s }) &&
					(defined $class->{cursor}->{ $s }) );
			delete $class->{db_env}->{ $s }
				if(	(exists $class->{db_env}->{ $s }) &&
					(defined $class->{db_env}->{ $s }) );
			delete $class->{duplicates}->{ $s }
				if(	(exists $class->{duplicates}->{ $s }) &&
					(defined $class->{duplicates}->{ $s }) );
			delete $class->{duplicates_count}->{ $s }
				if(	(exists $class->{duplicates_count}->{ $s }) &&
					(defined $class->{duplicates_count}->{ $s }) );
                        delete $class->{'db'}->{$s};

                        if (ref($class->{'db_stuff'}->{$s}) =~ /ARRAY/) {
                                untie @{$class->{'db_stuff'}->{$s}};
                        } else {
                                untie %{$class->{'db_stuff'}->{$s}};
                        };
                };
	};

	#barebone stupid hash function from $key to $db_id
	sub _keyDB {
                my ($class,$db_id) = @_;

                unless(	($db_id =~ m/^\d+$/) &&
			(int($db_id)) ) {
                        #normalise to the ord of 6 chars (should use Unicode too)
                        #my $c = ("c" x length($db_id));
                        #$db_id = unpack($c,$db_id);
                        $db_id = length( $db_id );
                };

                return  $db_id ? ( int($db_id) % $class->{db_options}->{ Split } ) : 0;
        };

	sub get_Options {
		my $class = shift;

print STDERR "get_Options - ",$class->{'db_options'}->{Name},"(@_)\n"
	if $::debug;

		return $class->{'db_options'};
	};

	sub set_parent {
		my $class = shift;
		my ($parent_ref) = @_;

print STDERR "set_parent - ",$class->{'db_options'}->{Name},"(@_)\n"
	if $::debug;

		# Set the parent (if the same type of)
		if( (defined $parent_ref) && ($parent_ref != $class) && (ref($parent_ref) eq ref($class)) ) {
			$class->{'parent'} = $parent_ref;
			return 1;
		} else {
			return;
		};
	};

	sub get_parent {
print STDERR "get_parent - ",$_[0]->{'db_options'}->{Name},"(@_)\n"
	if $::debug;

		return $_[0]->{'parent'};
	};

	sub reset_parent {
print STDERR "reset_parent - ",$_[0]->{'db_options'}->{Name},"(@_)\n"
	if $::debug;

		return delete $_[0]->{'parent'};
	};

	$Data::MagicTie::Storable_magicnumber='DMT';
	sub _deserialise {
		my($class,$value) = @_;

		#return $value
		#	unless(exists $class->{db_options}->{Style});

		# check whether the value string represent a frozen thingie or not
		if(	(defined $value) &&
			($value =~ s/^$Data::MagicTie::Storable_magicnumber//) ) {
			croak "Cannot fetch BLOBs because the Storable module is not properly installed"
				if $Data::MagicTie::NO_Storable;
			eval {
				my ($oldvalue) = thaw($value);
				$value = ref($oldvalue)=~ /SCALAR/ ? ${$oldvalue} : $oldvalue;
			};
			if($@) {
				warn $@;
				return;
			};
		};
		return $value;
	};

	sub _serialise {
		my($class,$value) = @_;

		#return $value
		#	unless(exists $class->{db_options}->{Style});

		my $v;
		if( 	(defined $value) &&
			($value =~ /^$Data::MagicTie::Storable_magicnumber/) ) {
			$v=$value;
			$value=\$v;
		};
		if(	(defined $value) &&
			(ref($value)) ) {
			croak "Cannot store BLOBs because the Storable module is not properly installed"
				if $Data::MagicTie::NO_Storable;

			eval {
				$value = $Data::MagicTie::Storable_magicnumber . nfreeze( $value );
			};
			if($@) {
				warn $@;
				return;
			};
		};
		return $value;
	};

	#read methods
	sub FETCHSIZE { 
		my $class = shift;

print STDERR "FS - ",$class->{'db_options'}->{Name},"(@_)\n"
	if $::debug;

		return $class->{db_options}->{Shared}->FETCHSIZE(@_)
			if(	(exists $class->{db_options}->{Shared}) &&
				(defined $class->{db_options}->{Shared}) );

		my $size=0;
                my $s;
		foreach $s ( 0 .. ($class->{db_options}->{ Split }-1) ) {
			$class->_lock($s)
                        	if(defined $class->{LOCKMODE});
			$size+=$#{$class->{db_stuff}->{$s}};
			$class->_unlock($s)
                        	if(defined $class->{LOCKMODE});
		};
		retrurn $size;
	};

	sub FETCH {
		my $class = shift;

		return $class->{db_options}->{Shared}->FETCH(@_)
			if(	(exists $class->{db_options}->{Shared}) &&
				(defined $class->{db_options}->{Shared}) );

print STDERR "F - ",$class->{'db_options'}->{Name},"(@_)\n"
	if $::debug;

		my $id = $class->_keyDB($_[0]);
 
		$class->_lock($id)
                      	if(defined $class->{LOCKMODE});

		my @values;
		if($class->{db_options}->{Duplicates}) {
			#always return the first of the multi list
			my $status;
			my $orig_key=$_[0];
			if(	($class->{'db_stuff'}->{$id} =~ /ARRAY/) ||
				(!(exists($class->{db_options}->{Style}))) ||
				($class->{db_options}->{Style} eq 'SDBM_File') ||
				($class->{db_options}->{Style} eq 'DBMS') ) {
				# we must return item by item
				unless(	(exists $class->{duplicates}->{ $id }->{$_[0]}) &&
                              		(defined $class->{duplicates}->{ $id }->{$_[0]}) ) {
					#"reset" the cursor/iterator
					# NOTE: duplicates are kept in-memory till all the elements are fetched or
					#       a complete iteration through each operator is performed
					my $v = $class->{'db'}->{ $id }->FETCH(@_);
					$class->{duplicates}->{ $id }->{$_[0]} = $class->_deserialise($v); # we thaw an ARRAY ref in any case
					$class->{duplicates_count}->{ $id }->{$_[0]}=$#{$class->{duplicates}->{ $id }->{$_[0]}};
				};
				$values[0] = shift @{$class->{duplicates}->{ $id }->{$_[0]}};
				$class->{duplicates_count}->{ $id }->{$_[0]}--;

				#clean up the iterator/cursor if necessary
				if($#{$class->{duplicates}->{ $id }->{$_[0]}} < 0) {
					delete($class->{duplicates_count}->{ $id }->{$_[0]});
					delete($class->{duplicates}->{ $id }->{$_[0]});
				};
			} elsif($class->{db_options}->{Style} eq 'DB_File') {
				{
                                no strict;
				$status=$class->{'db'}->{ $id }->seq($orig_key, $values[0], R_NEXT);
				$status=$class->{'db'}->{ $id }->seq($orig_key, $values[0], R_CURSOR)
					if $status;
				};
			} elsif($class->{db_options}->{Style} eq 'BerkeleyDB') {
				{
				no strict;
				$status=$class->{cursor}->{$id}->c_get($orig_key, $values[0], DB_NEXT_DUP);
				$status=$class->{cursor}->{$id}->c_get($orig_key, $values[0], DB_SET_RANGE)
					if $status;
				};
			};
		} else {
			my $value = $class->{'db'}->{ $id }->FETCH(@_);
			push @values, $value
				if(defined $value);
		};

		$class->_unlock($id)
                      	if(defined $class->{LOCKMODE});

		# Chain the request to the parent if necessary
		#
		return $class->{'parent'}->FETCH(@_)
			if( ($#values<0) && ($class->{'parent'}) );

		return $class->_deserialise($values[0]);
	};

	sub EXISTS {
		my $class = shift;
		
		return $class->{db_options}->{Shared}->EXISTS(@_)
			if(	(exists $class->{db_options}->{Shared}) &&
				(defined $class->{db_options}->{Shared}) );

#$::debug=1;
print STDERR "E - ",$class->{'db_options'}->{Name},"(@_)\n"
	if $::debug;

		my $id = $class->_keyDB($_[0]);
#print STDERR "ID='$id',caller=".(caller)[2]."\n";

		$class->_lock($id)
                      	if(defined $class->{LOCKMODE});

		my $value = $class->{'db'}->{ $id }->EXISTS(@_);

		$class->_unlock($id)
                      	if(defined $class->{LOCKMODE});

		#Chain the request to the parent if necessary
		if ( (not($value)) && ($class->{'parent'}) ) {
			return $class->{'parent'}->EXISTS(@_);
		} else {
			return $value;
		}
	}

	sub FIRSTKEY {
		my $class = shift;
		
		return $class->{db_options}->{Shared}->FIRSTKEY(@_)
			if(	(exists $class->{db_options}->{Shared}) &&
				(defined $class->{db_options}->{Shared}) );

                $class->{dbs_count}++; #go next DB

                if($class->{dbs_count} == $class->{db_options}->{ Split }) {
                        $class->{dbs_count}=-1;

			#Chain the request to the parent if necessary
			if($class->{'parent'}) {
				$class->{doing_parent}=1;
				my $value = $class->{'parent'}->FIRSTKEY();
				$class->{doing_parent}=0
					unless(defined $value);
				return $value;
			} else {
                        	return;
			};
                };

print STDERR "FK - ",$class->{'db_options'}->{Name},"(@_)\n"
	if $::debug;

		$class->_lock($class->{dbs_count})
                      	if(defined $class->{LOCKMODE});

		my $value = $class->{'db'}->{ $class->{dbs_count} }->FIRSTKEY();

		$class->_unlock($class->{dbs_count})
                	if(defined $class->{LOCKMODE});

		unless(defined $value) {
			$value = $class->FIRSTKEY();
		} elsif($class->{db_options}->{Duplicates}) {
			my $id = $class->_keyDB($value);
			if(	($class->{'db_stuff'}->{$id} =~ /ARRAY/) ||
				(!(exists($class->{db_options}->{Style}))) ||
				($class->{db_options}->{Style} eq 'SDBM_File') ||
				($class->{db_options}->{Style} eq 'DBMS') ) {
				unless(	(exists $class->{duplicates}->{ $id }->{$value}) &&
                        		(defined $class->{duplicates}->{ $id }->{$value}) ) {
					$class->_lock($id)
                      				if(defined $class->{LOCKMODE});

					my $v = $class->{'db'}->{ $id }->FETCH($value);

					$class->_unlock($id)
                      				if(defined $class->{LOCKMODE});

					$class->{duplicates}->{ $id }->{$value} = $class->_deserialise($v); # we thaw an ARRAY ref in any case
					$class->{duplicates_count}->{ $id }->{$value}=$#{$class->{duplicates}->{ $id }->{$value}}-1;
				};
			};
                };

		return $value;
	};

	sub NEXTKEY {
		my $class = shift;
		
		return $class->{db_options}->{Shared}->NEXTKEY(@_)
			if(	(exists $class->{db_options}->{Shared}) &&
				(defined $class->{db_options}->{Shared}) );

		if( ($class->{'parent'}) && ($class->{doing_parent}) ) {
			return $class->{'parent'}->NEXTKEY(@_);
		} else {
print STDERR "NK - ",$class->{'db_options'}->{Name},"(@_)\n"
	if $::debug;

			my $value;
			if($class->{db_options}->{Duplicates}) {
				my $id = $class->_keyDB($_[0]);
				if(	($class->{'db_stuff'}->{$id} =~ /ARRAY/) ||
					(!(exists($class->{db_options}->{Style}))) ||
					($class->{db_options}->{Style} eq 'SDBM_File') ||
					($class->{db_options}->{Style} eq 'DBMS') ) {
					# we must return n-times the current key if it is an iterator/cursor	
					if(	(exists $class->{duplicates}->{ $id }->{$_[0]}) &&
                        			(defined $class->{duplicates}->{ $id }->{$_[0]}) &&
						($class->{duplicates_count}->{ $id }->{$_[0]} >= 0) ) {
						$value = $_[0];
						$class->{duplicates_count}->{ $id }->{$_[0]}--;
					} else {
						if($class->{duplicates_count}->{ $id }->{$_[0]} < 0) {
							delete($class->{duplicates_count}->{ $id }->{$_[0]});
							delete($class->{duplicates}->{ $id }->{$_[0]});
						};

						$class->_lock($class->{dbs_count})
                					if(defined $class->{LOCKMODE});

						#go to the next one
						$value = $class->{'db'}->{ $class->{dbs_count} }->NEXTKEY(@_);

						$class->_unlock($class->{dbs_count})
                					if(defined $class->{LOCKMODE});

						if(defined $value) {
							$id = $class->_keyDB($value);

							$class->_lock($id)
                						if(defined $class->{LOCKMODE});

							my $v = $class->{'db'}->{ $id }->FETCH($value);

							$class->_unlock($id)
                						if(defined $class->{LOCKMODE});

							$class->{duplicates}->{ $id }->{$value} = $class->_deserialise($v); # we thaw an ARRAY ref in any case
							$class->{duplicates_count}->{ $id }->{$value} = $#{$class->{duplicates}->{ $id }->{$value}}-1;
						};
					};
				} else {
					$value = $class->{'db'}->{ $class->{dbs_count} }->NEXTKEY(@_);
				};
			} else {
				$class->_lock($class->{dbs_count})
                			if(defined $class->{LOCKMODE});

				$value = $class->{'db'}->{ $class->{dbs_count} }->NEXTKEY(@_);

				$class->_unlock($class->{dbs_count})
                			if(defined $class->{LOCKMODE});
			};

			$value = $class->FIRSTKEY()
				unless(defined $value);

			return $value;
		};
	};

	sub find_dup {
		my($class,$key,$value) = @_;

		return $class->{db_options}->{Shared}->find_dup($key,$value)
			if(	(exists $class->{db_options}->{Shared}) &&
				(defined $class->{db_options}->{Shared}) );

		return
			unless(	($class->{db_options}->{Duplicates}) ||
				(	($class->{'parent'}) &&
					($class->{'parent'}->{db_options}->{Duplicates}) ) );

print STDERR "find_dup - ",$class->{'db_options'}->{Name},"(@_)\n"
	if $::debug;

		my $status=1;
		my $id = $class->_keyDB($key);

		# we are assuming that object can be compared after using FT using $Storable::canonical!!!
                $Storable::canonical=1;
                my $vv = $class->_serialise($value);
		if(	($class->{'db_stuff'}->{$id} =~ /ARRAY/) ||
			(!(exists($class->{db_options}->{Style}))) ||
			($class->{db_options}->{Style} eq 'SDBM_File') ||
			($class->{db_options}->{Style} eq 'DBMS') ) {

			$class->_lock($id)
                		if(defined $class->{LOCKMODE});

			my $v = $class->{'db'}->{ $id }->FETCH($key);

			$class->_unlock($id)
                		if(defined $class->{LOCKMODE});

                        $v = $class->_deserialise($v);
			foreach(@{$v}) {
				if( $class->_serialise($_) eq $vv ) {
                                	$status=0;
					last;
				};
                        };
		} elsif($class->{db_options}->{Style} eq 'BerkeleyDB') {
			{
			no strict;
			my $s; 
			my $vvv;
			my $kkk=$key;
			for(	$s = $class->{cursor}->{$id}->c_get($kkk, $vvv, DB_SET_RANGE);
				$s == 0 ;
				$s = $class->{cursor}->{$id}->c_get($kkk, $vvv, DB_NEXT_DUP) ) {
				if(     ($kkk eq $key) &&
					($class->_serialise($vvv) eq $vv) ) {
                                       	$status=0;
					last;
				};
			};
			};
		} elsif($class->{db_options}->{Style} eq 'DB_File') {
			$class->_lock($id)
                		if(defined $class->{LOCKMODE});

			{
                        no strict;
			my $s; 
			my $vvv;
			my $kkk=$key;
			for(	$s = $class->{'db'}->{ $id }->seq($kkk, $vvv, R_CURSOR);
				$s == 0 ;
				$s = $class->{'db'}->{ $id }->seq($kkk, $vvv, R_NEXT) ) {
				if(	($kkk eq $key) &&
					($class->_serialise($vvv) eq $vv) ) {
                                       	$status=0;
					last;
				};
			};
			};

			$class->_unlock($id)
                		if(defined $class->{LOCKMODE});
		};
                $Storable::canonical=0;	

		#Chain the request to the parent if necessary
		if ( 	($status) && 
			($class->{'parent'}) ) {
			return $class->{'parent'}->find_dup(@_);
		} else {
			return $status;
		};
	};

	sub get_dup {
		my($class,$key,$flag) = @_;

		return $class->{db_options}->{Shared}->get_dup($key,$flag)
			if(	(exists $class->{db_options}->{Shared}) &&
				(defined $class->{db_options}->{Shared}) );

		return
			unless(	($class->{db_options}->{Duplicates}) ||
				(	($class->{'parent'}) &&
					($class->{'parent'}->{db_options}->{Duplicates}) ) );

print STDERR "get_dup - ",$class->{'db_options'}->{Name},"(@_)\n"
	if $::debug;

		my $id = $class->_keyDB($key);

		my $wantarray = wantarray;
		my %values=();
		my @values=();
		my $counter=0;
		my $status=0;
		if(	($class->{'db_stuff'}->{$id} =~ /ARRAY/) ||
			(!(exists($class->{db_options}->{Style}))) ||
			($class->{db_options}->{Style} eq 'SDBM_File') ||
			($class->{db_options}->{Style} eq 'DBMS') ) {

			$class->_lock($id)
                		if(defined $class->{LOCKMODE});

			my $v = $class->{'db'}->{ $id }->FETCH($key);

			$class->_unlock($id)
                		if(defined $class->{LOCKMODE});

                       	$v = $class->_deserialise($v);
			foreach(@{$v}) {
        			if($wantarray) {
            				if($flag) {
						++$values{$_};
					} else { 
						push @values,$_;
					};
        			} else {
					++$counter;
				};
                        };
		} elsif($class->{db_options}->{Style} eq 'BerkeleyDB') {
			{
			no strict;
			my $kkk=$key;
			my $vvv;
			for(	$status = $class->{cursor}->{$id}->c_get($kkk, $vvv, DB_SET_RANGE);
				( ($status == 0) && ($key eq $kkk) );
				$status= $class->{cursor}->{$id}->c_get($kkk, $vvv, DB_NEXT_DUP) ) {
        			if($wantarray) {
            				if($flag) {
						++$values{$vvv};
					} else { 
						push @values,$vvv;
					};
        			} else {
					++$counter;
				};
    			};
    			return ($wantarray ? ($flag ? %values : @values) : $counter); 
			};
		} elsif($class->{db_options}->{Style} eq 'DB_File') {
			$class->_lock($id)
                		if(defined $class->{LOCKMODE});

			if($wantarray) {
                        	if($flag) {
					%values = $class->{'db'}->{ $id }->get_dup($key,$flag);
                                } else {
					@values = $class->{'db'}->{ $id }->get_dup($key,$flag);
                                };
                        } else {
                        	$counter = scalar($class->{'db'}->{ $id }->get_dup($key,$flag));
                        };

			$class->_unlock($id)
                		if(defined $class->{LOCKMODE});
		};

		#Chain the request to the parent if necessary
		if ( 	(	(scalar(keys %values)<0) || 
				($#values<0) ||
				($counter==0) ) && ($class->{'parent'}) ) {
			if($wantarray) {
                        	if($flag) {
					%values = $class->{'parent'}->get_dup($key,$flag);
                                } else {
					@values = $class->{'parent'}->get_dup($key,$flag);
                                };
                        } else {
                        	$counter = scalar($class->{'parent'}->get_dup($key,$flag));
                        };
		};
    		return ($wantarray ? ($flag ? %values : @values) : $counter); 
	};

	# NOTE: obviously not chaining and sharing for write methods :)

	# If myself is read-only copy the other Data::MagicTie DB in-memory :( - copy on-write?
	# If the user passed a list here, that is the list of IDs to copy from the first to the second GDS
	sub copyOnWrite {
		my($class,@ids) = @_;

		return
			unless(	(exists $class->{db_options}->{Shared}) &&
				(defined $class->{db_options}->{Shared}) );

		my $shared = $class->{db_options}->{Shared};

		$class->_tie();	

		# copy the stuff across
		#XXXX it could be really expensive in memory consumage and CPU time!!!
		if(ref($class->{db_options}->{type}) =~ /HASH/) {
			my $lk;
			if($#ids>=0) {
				foreach $lk ( @ids ) {
					if($shared->{db_options}->{Duplicates}) {
						map {
							$class->STORE($lk,$_)
								if(defined $_);
						} $shared->get_dup($lk);
					} else {
						my $aa = $shared->FETCH($lk);
						$class->STORE($lk,$aa)
							if(defined $aa);
					};
				};
			} else {
				#the whole thing :(
				$lk = $shared->FIRSTKEY();
				do {
					my $aa = $shared->FETCH($lk);
					$class->STORE($lk,$aa)
						if(defined $aa);
				} while( $lk = $shared->NEXTKEY($lk) );
			};
                } elsif(ref($class->{db_options}->{type}) =~ /ARRAY/) {
			my $s;
			if($#ids>=0) {
				foreach $s ( @ids ) {
					if($shared->{db_options}->{Duplicates}) {
						map {
							$class->STORE($s,$_)
								if(defined $_);
						} $shared->get_dup($s);
					} else {
						my $aa = $shared->FETCH($s);
						$class->STORE($s,$aa)
							if(defined $aa);
					};
				};
			} else {
				#the whole thing :(
				foreach $s (0..$shared->FETCHSIZE()) {
					my $aa = $shared->FETCH($s);
					$class->STORE($s,$aa)
						if(defined $aa);
				};
			};
                } else {
			warn "Nothing copied really....\n";
		};

		#break the sharing
		delete($class->{db_options}->{Shared});

		#not sure that shared DB is untied right hereish.....
	};

	#To flush the buffer
	sub sync {
		my $class = shift;
		my $id = shift;

		return
			if($class->{db_options}->{Style} eq 'SDBM_File');

print STDERR "sync - ",$class->{'db_options'}->{Name},"(@_)\n"
	if $::debug;

		$class->copyOnWrite();

                # To flush the buffer
                # NOTE: we must fix for Split=1 here!!
                if( (defined $id) && (int($id)) ) {
			if($class->{db_options}->{Style} eq 'BerkeleyDB') {
				$class->{db}->{ $id }->db_sync();
			} else {
				$class->_lock($id)
                			if(defined $class->{LOCKMODE});

                        	$class->{db}->{ $id }->sync();

				$class->_unlock($id)
                			if(defined $class->{LOCKMODE});
			};
			return 1;
                };
                my $s;
                foreach $s ( 0 .. ($class->{db_options}->{ Split }-1) )
                {
			if($class->{db_options}->{Style} eq 'BerkeleyDB') {
				$class->{db}->{ $s }->db_sync();
			} else {
				$class->_lock($s)
                			if(defined $class->{LOCKMODE});

                        	$class->{db}->{ $s }->sync();

				$class->_lock($s)
                			if(defined $class->{LOCKMODE});
			};
                };
		return 1;
	};

	sub STORESIZE { };    # not implemented yet

	sub del_dup {
		my($class,$key,$value) = @_;

		$class->copyOnWrite();

		return
			unless($class->{db_options}->{Duplicates}); #no parent delegation

print STDERR "del_dup - ",$class->{'db_options'}->{Name},"(@_)\n"
	if $::debug;

		my $id = $class->_keyDB($key);
		if($class->{db_options}->{Duplicates}) {
			if(	($class->{'db_stuff'}->{$id} =~ /ARRAY/) ||
				(!(exists($class->{db_options}->{Style}))) ||
				($class->{db_options}->{Style} eq 'SDBM_File') ||
				($class->{db_options}->{Style} eq 'DBMS') ) {

				$class->_lock($id)
                			if(defined $class->{LOCKMODE});

				my $v = $class->{'db'}->{ $id }->FETCH($key);

                                $v = $class->_deserialise($v);

                                # we are assuming that object can be compared after using FT using $Storable::canonical!!!
                        	$Storable::canonical=1;
                        	my $vv = $class->_serialise($value);
                                my @values;
				foreach(@{$v}) {
                                        push @values, $_
						unless( $class->_serialise($_) eq $vv );
                                };
                        	$Storable::canonical=0;	

				$value = $class->_serialise(\@values);

				$value = $class->{'db'}->{ $id }->STORE($key,$value);

				$class->_unlock($id)
                			if(defined $class->{LOCKMODE});

				if(defined $value) {
					#reset the iterator/cursor (practically used in FETCH/FIRSTKEY/NEXTKEY)
					$class->{duplicates_count}->{ $id }->{$key}=$#values;
					$class->{duplicates}->{ $id }->{$key}=\@values;
				};

				return $value;
			} elsif($class->{db_options}->{Style} eq 'BerkeleyDB') {
				{
				no strict;
                        	my $vv = $class->_serialise($value);

				my $status; 
				my $vvv;
				my $kkk=$key;
				for(	$status = $class->{cursor}->{$id}->c_get($kkk, $vvv, DB_SET_RANGE);
					$status == 0 ;
					$status= $class->{cursor}->{$id}->c_get($kkk, $vvv, DB_NEXT_DUP) ) {
					return $class->{cursor}->{$id}->c_del()
						if(	($kkk eq $key) &&
							($vvv eq $vv) );
				};
				};
			} elsif($class->{db_options}->{Style} eq 'DB_File') {
				unless($class->{'db'}->{ $id }->can('del_dup')) {
					warn "del_dup method not supported from this DB_File version";
					return;
				};
                        	my $vv = $class->_serialise($value);

				$class->_lock($id)
                			if(defined $class->{LOCKMODE});

				my $status = $class->{'db'}->{ $id }->del_dup($key,$vv);

				$class->_unlock($id)
                			if(defined $class->{LOCKMODE});

				return $status;
			};
		};
	};

	sub STORE {
		my $class = shift;
		my ($index_or_key,$value) = @_;

		$class->copyOnWrite();

		my $id = $class->_keyDB($index_or_key);

print STDERR "S - ",$class->{'db_options'}->{Name},"(@_)\n"
	if $::debug;

		$class->_lock($id)
                	if(defined $class->{LOCKMODE});

		if($class->{db_options}->{Duplicates}) {
			if(	($class->{'db_stuff'}->{$id} =~ /ARRAY/) ||
				(!(exists($class->{db_options}->{Style}))) ||
				($class->{db_options}->{Style} eq 'SDBM_File') ||
				($class->{db_options}->{Style} eq 'DBMS') ) {
				my $v = $value;

				#additional FETCH :(
				my $v1 = $class->{'db'}->{ $id }->FETCH($index_or_key);
				$value = $class->_deserialise( $v1 );
				if(	(defined $value) &&
					(ref($value) =~ /ARRAY/) ) {
                                	# we are assuming that object can be compared after using FT using $Storable::canonical!!!
                                	push @{$value}, $v;
				} else {
					$value = [$v]; #mimic duplicates using an ARRAY :)
				};
			};
		};

		my $vvvv = $class->_serialise($value);

		$vvvv = $class->{'db'}->{ $id }->STORE($index_or_key,$vvvv);

		$class->_unlock($id)
                	if(defined $class->{LOCKMODE});

		if(	(defined $vvvv) &&
			($class->{db_options}->{Duplicates}) &&
			(	($class->{'db_stuff'}->{$id} =~ /ARRAY/) ||
				(!(exists($class->{db_options}->{Style}))) ||
				($class->{db_options}->{Style} eq 'SDBM_File') ||
				($class->{db_options}->{Style} eq 'DBMS') ) ) {
			#reset the iterator/cursor (practically used in FETCH/FIRSTKEY/NEXTKEY)
			$class->{duplicates_count}->{ $id }->{$index_or_key}=$#{$value};
			$class->{duplicates}->{ $id }->{$index_or_key}=$value;
		};

		#$class->{'db'}->{ $id }->sync();

		return $vvvv;
	};

	sub inc {
		my $class = shift;

		$class->copyOnWrite();

print STDERR "inc - ",$class->{'db_options'}->{Name},"(@_)\n"
	if $::debug;

		my $id = $class->_keyDB($_[0]);

		if(	(exists $class->{db_options}->{Style}) &&
			(defined $class->{db_options}->{Style}) &&
			($class->{db_options}->{Style} eq 'DBMS') &&
			(!($class->{db_options}->{Duplicates})) ) {
			return $class->{'db'}->{ $id }->inc(@_); #atomic - see dbmsd(8)
		} else {
			$class->_lock($id)
                		if(defined $class->{LOCKMODE});

			# XXXXX the following is _not_ atomic and fault tolerant!!!!!!
			my $value = ++$class->{db_stuff}->{ $id }->{$_[0]};

			$class->_unlock($id)
                		if(defined $class->{LOCKMODE});

                	return $value;
		};
	};

	sub DELETE {
		my $class = shift;
		
		$class->copyOnWrite();

print STDERR "D - ",$class->{'db_options'}->{Name},"(@_)\n"
	if $::debug;

		my $id = $class->_keyDB($_[0]);
		$class->_lock($id)
                	if(defined $class->{LOCKMODE});

		my $value = $class->{'db'}->{ $id }->DELETE(@_);

		$class->_unlock($id)
                	if(defined $class->{LOCKMODE});

		#$class->{'db'}->{ $id }->sync();
		return $value;
	};

	# well it is not nice to clear/delete the parent stuff too ;-)
	sub CLEAR {
		my $class = shift;
		
		#we could avoid the copy here...
		$class->copyOnWrite();

print STDERR "C - ",$class->{'db_options'}->{Name},"(@_)\n"
	if $::debug;

		my $s;
                for $s ( 0 .. ($class->{db_options}->{ Split }-1) ) {
			$class->_lock($s)
                		if(defined $class->{LOCKMODE});

                        # XXX no error trapping !
                        $class->{'db'}->{ $s }->CLEAR(@_);
			#$class->{'db'}->{ $s }->sync();

			$class->_unlock($s)
                		if(defined $class->{LOCKMODE});
                }

                return 1;
	};
	
	sub DESTROY {
		$_[0]->_untie();
	};

package Data::MagicTie::Array;

use vars qw ( $VERSION $perl_version_ok );
use strict;

$VERSION = '0.1';

BEGIN {
	$Data::MagicTie::Array::perl_version_ok=1;
	eval {
		require 5.6.0;
	};
	$Data::MagicTie::Array::perl_version_ok=0
		if($@);
};

sub new {
	return $_[0]->TIEARRAY(@_);
};

sub TIEARRAY {
	my ($pkg) = @_;

	my $self={};
	$self->{stuff}= [];
	return bless $self,$pkg;
};

sub sync {
};

sub FETCH {
	return $_[0]->{stuff}->[$_[1]];
};

sub FETCHSIZE {
	return $#{$_[0]->{stuff}};
};

sub EXISTS {
	return eval"exists($_[0]->{stuff}->[$_[1]])"
		if($Data::MagicTie::Array::perl_version_ok);
};

sub STORESIZE {
	return $#{$_[0]->{stuff}} = $_[1]
		if(int($_[1]));
};
 
sub inc {
	my $value = $_[0]->FETCH($_[1]);
	$value = int($value);
        if(defined $value) {
        	$value++;
               	$value = $_[0]->STORE($_[1],$value);
        };
	return $value;
};

sub STORE {
	$_[0]->{stuff}->[$_[1]] = $_[2];
	return;
};

sub DELETE {
	eval "delete($_[0]->{stuff}->[$_[1]])"
		if($Data::MagicTie::Array::perl_version_ok);
	return;
};

sub DESTROY {
};

package Data::MagicTie::Hash;

use vars qw ( $VERSION );
use strict;

$VERSION = '0.1';

sub new {
	return $_[0]->TIEHASH(@_);
};

sub TIEHASH {
	my ($pkg,%options) = @_;

	my $self={};
	$self->{stuff}={};
	return bless $self,$pkg;
};

sub sync {
};

sub FETCH {
	return $_[0]->{stuff}->{$_[1]};
};

sub EXISTS {
	return exists($_[0]->{stuff}->{$_[1]});
};

sub FIRSTKEY {
	my $a = keys %{$_[0]->{stuff}};
	return scalar each %{$_[0]->{stuff}};
};

sub NEXTKEY {
	return scalar each %{$_[0]->{stuff}};
};

sub inc {
	my $value = $_[0]->FETCH($_[1]);
	$value = int($value);
        if(defined $value) {
        	$value++;
               	$value = $_[0]->STORE($_[1],$value);
        };
	return $value;
};

sub STORE {
	$_[0]->{stuff}->{$_[1]} = $_[2];
	return;
};

sub DELETE {
	delete($_[0]->{stuff}->{$_[1]});
	return;
};

sub CLEAR {
	%{$_[0]->{stuff}}=();
};

sub DESTROY {
};

1;
}
__END__

=head1 NAME

Data::MagicTie - This module implements an adaptor like Perl TIE interface over hash and array that support BLOBs, delegation, duplicate keys, locking and storage splitting

=head1 SYNOPSIS

  	use Data::MagicTie;

	my $hash = tie %a,'Data::MagicTie'; #in-memory hash with duplicates and delegation support
	my $array = tie @a,'Data::MagicTie'; #in-memory array with duplicates and delegation support
	my $hash = tie %a,'Data::MagicTie','test',( Style => "DB_File", Split => 7, Mode => 'r'); #query 7 dbs in one
	my $hash = tie %a,'Data::MagicTie','test',( Split => 1 ); #normal hash
	my $hash = tie %a,'Data::MagicTie','test',( Style => "BerkeleyDB"); #sleepycat-ish :-)
	my $hash = tie %a,'Data::MagicTie','test',( Style => "DBMS", Host => 'me.jrc.it'); #cool way

	$a{mykey} = 'myvalue'; #store
	$a{myspecialkey} = [ {},'blaaa',[],[ { a => b, c => d }] ]; # ref store
	my $b = $a{mykey}; #fetch
	#iterator
	while (($k,$v) = each %a) {
		my $c = $v;
	};
	#clear
	%a=();

	#basic delegation model - first match %a then %b
	my $hash1 = tie %b,'Data::MagicTie','test1',(Style => "DB_File");
	$hash1->set_parent($hash);
	print $b{mykey}; # looks up in %a :)
	untie %b;
	untie %a;

	#duplicates
	my $hash = tie %a,'Data::MagicTie','test',( Style => "DB_File", Split => 7, Duplicates => 1); #7 dbs + duplicates

	$a{mykey} = 'myvalue'; #store
	$a{mykey} = [ {},'blaaa',[] ]; #ref store

	#iterator
	my $val;
	foreach(keys %a) {
		print $_=$a{$_}."\n"; # either scalars or refs
	};

	$hash->del_dup('mykey','myvalue');
	$hash->del_dup('mykey',[ {},'blaaa',[] ]);


=head1 DESCRIPTION

Perl provides two basic ways to model pluralities: hash and arrays. The perltie interface allows to easily map such data structuring constructs to databases and storages such as BerkeleyDB key/value-ed databases. Most of implementations existing today do provide duplicate keys, locking and BLOB support, but they are not almost integrated; most of the times the use of such features are not transparent at all to the end-user. In addition, most packages using the DB_File module do not provide a way to split up the storage over several files to scale up for large databases (i.e. most DB files get too big and inefficient to process - NOTE: this is not longer true with new generation Sleepycat BerkeleyDB implementations).

The Data::MagicTie module provides an integrated and omogenuous interface over hashes and arrays that support BLOBs, delegation, duplicate keys, locking and storage splitting; value lists can either be stored as an in-memory data structure, or a local or remote BerkeleyDB file. The module acts as an adaptor over actual implementations of Generic Data Storages (GDSs) such as Data::MagicTie::Array(3), Data::MagicTie::Hash(3), DBMS(3), DB_File(3) and BerkeleyDB(3). B<By default Data::MagicTie assumes an in-memory data structure model>. NOTE: I<a user would decide to use in-memory Data::MagicTie implementation over normal Perl hash/array to obtain duplicate keys and delegation support :)>

The values can be either strings or in-memory data structures (BLOBs) - see Storable(3); each tie database can then be splitted up on several files for eccifency and reduce the size of the actual database files. More, for query purposes only, tie operations can be "chained" to transparently access different databases; such a chain feature does not need any additional field in the database, but it is just using in-memory Perl OO methods to delegate read operations (FETCH, EXISTS, FIRSTKEY, NETXKEY). I.e. a look up for a key or value in a database ends up in a read operation in the current database or in one of its "delegates".

Each atomic operation using the Perl operators actually trigger either in-memory, local or remote database lookups and freeze/thaw operations on values. Perl iteration constructs such as B<each>, B<keys> and B<values> can then be used to iterate over the content of a tied database; when the file is splitted over several single files the module iterates over the whole set of files. Even when a parent (delegate) is set for a database these operators allow to scan the whole set of storages (note: this feature might be not efficent over large databases).

By using such a Perl TIE model is becoming easy to write simple "cache" systems for example using the Apache Web server and mod_perl. This could really important for RDF storages and cumbersome and cpu-consuming queries - see RDFStore::Model(3)

=head1 CONSTRUCTORS

The following methods construct/tie Data::MagicTie databases and objects:

=item $db_hash = tie %b, 'Data::MagicTie' [, %whateveryoulikeit ];

=item tie %b to a MagicTie database. The %whateveryoulikeit hash contains a set of configuration options about how and where store actual data.
Possible options are the following:

=over 4

=item Name

A string identifing the name of the database; this option make sense only for persistent storages such as DB_File(3), BerkeleyDB(3) or DBMS(3).

=item Style

A string identifing if the database is going to be DB_File(3), BerkeleyDB(3) or DBMS(3). Possible values are 'DB_File', 'BerkeleyDB' or 'DBMS'. By setting DBMS here the database is going to be stored on a remote DBMS(3) server. I<Default is to use an in-memory storage using Data::MagicTie::Array(3), Data::MagicTie::Hash(3)>.

=item Split

An integer about how many files to split around the database. I<Default to 1> (normal perltie behaviour).
Please note that set a number too high here might exceed you operating system MAX filedescriptors threshold (see man dbmsd(8) and DBMS(3) if installed on your system). Note that this option is ignored for default in-memory style.

=item Mode

A string which value can be 'r' (read only), 'w' (write only) or 'wr' (read/write). I<Default mode is 'rw'>. This option obviously does make sense only for persistent databases such as DBMS(3), Berkeley_DB(3) or DB_File(3).
Write mode forces the creation of the database. Open read only a new database fails. Internally the module maps these strings to low level Fcntl and BerkeleyDB constants such as O_CREAT, O_RDWR, O_WRONLY, O_RDONLY, DB_CREATE and DB_RDONLY.

=item Shared

This option allows to tie a Data::MagicTie GDS to an another B<existing Data::MagicTie GDS of the same type (hash/array)> and delegate all read operations to the underling object (I<copy on-read>); any write operation will call the B<copyOnWrite> method and will B<make a copy> of the secondary database (I<copy on-write>) over the input one and reset the Shared option. I<Please note such copy on-write could be really expensive for memory consumation and CPU cycles for in-memory databases, bear in mind what you are copying while doing so!>. Before copying the database the input GDS is actually tied and created using the original options passed by the user. By using the B<copyOnWrite> method the user can break/interrupt the sharing and copy the data across them; if a list of values is passed to the method only those specific keys are actually copied from the first to the second GDS (see below). I<By default the mothod copy the whole content across>.

Example

$a = tie %a, "Data::MagicTie",( Name => 'secondary' );
$a{test}='value';
$a{'test me please'}='value';
$a{'another test'}='value';

$b = tie %b, "Data::MagicTie",( Name => 'primary', Shared => $a);
print $b{test}; # prints 'value'

$b{test}='newvalue'; #reset the Shared option, tie %b to a GDS named 'primary' and copy the content accross

#or the user could also...
$b->copyOnWrite(); # to stop the sharing and copy the whole content across

# break sharing and copy 'test' and 'another test' across :)
$b->copyOnWrite('test','another test');

untie %a;
untie %b;

Tie a GDS to another one sitting on a disk or remote DBMS database allow the user to easily B<share> copies of data. As soon as a copy on-write is over the Shared option is reset to NULL and the input GDS is becoming completely independent from the secondary one.

This option is an alternative way to manage delegates but in a more complicated and tricky way. The canonical delegation model provided by the get/set/reset parent methods below always require to run the operation (method invocation) on the current database before passing through to the underling model, while by using the I<Shared> option the interaction is directly with the underling layer. In a near future this new way of managing duplicates could replace the current model :)

=item Duplicates

This is in integer flag to tell to the Data::MagicTie module whether or not use the BerkleyDB (>1.x) library code to handle duplicate keys. I<By default no duplicates are used>. This option works best for B<DB_File> and B<BerkeleyDB> styles hash tables while for all the other cases (arrays and DBMS style) the Storable(3) module is actually used to mimic duplicate keys behaviour by storing values as arrays. I<Please note that such a solution does require an addional FETCH operation for each STORE and is not atomic and fault tolerant...yet> :)

=item Host

This option is only valid for B<DBMS> style and tells to the system which is the IP address or machine name of the DBMS(3) server. I<Default is 'localhost'>. See man dbmsd(8)

=item Port

This option is only valid for B<DBMS> style and tells to the system which is
the TCP/IP port to connect to for the DBMS protocol. I<Default is '1234'>. See man dbmsd(8)
		

=item	$db_array = tie @b, 'Data::MagicTie' [, %whateveryoulikeit ];

Tie @b to a MagicTie database. The %whateveryoulikeit hash is the same as above.

=head1 METHODS

Most of the method are common to the standard perltie(3) interface (sync, TIEHASH, TIEARRAY, FETCH,
STORE, EXISTS, FIRSTKEY, NEXTKEY, CLEAR, DELETE, DESTROY)

=item get_Options()

Return an hash reference containing all the major I<options> plus the I<directory> and I<filename> of
the database. See B<CONSTRUCTORS>

In addition Data::MagicTie provides additional method that allow to manage a simple delegation or pass-through model; delegation happen just for read methods such as FETCH, EXISTS, FIRSTKEY, NEXTKEY.

=head2 Canonical delegation model

=over 4

=item set_parent($ref)

Set the parent delegate to which forward read requests. $ref must be a valid Data::MagicTie blessed
Perl object, othewise the delegate is not set. After this method call any FETCH, EXISTS, FIRSTKEY or
NEXTKEY invocation (normally automagically called by Perl for you :-) starts up a chain of requests
to parents till the result has been found or undef.

=item get_parent()

Return a valid Data::MagicTie blessed Perl object pointing to the parent of a tied database

=item reset_parent()

Remove the parent of the database and the operations are back to normal.

Data::MagicTie provides also equivalent methods to the DB_File module to manage duplicate keys - see DB_File(3) :

=head2 Duplicates

=item get_dup($key)

This method allows to read duplicate key values. In a scalar context the method returns the number of values associated with the key, $key. In list context, it returns all the values which match $key. Note that the values will be returned in an apparently random order. In list context, if the second parameter is present and evaluates TRUE, the method returns an associative array.  The keys of the associative array correspond to the values that matched the key $key and the values of the hash are a count of the number of times that particular value occurred.

=item del_dup($key,$value)

This method deletes a specific key/value pair.

=item find_dup($key, $value)

This method checks for the existence of a specific key/value pair. If the pair exists, the cursor is left pointing to the pair and the method returns 0. Otherwise the method returns a non-zero value.


=head1 EXAMPLES

=item Canonical delegation model howto

 use Data::MagicTie;

 my $hash = tie %a,'Data::MagicTie','test',(Style => "DB_File");
 my $hash1 = tie %b,'Data::MagicTie','test1',(Style => "DB_File");
 my $hash2 = tie %c,'Data::MagicTie','test2',(Style => "DB_File");

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
 my $hash3 = tie %d,'Data::MagicTie','test3',( Style -> "DBMS" );
 my $hash4 = tie %e,'Data::MagicTie','test4',( Style => "BerkeleyDB" );

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
	- DBMS style does not support TIEARRAY yet.
	- Data::MagicTie ARRAY support is not complete (FETCHSIZE at least should be added) - see perltie(3)
	- a well-known problem using BLOBs is the following:
		
		tie %a,"Data::MagicTie","test";
		$a{key1} = sub { print "test"; }; # works
		$a{key2} = { a => [ 1,2,3], b => { tt => [6,7],zz => "test1234" } }; # it works too
		$a{key3}->{this}->{is}->{not} = sub { "working"; }; #does not always work

	The problem seems to be realated to the fact Perl is "automagically" extending/defining
	hashes (or other in-memory structures). As soon as you start to reference a value it
	gets created "automatically" :-( 
	E.g.
		$a = {};
		$a->{a1} = { a2 => [] };

		$b->{a1}->{a2} = []; # this is the same of the two lines above

	In the Data::MagicTie realm this problem affects the Storable freeze/thaw method results.
	Any idea how to fix this?

=head1 SEE ALSO

perltie(3) Storable(3) DBMS(3) DB_File(3) BerkeleyDB(3)

=head1 AUTHOR

Alberto Reggiori <areggiori@webweaving.org>

You can send your postcards and bugfixes to

Alberto Reggiori
Via Giacomo Puccini 16 - 21014
Laveno Mombello (VA) ITALY

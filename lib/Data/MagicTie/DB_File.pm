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
# *
#
package Data::MagicTie::DB_File;
{
	$|=1;$::|=1;

	use DB_File;
	use Carp;
        use Symbol;
        use Fcntl;

        #Used by flock() syscall
        $LOCK_SH=1;
        $LOCK_EX=2;
        $LOCK_NB=4;
        $LOCK_UN=8;

        # The lock() and unlock() facilities will be ONLY used inside implicit 
        # methods (FETCH,STORE, NEXTKEY etc. etc. - see below)
        #
	sub lock {
                my $class = shift;
                my ($rw) = @_;  #r = 0       w = 1

                if ($rw == 0)   #Read lock
                {
                        # Try a Shared non blocking lock.....
                        unless (flock $class->{LOCKFD},$LOCK_SH | $LOCK_NB)
                        {
                                # Otherwise try a blocking one.... i.e. wait
                                # effictively until someone else releases
                                # the exclsuive lock.
                                unless (flock $class->{LOCKFD},$LOCK_SH) 
                                {
                                        croak "flock: $!";
                                }
                        }
                }
                else
                {
                        # Try an Exclusive non blocking lock.....
                        unless (flock $class->{LOCKFD},$LOCK_EX | $LOCK_NB)
                        {
                                #Otherwise try a blocking one....
                                unless (flock $class->{LOCKFD},$LOCK_EX) 
                                {
                                        croak "flock: $!";
                                }
                        }
                } 
        };

        sub unlock {
                my $class = shift;

                #To flush the buffer
		$class->{db}->sync();
                flock $class->{LOCKFD},$LOCK_UN;
        };
	
	sub sync {
		my $class = shift;

		return $class->{db}->sync();
	};

	sub TIEHASH {
		my ($pkg,$filename,%params) = @_;

		my $class = {};
		bless $class,$pkg;

		$class->{'dbfullfilename'} = $filename;

		$filename =~ m#(\/)(.*)(\/)#;
		$class->{'dbfilename'} = $';
		$class->{'dbdirname'} = $&;
		$class->{'db_stuff'} = {};
		umask 0;

		$params{mode} = O_CREAT
			unless( (exists $params{mode}) && (defined $params{mode}) );

		if( $class->{'db'}  = tie ( %{ $class->{'db_stuff'} }, "DB_File", $filename, $params{mode},0666,$DB_HASH ) ) {
			#### this sync is fundamental (otherwise we get o sized db files!!)
			$class->{db}->sync();	
			$class->{LOCKFD} = gensym;
                        open($class->{LOCKFD},"+<&=" . $class->{'db'}->fd) 
				or confess "fdopen: $!";
			return $class;
		};
		return undef;
	};

	sub TIEARRAY {
		my ($pkg,$filename,%params) = @_;

		my $class = {};
		bless $class,$pkg;

		$class->{'dbfullfilename'} = $filename;

		$filename =~ m#(\/)(.*)(\/)#;
		$class->{'dbfilename'} = $';
		$class->{'dbdirname'} = $&;
		$class->{'db_stuff'} = [];
		umask 0;

		$params{mode} = O_CREAT
			unless( (exists $params{mode}) && (defined $params{mode}) );

		if( $class->{'db'}  = tie ( @{ $class->{'db_stuff'} }, "DB_File", $filename, $params{mode},0666,$DB_RECNO ) ) {
			#### this sync is fundamental (otherwise we get o sized db files!!)
			$class->{db}->sync();	
			$class->{LOCKFD} = gensym;
                        open($class->{LOCKFD},"+<&=" . $class->{'db'}->fd) 
				or confess "fdopen: $!";
			return $class;
		};
		return undef;
	};

	#read methods
	sub FETCH {
		my $class = shift;

		$class->lock(0);
		$class->{db}->sync();	
		my $value = $class->{'db'}->FETCH(@_);
		$class->unlock();

		return $value;
	}

	sub inc {
		my $class = shift;

		$class->lock(0);
		$class->{db}->sync();	

		my $value = $class->{'db'}->FETCH($_[0]);

		if(defined $value) {
			$value++;
			$value = $class->{'db'}->STORE($_[0],$value);
		};

		$class->unlock();

		return $value;
	};


	sub EXISTS {
		my $class = shift;

                $class->lock(0);
		$class->{db}->sync();	
                my $value = $class->{'db'}->EXISTS(@_);
                $class->unlock();

                return $value;
	};

	sub FIRSTKEY {
                my $class = shift;

                $class->lock(0);
		$class->{db}->sync();	
                my $a = keys %{$class->{'db_stuff'}};
                my $value = scalar each %{$class->{'db_stuff'}};
                $class->unlock();
		return $value;
        };
	
	sub NEXTKEY {
                my $class = shift;

                if($class->{keys_count} == $class->{keys_total}-1) {
                        $class->{keys_count}=0;
                        $class->{dbs_count}++; #go next DB

                        return $class->FIRSTKEY();
                } else {
                        $class->{keys_count}++;
                	$class->lock(0);
			$class->{db}->sync();	
                        my $value = $class->{'db'}->NEXTKEY(@_);
                	$class->unlock();
			return $value;
                };
        }

	#write methods
	sub STORE {
		my $class = shift;

                $class->lock(1);
		$class->{db}->sync();	
		my $returnvalue = $class->{'db'}->STORE(@_);
		$class->{db}->sync();	
                $class->unlock();

		return $returnvalue;	#do not chain here
	};

	sub DELETE {
		my $class = shift;

                $class->lock(1);
		$class->{db}->sync();	
                my $returnvalue = $class->{'db'}->DELETE(@_);
		$class->{db}->sync();	
                $class->unlock();

                return $returnvalue;
	};

	sub CLEAR {
		my $class = shift;

		# XXX no error trapping !
                $class->lock(1);
		$class->{db}->sync();	
		$class->{'db'}->CLEAR(@_);
		$class->{db}->sync();	
                $class->unlock();

		return 1;
	};

	sub DESTROY {
		my $class = shift;

		close($class->{LOCKFD});
		undef $class->{'db'};

		if (ref($class->{'db_stuff'}) =~ /ARRAY/)
		{
                	untie @{$class->{'db_stuff'}};
                }
		else
		{
                	untie %{$class->{'db_stuff'}};
               	}
	};

1;
}

__END__

=head1 NAME

Data::MagicTie::DB_File - This module is used by Data::MagicTie(3) to get a tied tied DB_File with locking support.

=head1 SYNOPSIS

see DB_File(3)

=head1 DESCRIPTION

=head1 SEE ALSO

http://www.sleepycat.com

=head1 AUTHOR

Alberto Reggiori <alberto.reggiori@jrc.it>

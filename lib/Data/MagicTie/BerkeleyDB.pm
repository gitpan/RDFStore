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
# *             - fixed bug in DESTROY() to undef the tied variable
# *     version 0.4
# *		- completely modified the access methods to Sleepycat library and DBs - see Data::MagicTie::DB_File(3)
# *
package Data::MagicTie::BerkeleyDB;
{
	$|=1;$::|=1;

	use BerkeleyDB;
	use Carp;

	sub sync {
		my $class = shift;
		my $id = shift;

		$class->{db}->db_sync();
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

		$params{mode} = DB_CREATE
			unless( (exists $params{mode}) && (defined $params{mode}) );

		if( $class->{'db'}  = tie ( %{ $class->{'db_stuff'} }, "BerkeleyDB::Btree", (Filename => $filename, Flags => $params{mode}, "Mode" => 0666) ) ) {
			$class->{'db'}->db_sync();
			return $class;
		};
		return undef;
	};


	# TIEARRAY  not yet.....
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

		$params{mode} = DB_CREATE
			unless( (exists $params{mode}) && (defined $params{mode}) );

		if( $class->{'db'}  = tie ( @{ $class->{'db_stuff'} }, "BerkeleyDB::Recno",( "Filename" => $filename, "Flags" => $params{mode}, "Mode" => 0666) ) ) {
			$class->{'db'}->db_sync();
			return $class;
		};
		return undef;
	};

	#read methods
	sub FETCH {
		my $class = shift;

		$class->{'db'}->db_sync();
		my $value = $class->{'db'}->FETCH(@_);

		return $value;
	}

	sub inc {
		my $class = shift;

		$class->{'db'}->db_sync();

		my $value = $class->{'db'}->FETCH($_[0]);

		if(defined $value) {
			$value++;
			$value = $class->{'db'}->STORE($_[0],$value);
		};

		return $value;
	};


	sub EXISTS {
		my $class = shift;

		$class->{'db'}->db_sync();
                my $value = $class->{'db'}->EXISTS(@_);

                return $value;
	};

	sub FIRSTKEY {
                my $class = shift;

		$class->{'db'}->db_sync();
                my $a = keys %{$class->{'db_stuff'}};
                my $value = scalar each %{$class->{'db_stuff'}};
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
			$class->{'db'}->db_sync();
                        my $value = $class->{'db'}->NEXTKEY(@_);
			return $value;
                };
        }

	#write methods
	sub STORE {
		my $class = shift;

		$class->{'db'}->db_sync();
		my $returnvalue = $class->{'db'}->STORE(@_);
		$class->{'db'}->db_sync();

		return $returnvalue;	#do not chain here
	};

	sub DELETE {
		my $class = shift;

		$class->{'db'}->db_sync();
                my $returnvalue = $class->{'db'}->DELETE(@_);
		$class->{'db'}->db_sync();

                return $returnvalue;
	};

	sub CLEAR {
		my $class = shift;

		# XXX no error trapping !
		$class->{'db'}->db_sync();
		$class->{'db'}->CLEAR(@_);
		$class->{'db'}->db_sync();

		return 1;
	};

	sub DESTROY {
		my $class = shift;

		undef $class->{'db'};

		if (ref($class->{'db_stuff'}) =~ /ARRAY/) {
                	untie @{$class->{'db_stuff'}};
                } else {
                      	untie %{$class->{'db_stuff'}};
		};
	};

1;
}

__END__

=head1 NAME

Data::MagicTie::BerkeleyDB - This module is used by Data::MagicTie(3) to get a tied over SleepyCat BerkeleyDB files.

=head1 SYNOPSIS

see BerkeleyDB(3)

=head1 DESCRIPTION

=head1 SEE ALSO

http://www.sleepycat.com

=head1 AUTHOR

Alberto Reggiori <alberto.reggiori@jrc.it>

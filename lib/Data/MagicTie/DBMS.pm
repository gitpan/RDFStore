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
# *     version 0.3
# *		- fixed bug in FIRSTKEY(). Do not call keys and each anymore.
# *
package Data::MagicTie::DBMS;
{
	$|=1;$::|=1;

	use DBMS;
	use Carp;
	use Fcntl;
	
	sub sync {
		my $class = shift;

		return $class->{db}->sync();
	};

	sub TIEHASH {
		my ($pkg,$filename,%params) = @_;

		$params{dbms_host} = 'localhost' #see man dbmsd(8)
			unless( (exists $params{dbms_host}) && (defined $params{dbms_host}) );

		$params{dbms_port} = '1234' #see man dbmsd(8)
			unless( (exists $params{dbms_port}) && (defined $params{dbms_port}) );

		my $class = {};
		bless $class,$pkg;

		$class->{'dbfullfilename'} = $filename;

		$filename =~ m#(\/)(.*)(\/)#;
		$class->{'dbfilename'} = $';
		$class->{'dbdirname'} = $&;
		$class->{'db_stuff'} = {};
		umask 0;

		#yes DBMS uses DB_File still
                $params{mode} = O_CREAT
			unless( (exists $params{mode}) && (defined $params{mode}) );

		if( $class->{'db'}  = tie ( %{ $class->{'db_stuff'} }, "DBMS", $filename, $params{mode},$params{dbms_host},$params{dbms_port} ) ) {
			$class->{db}->sync();
			return $class;
		} else {
			return undef;
		};
	};


	# TIEARRAY  not yet.....

	#read methods
	sub FETCH {
		my $class = shift;

		return $class->{'db'}->FETCH(@_);
	};

	sub inc {
		my $class = shift;

		return $class->{'db'}->INC(@_);
	};

	sub EXISTS {
		my $class = shift;

		return $class->{'db'}->EXISTS(@_);
	};

	sub FIRSTKEY {
		my $class = shift;

		return $class->{'db'}->FIRSTKEY(@_);
	};

	sub NEXTKEY {
		my $class = shift;

		return $class->{'db'}->NEXTKEY(@_);
	};

	#write methods
	sub STORE {
		my $class = shift;

		return $class->{'db'}->STORE(@_);
	};

	sub DELETE {
		my $class = shift;

		return $class->{'db'}->DELETE(@_);
	};

	sub CLEAR {
		my $class = shift;

		# XXX no error trapping !
		$class->{'db'}->CLEAR(@_);

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

Data::MagicTie::DBMS - This module is used by Data::MagicTie(3) to get a tied remote interface over TCP/IP using DBMS(3) and DB_File(3)

=head1 SYNOPSIS

see DBMS(3) and DB_File(3)

=head1 DESCRIPTION

=head1 SEE ALSO

http://www.sleepycat.com

=head1 AUTHOR

Alberto Reggiori <alberto.reggiori@jrc.it>

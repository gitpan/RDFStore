# DBMS.pm -- Perl 5 interface to DBMS scokets
# $Id: DBMS.pm,v 1.1.1.1 2001/01/18 09:53:21 reggiori Exp $
#
=NAME DBMS

=head1 NAME

DBMS - Perl5 access to the dbms server.

=head1 SYNOPSIS

    use DBMS ;
    $x=tie %hash, 'DBMS', $type,$name;

    # Use the %hash array.
    $hash{ aap } = noot;
    foreach $k (keys(%hash)) {
	print "$k - $hash{ $k }\n";
	};
    # and destroy..
    undef $x;

=head1 DESCRIPTION

B<DBMS> is a module which allows Perl programs to make use of the
facilities provided by the dbms server. The dbms server is a small
server with a bit of glue to the Berkeley DB (> 1.85) and some code
to listen to a few sockets.

=head1 DETAILS

As the devil is in the details... this module supports two
functions which are not part of the normal tie interface; 
atomic counter increment and atomic list retrival.

The increment function increments a counter before it returns
a value. Thus a null or undef value can safely be taken as
an error.

=head2 EXAMPLE

    use DBMS ;
    $x=tie %hash, 'DBMS', $type,$name
	or die "Could not ty to $name: $!";

    $hash{ counter } = 0;

    $my_id = $x->inc( 'counter' )
	or die "Oi";

    # and these are not quite implemented yet..
    # 	
    @keys = $x->keys();
    @values = $x->values();
    @all = $x->hash();

=head1 VERSION

$Id: DBMS.pm,v 1.1.1.1 2001/01/18 09:53:21 reggiori Exp $

=head1 AVAILABILITY

Well, ah hmmm. For ParlEuNet that is, for now that is..

=head1 BUGS

Memory management not fully checked. Some speed issues, I.e. only
about 100 TPS. No proper use of $! and $@, i.e. it will just croak,
carp or return an undef. And there is no automagic retry should you 
loose the connection.

=head1 Author

Blame Dirk-Willem van Gulik <dirkx@webweaving.org> for now. You can send
your postcards and bugfixes to
	
=head1 SEE ALSO

L<perl(1)>, L<DB_File(3)>. 

=cut

package DBMS;

$E_NOSUCHDATABASE = 1011;

use strict;
use vars qw($VERSION @ISA @EXPORT $AUTOLOAD);

require Carp;
require Tie::Hash;
require Exporter;
use AutoLoader;
require DynaLoader;
@ISA = qw(Tie::Hash Exporter DynaLoader);
@EXPORT = qw(
);

$VERSION = "1.00";

sub AUTOLOAD {
    my($constname);
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    Carp::croak("Your vendor has not defined DBMS macro $constname, used");
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap DBMS $VERSION;

# Preloaded methods go here.  Autoload methods go after __END__, and are
# processed by the autosplit program.

1;
__END__

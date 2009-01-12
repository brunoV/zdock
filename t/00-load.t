#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Zdock' );
}

diag( "Testing Zdock $Zdock::VERSION, Perl $], $^X" );

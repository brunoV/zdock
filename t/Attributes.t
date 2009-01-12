use Test::More tests => 1;

{
   package MyClass;
   use Moose;
   with 'Zdock::Attributes';
   
   __PACKAGE__->meta->make_immutable;
}

package main;

my $obj = MyClass->new;

my @methods = qw(zscore rmsd);

can_ok( 'MyClass', @methods );

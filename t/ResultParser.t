use Test::More tests => 3;

{
   package MyClass;
   use Moose;
   with 'Zdock::ResultParser';

   __PACKAGE__->meta->make_immutable;
}

my $parser = MyClass->new;
$parser->scorefile('t/results.txt');

my $results = $parser->parse_zdock_scores;

is( $results->{'complex.1.pdb'}->{rmsd}, '0.000', 'rmsd');
is( $results->{'complex.1.pdb'}->{zscore}, '2059.773', 'zscore');
is( keys %$results, 10, 'Correct number of entries');

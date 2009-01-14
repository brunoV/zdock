#!/usr/bin/perl
use strict;
use warnings;

use Zdock::Clusterer;

my @dirs = qw(
    /home/bruno/fab/r1x/zdocking-runs/run1/decoys/top1000/
    /home/bruno/fab/m1r/zdocking-runs/run1/decoys/top1000/);
my $result_file = 'resultado.txt';
my @range       = ( 5 .. 8 );
my $step        = 3;

foreach my $model (@dirs) {

   print $model, "\n";

   my $clusterer = Zdock::Clusterer->new_with_traits(
      traits            => [qw(Zdock::Clusterer::StatsReport)],
      dir               => $model,
      zdock_result_file => $model . $result_file,
      decoy_files       => "complex.??.pdb",
      chain             => 'H|L',
   );

   for ( my $i = $range[0]; $i <= $range[-1]; $i += $step ) {
      $clusterer->grouping_method( { number => $i } );
      $clusterer->calculate;
      printf( "%d %d %.2f\n",
         $i, $clusterer->cluster_count, $clusterer->error );
      print "Zdock stats:\n";
   }
   $clusterer->print_stats_report(
      description => "This is a test",
   );
}

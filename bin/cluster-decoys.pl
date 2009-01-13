#!/usr/bin/perl
use strict;
use warnings;

use File::Basename;
use Chemistry::MacroMol::MiniPDB;
use Chemistry::Clusterer;
use Data::Dumper;

my $dir = '/home/bruno/fab/r1x/zdocking-runs/run1/decoys/top1000/';
my $result_file = 'resultado.txt';
my $decoy_file  = "*.pdb";

my $clusterer = Chemistry::Clusterer->new_with_traits(
   traits            => [qw(Zdock::ResultParser)],
   zdock_result_file => $dir . $result_file,
);

my @pdbfiles = glob( $dir . $decoy_file );
my $results  = $clusterer->zdock_results;

#my $i = 0;
foreach my $file (@pdbfiles) {
   my $pdb = Chemistry::MacroMol::MiniPDB->new_with_traits(
      traits => [qw(Zdock::Attributes)] );
   $pdb->file($file);
   $pdb->chain('H|L');
   $pdb->zscore( $results->{ basename($file) }->{zscore} );
   $pdb->rmsd( $results->{ basename($file) }->{rmsd} );
   $clusterer->add_structures($pdb);

   #   ++$i;
   #   last if $i > 20;
}
#for ( 1 .. 3 ) {
   for my $i ( 10 .. 20 ) {
      warn $i, "\n";
      $clusterer->grouping_method( { number => 2 * $i } );
      $clusterer->calculate;
      printf( "%d %d %.2f\n",
         2 * $i, scalar @{ $clusterer->clusters },
         $clusterer->error );
   }
#}

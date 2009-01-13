#!/usr/bin/perl
use strict;
use warnings;

use File::Basename;
use Chemistry::MacroMol::MiniPDB;
use Chemistry::Clusterer;
use Data::Dumper;

my $dir = '/home/bruno/fab/r1x/zdocking-runs/run1/decoys/top1000/';
my $result_file   = 'resultado.txt';
my $decoy_file    = "*.pdb";
my @cluster_range = ( 1 .. 2 );
my $step          = 1;
my $chain_regex   = 'H|L';

my $clusterer = Chemistry::Clusterer->new_with_traits(
   traits            => [qw(Zdock::ResultParser)],
   zdock_result_file => $dir . $result_file,
);

my @pdbfiles = glob( $dir . $decoy_file );
my $results  = $clusterer->zdock_results;

foreach my $file (@pdbfiles) {
   my $pdb = Chemistry::MacroMol::MiniPDB->new_with_traits(
      traits => [qw(Zdock::Attributes)] );
   $pdb->file($file);
   $pdb->chain($chain_regex);
   $pdb->zscore( $results->{ basename($file) }->{zscore} );
   $pdb->rmsd( $results->{ basename($file) }->{rmsd} );
   $clusterer->add_structures($pdb);

}

for my $i (@cluster_range) {
   warn $i, "\n";
   my $clus_num = $step * $i;
   $clusterer->grouping_method( { number => $clus_num } );
   $clusterer->calculate;
   printf( "%d %d %.2f\n",
      $clus_num, $clusterer->cluster_count,
      $clusterer->error );
}

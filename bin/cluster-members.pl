#!/usr/bin/perl
use strict;
use warnings;
use Zdock::Clusterer;
use File::Basename;

my $base_dir   = '/home/bruno/fab';
my @models     = ('/r1x', '/m1r');
my $clus_dir   = '/zdocking-runs/run1/clusters';
my $clus_file  = '/n13.dump';

print "Cluster centroids for $clus_file\n";

foreach my $model (@models) {
   print "Model: $model\n";
   my $infile     = $base_dir . $model . $clus_dir . $clus_file;

   my $clusterer = Zdock::Clusterer->load($infile);

   my $i = 1;
   foreach my $cluster ( $clusterer->clusters ) {
      my $centroid = $cluster->centroid;
      print $i, "\t", basename($centroid->file), "\n";
      ++$i;
   }

}

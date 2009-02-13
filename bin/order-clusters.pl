#!/usr/bin/perl
use strict;
use warnings;
use Zdock::Clusterer;
# Order clusters based on some criteria. Now: maximum score.

my $base_dir  = '/home/bruno/fab';
my @models    = ( '/m1r'); #, '/m1r' );
my $clus_dir  = '/zdocking-runs/run1/clusters';

foreach my $model (@models) {
   my @infiles = glob( $base_dir . $model . $clus_dir . "/n13.dump" );

   foreach my $infile (@infiles) {
      my $clusterer;
      eval { $clusterer = Zdock::Clusterer->load($infile) };
      if ($@) { print $infile, "\n"; next };

      # Load the Zscore statistics plugin for each cluster
      foreach my $cluster ( $clusterer->clusters ) {
         unless ( $cluster->can('zscore') ) {
            $cluster->_plugin_app_ns( ['Zdock'] );
            $cluster->_plugin_ns('Cluster');
            $cluster->load_plugin('ZdockStats');
         }
      }

      $clusterer->sort_clusters(
         sub { $_[1]->zscore->max <=> $_[0]->zscore->max } );

      my ($top_cluster) = $clusterer->clusters;
      print $top_cluster->zscore->max, "\n";

      $clusterer->store($infile);
   }

}

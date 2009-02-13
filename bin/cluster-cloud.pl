#!/usr/bin/perl
use strict;
use warnings;
use Zdock::Clusterer;
use Chemistry::MacroMol;
use Chemistry::File::PDB;
use Chemistry::Domain;

my $base_dir   = '/home/bruno/fab';
my @models     = ('/m1r' ); #, '/m1r');
my $clus_dir   = '/zdocking-runs/run1/clusters';
my $clus_file  = '/n13.dump';
my $cloud_file = '/n13.pdb';

foreach my $model (@models) {
   my $infile     = $base_dir . $model . $clus_dir . $clus_file;
   my $outfile    = $base_dir . $model . $clus_dir . $cloud_file;

   my $clusterer = Zdock::Clusterer->load($infile);
   my $big_cloud = Chemistry::Mol->new;

   # Load the Zscore statistics plugin for each cluster
   foreach my $cluster ( $clusterer->clusters ) {
      unless ( $cluster->can('zscore') ) {
         $cluster->_plugin_app_ns( ['Zdock'] );
         $cluster->_plugin_ns('Cluster');
         $cluster->load_plugin('ZdockStats');
      }
   }

   my $Z = 1;
   foreach my $cluster ( $clusterer->clusters ) {
      my $cloud = create_cloud_from_cluster( $cluster, $Z );
      $big_cloud->combine($cloud);
      ++$Z;
   }

   $big_cloud->write($outfile);
}

sub create_cloud_from_cluster {
   my ( $cluster, $Z ) = @_;
   my $cloud = Chemistry::Mol->new;
   foreach my $member ( $cluster->members ) {
      my $struct
          = Chemistry::MacroMol->read( $member->file )->chains('H|L');

      my $centroid = $struct->coords;
      my $atom     = Chemistry::Atom->new(
         Z      => $Z,
         coords => $centroid,
      );
      $cloud->add_atom($atom);
   }
   return $cloud;
}

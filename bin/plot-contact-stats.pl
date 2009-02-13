#!/usr/bin/perl
use strict;
use warnings;

use Storable qw(retrieve);
use PDL;
use PDL::Graphics::PLplot;
use PDL::IO::Storable;
use Carp qw(croak);

my $base_dir = '/home/bruno/fab';
my @models   = ( '/m1r' ); #, '/m1r' );
my $run_dir  = '/zdocking-runs/run1';
my $cmap_dir = '/cmaps';
my $clus_run = 'n13';
my @clus_num = ( '0', '1' );

foreach my $clus_num (@clus_num) {
   foreach my $model (@models) {
      foreach my $chain ( 'l', 'h', ) {
         my $stat_file
             = $clus_run . '-' . $clus_num . '.' . $chain . '.stat';
         my $stats
             = retrieve( $base_dir 
                . $model 
                . $run_dir
                . $cmap_dir . '/'
                . $stat_file );

         foreach my $stat ( keys %$stats ) {
            my $plot_file
                = $base_dir 
                . $model 
                . $run_dir
                . $cmap_dir . '/'
                . $stat . '-'
                . $clus_run . '-'
                . $clus_num . '.'
                . $chain . '.ps';

            my $pl = PDL::Graphics::PLplot->new(
               DEV  => "psc",
               FILE => $plot_file,
            );

            $pl->shadeplot( $stats->{$stat}, 10, PALETTE => 'RAINBOW' );
            $pl->colorkey( $stats->{$stat}, 'v',
               VIEWPORT => [ 0.93, 0.96, 0.125, 0.825 ] );
            $pl->close;

         }
      }
   }
}

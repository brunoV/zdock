#!/usr/bin/perl
use strict;
use warnings;
use lib qw(/home/bruno/lib/Zdock/lib);
use lib qw(/home/bruno/lib/PerlMol/lib);
use Chemistry::ContactMap;
use File::Basename;
use Zdock::Clusterer;
use PDL qw(statsover);
use Storable;
use PDL::IO::Storable;

#use Smart::Comments;

# Where everything is.
my $base_dir = '/home/bruno/fab';
my @models   = ('/m1r');                #, '/m1r' );
my $run_dir  = '/zdocking-runs/run1';
my $clus_dir = '/clusters';
my $cmap_dir = '/cmaps';
my $clus_run = '/n13';
my @clus_num = ( '0', '1' );
my @chains   = ( 'h', 'l' );

foreach my $clus_num (@clus_num) {
   foreach my $model (@models) {
      foreach my $chain (@chains) {
         print $chain, "\n";
         my $outfile
             = $base_dir 
             . $model 
             . $run_dir
             . $cmap_dir
             . $clus_run . '-'
             . $clus_num . '.'
             . $chain . '.stat';

         next if -e $outfile;

         my $clus_file
             = $base_dir 
             . $model 
             . $run_dir
             . $clus_dir
             . $clus_run . '.dump';

         ### Loading clusterer $clus_file
         my $clusterer = Zdock::Clusterer->load($clus_file);
         my @clusters  = $clusterer->clusters;

         my @pdb_files;
         add_from_cluster( \@pdb_files, $chain, $clusters[$clus_num] );
         my @cmap_files = pdb_to_cmap( $model, $chain, @pdb_files );

         my @pdl_cmaps;    # <-- here's where the pdls should go...

         foreach my $file (@cmap_files) {    ### reading cmaps: 0...  100
            ### got: $file
            print $file, "\n";
            my $cmap = Chemistry::ContactMap->read($file);
            my $pdl  = $cmap->_get_PDL;
            push @pdl_cmaps, $pdl;
         }

         my $Cmap = pdl(@pdl_cmaps);

         ### Calculating stats...
         my @stats = statsover( $Cmap->xchg( 2, 0 )->xchg( 1, 2 ) );
         my %stats = (
            mean   => $stats[0],
            prms   => $stats[1],
            median => $stats[2],
            min    => $stats[3],
            max    => $stats[4],
            adev   => $stats[5],
            rms    => $stats[6],
         );    # So many stats!! And for free!

         # Storing in $outfile
         store( \%stats, $outfile );
      }
   }
}

sub add_from_cluster {

   # Add the files of a certain cluster
   # to an array.
   my ( $file_list, $chain, @clusters ) = @_;
   foreach my $cluster (@clusters) {
      foreach my $pdb ( $cluster->members ) {
         push @$file_list, $pdb->file;
      }
   }
}

sub pdb_to_cmap {
   my ( $model, $chain, @file_list ) = @_;
   my @cmap_files;
   foreach my $file (@file_list) {
      my $basename = basename( $file, '.pdb' );
      my $dirname = dirname($file);
      push @cmap_files,
          $base_dir 
          . $model 
          . $run_dir
          . $cmap_dir . '/'
          . $basename . '.'
          . $chain . '.cmap';
   }
   return @cmap_files;
}

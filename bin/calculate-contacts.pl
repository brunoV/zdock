#!/usr/bin/perl
use strict;
use warnings;
use lib qw(/home/bruno/lib/Zdock/lib);
use lib qw(/home/bruno/lib/PerlMol/lib);
use Chemistry::ContactMap::Polyhedra;
use Chemistry::File::PDB;
use Chemistry::MacroMol;
use File::Basename;
use Zdock::Clusterer;
#use Smart::Comments;

# Where everything is.
my $base_dir  = '/home/bruno/fab';
my @models    = ('/m1r'); #( '/r1x', '/m1r' );
my $run_dir   = '/zdocking-runs/run1';
my $decoy_dir = '/decoys/top1000';
my $clus_dir  = '/clusters';
my $cmap_dir  = '/cmaps';

# The unmoveable antigen.
my $ttg = Chemistry::MacroMol->read('/home/bruno/fab/ttg.pdb')->chains('A');

foreach my $model (@models) {

   my $clus_file
       = $base_dir . $model . $run_dir . $clus_dir . '/n13.dump';

   ### Loading file: $clus_file
   my $clusterer = Zdock::Clusterer->load($clus_file);
   my @clusters  = $clusterer->clusters;

   my @pdbfiles;
   add_from_cluster( \@pdbfiles, @clusters[ 0, 1 ] );

   foreach my $file (@pdbfiles) { ### Evaluating...   done 

      my ( $outfile, $complex );
      foreach my $chain ( 'h', 'l' ) {
         $outfile
             = $base_dir 
             . $model 
             . $run_dir
             . $cmap_dir . '/'
             . basename( $file, '.pdb' ) . '.'
             . $chain . '.cmap';

         next if -e $outfile;    # Cmap has already been calculated

         ### Reading structure: $complex
         $complex = Chemistry::MacroMol->read($file) unless ($complex);

         my $fab_chain = $complex->chains($chain);
         my $cmap      = Chemistry::ContactMap::Polyhedra->new;

         $cmap->structures( $ttg, $fab_chain );
         ### Calculating contacts
         $cmap->calculate;
         $cmap->store($outfile);
      }
   }
}

sub add_from_cluster {

   # Add the files of a certain cluster
   # to an array.
   my ( $file_list, @clusters ) = @_;
   foreach my $cluster (@clusters) {
      foreach my $pdb ( $cluster->members ) {
         push @$file_list, $pdb->file;
      }
   }
}

# Beautiful Perl code, that neatly crunches data NOM NOM NOM.

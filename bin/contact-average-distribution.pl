#!/usr/bin/perl
use strict;
use warnings;

use Storable qw(retrieve);
use PDL qw(qsorti);
use PDL::IO::Storable qw();
use Data::Dumper;
use POSIX qw();
use Chemistry::File::PDB;
use Chemistry::MacroMol;
use Chart::Gnuplot;
use List::MoreUtils qw(each_array);

my %aa_table = (
   'ALA' => 'A',
   'ASX' => 'B',
   'CYS' => 'C',
   'ASP' => 'D',
   'GLU' => 'E',
   'PHE' => 'F',
   'GLY' => 'G',
   'HIS' => 'H',
   'ILE' => 'I',
   'LYS' => 'K',
   'LEU' => 'L',
   'MET' => 'M',
   'ASN' => 'N',
   'PRO' => 'P',
   'GLN' => 'Q',
   'ARG' => 'R',
   'SER' => 'S',
   'THR' => 'T',
   'VAL' => 'V',
   'TRP' => 'W',
   'XAA' => 'X',
   'TYR' => 'Y',
   'GLX' => 'Z',
   'TER' => '*',
   'SEL' => 'U'
);

my $base_dir = '/home/bruno/fab';
my @models   = ( 'r1x', 'm1r' );
my $run_dir  = '/zdocking-runs/run1';
my $cmap_dir = '/cmaps';
my $clus_dir = '/clusters';
my $clus_run = 'n13';
my $clus_num = '0';

my $histograms;
   my $fab
       = Chemistry::MacroMol->read( '/home/bruno/fab/' 
          . 'm1r' 
          . '/zdocking-runs/run1/decoys/top1000/complex.1.pdb' );

   my ( $h, $l ) = $fab->chains( 'H', 'L' );
   my %fab = ( 'h' => $h, 'l' => $l );
   my $ttg = Chemistry::MacroMol->read( '/home/bruno/fab/ttg.pdb' );

foreach my $model (@models) {

   # Hay diferencias en la correlación número de residuo-identidad
   # de residuo entre m1r y r1x. Por eso, para obtener la identidad
   # del residuo a partir del número de secuencia, hay que utilizar
   # el modelo correcto.

   foreach my $chain ( 'l', 'h', ) {
      $histograms->{$clus_run}->{$clus_num}->{$model}->{$chain} = [];

      my $stat_file
          = $base_dir . '/' 
          . $model 
          . $run_dir
          . $cmap_dir . '/'
          . $clus_run . '-'
          . $clus_num . '.'
          . $chain . '.stat';

      my $stats = retrieve($stat_file);
      my ( $ttg_pdl, $fab_pdl )
          = get_1d_binding_frequency( $stats->{'mean'} );
      my @ttg       = PDL::Core::list( $ttg_pdl / $ttg_pdl->sumover );
      my @fab       = PDL::Core::list( $fab_pdl / $fab_pdl->sumover );
      print $model, " ", scalar @fab, "\n";
      my @fab_xtics = xtics( $fab{$chain}, \@fab );
      my @ttg_xtics = xtics( $ttg, \@ttg );
      $histograms->{$clus_run}->{$clus_num}->{$model}->{$chain} = {
         ttg_y     => \@ttg,
         ttg_xtics => \@ttg_xtics,
         fab_y     => \@fab,
         fab_xtics => \@fab_xtics,
      };

   }
}

my $chain     = 'h';
my $fab_xtics = $histograms->{$clus_run}->{$clus_num}->{'m1r'}->{$chain}
    ->{'fab_xtics'};
my $fab1
    = $histograms->{$clus_run}->{$clus_num}->{'r1x'}->{$chain}->{'fab_y'};
my $fab2
    = $histograms->{$clus_run}->{$clus_num}->{'m1r'}->{$chain}->{'fab_y'};

my $chart = Chart::Gnuplot->new(
   output => join( '-', ( $clus_run, $clus_num, $chain ) ) . '.eps',
   title  => 'Test',
   xlabel => 'Residue',
   ylabel => 'frequency',
   size   => "1.5, 1",
   xtics  => {
#      font   => "9",
      labels => [ join( ',', @$fab_xtics ) ],
      length => "0, 0",
   },
);

my $dataset1 = Chart::Gnuplot::DataSet->new(
   xdata => [ 0 .. scalar @$fab1 - 1 ],
   ydata => $fab1,
   title => 'r1x',
   style => 'boxes fill solid 1.0 border -1',
);

my $dataset2 = Chart::Gnuplot::DataSet->new(
   xdata => [ 0 .. scalar @$fab2 - 1 ],
   ydata => $fab2,
   title => 'm1r',
   style => 'boxes fill solid 1.0 border -1',
);

$chart->plot2d( $dataset1, $dataset2 );

sub get_1d_binding_frequency {
   my $pdl = shift;

   my $freq_x = $pdl->transpose->sumover;
   my $freq_y = $pdl->sumover;
   return ( $freq_x, $freq_y );
}

sub get_residue_name {
   my ( $mol, $number ) = @_;
   my $residue;
   ($residue)
       = grep { $_->attr('pdb/sequence_number') == $number }
       $mol->domains;
   if ($residue) {
      my ($resn) = $residue->name =~ m/(\D+)/;
      return $aa_table{$resn};
   } else {
      return "-";
   }
}

sub xtics {
   my ( $mol, $list ) = @_;
   my @xtics;
   foreach my $resi ( 0 .. scalar @$list - 1 ) {
      push @xtics, '"' . get_residue_name( $mol, $resi ) . '" ' . $resi;
   }
   return @xtics;
}

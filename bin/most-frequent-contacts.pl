#!/usr/bin/perl
use strict;
use warnings;

# Este script extrae las estadísticas de un mapa de contacto promedio,
# y extrae aquellos contactos que son más frecuentes que un cutoff. Luego
# imprime un informe con los datos de número de residuo y tipo de residuo.
# Itera para todas las corridas de clusters, número de cluster, modelos,
# y cadenas. Y es feo. Muy muy feo.
# Warning: This is a nasty script. It probably needs a lot of refactoring.

use Storable qw(retrieve);
use PDL qw(qsorti);
use PDL::IO::Storable qw();
use Chemistry::File::PDB;
use Chemistry::MacroMol;
use Data::Dumper;
use Text::Report;
use POSIX qw();
use DateTime;

my $base_dir  = '/home/bruno/fab';
my @models    = ( 'r1x', 'm1r' );
my $run_dir   = '/zdocking-runs/run1';
my $cmap_dir  = '/cmaps';
my $clus_dir  = '/clusters';
my $clus_run  = 'n13';
my @clus_nums = ( '0', '1' );

my $contacts;
my $frequency_cutoff = 0.5;
my $fab
    = Chemistry::MacroMol->read( '/home/bruno/fab/' 
       . $model
       . '/zdocking-runs/run1/decoys/top1000/complex.1.pdb' );

my ( $h, $l ) = $fab->chains( 'H', 'L' );
my $ttg = Chemistry::MacroMol->read('/home/bruno/fab/ttg.pdb');
my %fab = ( 'h' => $h, 'l' => $l );


foreach my $model (@models) {
   foreach my $clus_num (@clus_nums) {
      foreach my $chain ( 'l', 'h', ) {
         $contacts->{$clus_run}->{$clus_num}->{$model}->{$chain} = [];

         my $stat_file
             = $base_dir . '/' 
             . $model 
             . $run_dir
             . $cmap_dir . '/'
             . $clus_run . '-'
             . $clus_num . '.'
             . $chain . '.stat';

         my $stats = retrieve($stat_file);
         my @ind   = reverse get_sorted_indices( $stats->{'mean'} );

         foreach my $contact (@ind) {
            my $freq
                = $stats->{'mean'}->at( $contact->[0], $contact->[1] );
            last if $freq < $frequency_cutoff;

            my $res_ttg = get_residue_name( $ttg, $contact->[0] );
            my $res_fab = get_residue_name( $fab{$chain}, $contact->[1] );

            push @{ $contacts->{$clus_run}->{$clus_num}->{$model}->{$chain} },
                {
               ttg  => $res_ttg->name,
               fab  => $res_fab->name,
               freq => $freq,
                };
         }
      }
   }
}

print_report($contacts);

sub get_sorted_indices {

   # Return
   my $pdl = shift;
   die "This is not a PDL\n" unless ref $pdl eq 'PDL';
   my ( $nx, $ny ) = $pdl->dims;
   my $ind_1d = qsorti( $pdl->clump(-1) );
   my @ind_1d = PDL::Core::list($ind_1d);
   my @ind_2d;
   foreach my $i (@ind_1d) {
      push @ind_2d,
          [ n_to_coords( $i, $nx, ( 'x' => -1, 'y' => -1, 'n' => -1 ) ) ];
   }
   return @ind_2d;
}

sub n_to_coords {

   # get the coordinates of the nth element (counting left-right
   # top-bottom) of a grid of size $nx.

   my ( $n, $nx, %offset ) = @_;

   unless (%offset) {
      %offset = ( x => 0, y => 0, n => 0 );
   }

   $n -= $offset{'n'};
   my $y = POSIX::ceil( $n / $nx );
   my $x;
   if   ( $n % $nx == 0 ) { $x = $nx }
   else                   { $x = $n % $nx }
   $y += $offset{'y'};
   $x += $offset{'x'};
   return ( $x, $y );
}

sub get_residue_name {
   my ( $mol, $number ) = @_;
   my $residue;
   ($residue)
       = grep { $_->attr('pdb/sequence_number') == $number }
       $mol->domains;
   return $residue;
}

sub print_report {
   my ( $data, %args ) = @_;
   my $rpt = Text::Report->new( debug => 'error', debugv => 1 );

   # Title Block.
   $rpt->defblock( name => 'title_lines' );
   my $title = $args{'title'}
       || "Contact Analysis\nMost frequent residue-residue contacts";
   my @title_lines = map { [$_] } split( "\n", $title );
   $rpt->fill_block( 'title_lines', @title_lines );
   $rpt->insert('dbl_line');

   foreach my $clusterer ( keys %{$data} ) {
      foreach my $cluster ( keys %{ $data->{$clusterer} } ) {
         foreach my $model ( keys %{ $data->{$clusterer}->{$cluster} } ) {

            # Summary Block.
            # define the block
            $rpt->defblock(
               name        => $clusterer . $cluster . $model . 'summary',
               title       => "Cluster $clusterer",
               columnWidth => 15,
               columnAlign => 'left',
            );
            $rpt->setcol( $clusterer . $cluster . $model . 'summary',
               2, width => 70 );

            # set the headers.
            for ( 1 .. 2 ) {
               $rpt->setcol( $clusterer . $cluster . $model . 'summary',
                  $_ );
            }

            # define and set the data.
            my @desc = (
               [ 'Date:',           DateTime->now->dmy("/") ],
               [ 'Cluster run:',    $clusterer ],
               [ 'Cluster number:', $cluster ],
               [ 'Model:',          $model ],
            );
            $rpt->fill_block( $clusterer . $cluster . $model . 'summary',
               @desc );

            # Contacts Block.
            $rpt->defblock(
               name  => $clusterer . $cluster . $model . 'contacts',
               title => 'Most frequent Contacts',
               useColHeaders => 1,
               sortby        => 1,
               sorttype      => 'numeric',
               orderby       => 'descending',
               columnWidth   => 7,
               columnAlign   => 'left',
               pad           => { top => 2, bottom => 2 },
            );
            my @headers = qw( freq ttg fab );
            my $i       = 0;
            for (@headers) {
               $rpt->setcol( $clusterer . $cluster . $model . 'contacts',
                  ++$i, head => $_ );
            }

            my @lines;
            foreach my $chain (
               keys %{ $data->{$clusterer}->{$cluster}->{$model} } )
            {
               foreach my $contact (
                  @{ $data->{$clusterer}->{$cluster}->{$model}->{$chain} }
                   )
               {
                  push @lines,
                      [
                     $contact->{'freq'},
                     $contact->{'ttg'},
                     $chain . '-' . $contact->{'fab'},
                      ];
               }
            }
            $rpt->fill_block( $clusterer . $cluster . $model . 'contacts',
               @lines );
         }
      }
   }

   my @report = $rpt->report('get');
   print $_, "\n" for @report;
}

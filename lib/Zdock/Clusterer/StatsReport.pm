package Zdock::Clusterer::StatsReport;
use strict;
use warnings;
use Moose::Role;
use Text::Report;
use DateTime;
use Carp qw(croak);

sub print_stats_report {
   my ( $self, %args ) = @_;
   my $rpt = Text::Report->new( debug => 'error', debugv => 1 );

   # Title Block.
   $rpt->defblock( name => 'title_lines' );
   my $title = $args{'title'} || "Decoy Clustering\nZscore Statistics";
   my @title_lines = map { [$_] } split( "\n", $title );
   $rpt->fill_block( 'title_lines', @title_lines );
   $rpt->insert('dbl_line');

   # Summary Block.
   #    define the block
   $rpt->defblock(
      name        => 'summary',
      title       => 'Summary',
      columnWidth => 15,
      columnAlign => 'left',
   );
   $rpt->setcol( 'summary', 2, width => 70 );

   #    set the headers.
   for ( 1 .. 2 ) { $rpt->setcol( 'summary', $_ ); }

   #    define and set the data.
   my @desc = (
      [ 'Date:',           DateTime->now->dmy("/") ],
      [ 'Directory:',      $self->dir ],
      [ 'N. of decoys:',   $self->structure_count ],
      [ 'N. of clusters:', $self->cluster_count ],
      [ 'Error:', substr( $self->error, 0, 4 ) ],
   );
   if ( $args{'description'} ) {
      unshift @desc, [ 'Description:', $args{'description'} ];
   }
   $rpt->fill_block( 'summary', @desc );

   # Statistics Block.
   #    define the block
   $rpt->defblock(
      name          => 'stats',
      title         => 'Statistical Analysis of Decoy Clustering',
      useColHeaders => 1,
      sortby        => 3,
      sorttype      => 'numeric',
      orderby       => 'descending',
      columnWidth   => 6,
      columnAlign   => 'left',
      pad           => { top => 2, bottom => 2 },
   );
   $rpt->setcol( 'stats', 1, align => 'left', width => 9 );

   #    name and add the headers
   my @header = qw(cluster_n size max min avg median stddev);
   my $i      = 0;
   for (@header) { $rpt->setcol( 'stats', ++$i, head => $_ ); }

   #    define and set the data
   $rpt->fill_block( 'stats', @{ $self->_get_cluster_stats_array } );

   # Create a separator:
   $rpt->insert('dotted_line');

   # Create a footer block:
   $rpt->defblock( name => 'footer' );

   $rpt->fill_block( 'footer',
      ['This report was automatically created by the Zdock module'],
      ['Author: Bruno Vecchi'] );

   # Define where the report should be written to.
   my $fh;
   my $file = $args{'file'};
   if ($file) {
      if ( -e $file ) { croak "File already exists!\n" }
      open( $fh, '>', $file )
          or croak "Couldn't open $file for writing: $!\n";
   } else {
      $fh = \*STDOUT;
   }

   # Get our formatted report:
   my @report;
   if ( defined $args{'format'} && $args{'format'} eq 'csv' ) {
      @report = $rpt->report('csv');
      {
         local $, = "\n";
         print $fh @{$_}, "\n" for @report;
      }
   } else {
      @report = $rpt->report('get');
      print $fh $_, "\n" for @report;
   }
}

sub _get_cluster_stats_array {

   # This method returns an arrayref
   # with the basic stats for each cluster,
   # in a way that can be easily fed to the
   # report generator.

   my $self = shift;
   my @data;
   my $i = 1;
   foreach my $cluster ( $self->clusters ) {

      # If the clusters haven't loaded the stats
      # plugin, do it.
      unless ($cluster->can('zscore')) {
         $cluster->_plugin_app_ns( ['Zdock'] );
         $cluster->_plugin_ns('Cluster');
         $cluster->load_plugin('ZdockStats');
      }

      push @data,
          [
         $i,                     $cluster->size,
         $cluster->zscore->max,  $cluster->zscore->min,
         $cluster->zscore->mean, $cluster->zscore->median,
         $cluster->zscore->standard_deviation,
          ];
      ++$i;
   }
   return \@data;
}

no Moose;
1;

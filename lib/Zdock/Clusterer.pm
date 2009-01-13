package Zdock::Clusterer;
use Moose;
use Carp qw(croak);
use File::Basename;
use Chemistry::MacroMol::MiniPDB;
use Statistics::Descriptive;
extends 'Chemistry::Clusterer';
with 'Zdock::ResultParser';

has dir => (
   is       => 'rw',
   isa      => 'Str',
   required => 1,
   trigger  => sub { (shift)->_load_pdbs() },
);

has decoy_files => (
   is      => 'rw',
   isa     => 'Str',
   default => '*.pdb',
);

has chain => (
   is      => 'rw',
   isa     => 'Str',
   default => '\w',
);

sub _load_pdbs {

   my $self     = shift;
   my $results  = $self->zdock_results;
   my @pdbfiles = glob( $self->dir . $self->decoy_files );
   croak "There are no structure files in ", $self->dir, "\n"
       unless @pdbfiles;

   foreach my $file (@pdbfiles) {
      my $pdb = Chemistry::MacroMol::MiniPDB->new_with_traits(
         traits => [qw(Zdock::Attributes)] );
      $pdb->file($file);
      $pdb->chain( $self->chain );
      $pdb->zscore( $results->{ basename($file) }->{zscore} );
      $pdb->rmsd( $results->{ basename($file) }->{rmsd} );
      $self->add_structures($pdb);
   }
}

after 'calculate' => sub {
   my $self = shift;

   # I made Clusters pluggable so that they can have zdock-y
   # attributes after being blessed. Neat-oh!
   foreach my $cluster ( $self->clusters ) {

      # We tell the plugin loader where to look for the plugin.
      $cluster->_plugin_app_ns( ['Zdock'] );    # (Zdock/)
      $cluster->_plugin_ns('Cluster');        # (Zdock/Cluster)
      $cluster->load_plugin('ZdockStats');    # (Zdock/Cluster/ZdockStats)
   }
};

no Moose;
1;

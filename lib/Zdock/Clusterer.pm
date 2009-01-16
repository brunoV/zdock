package Zdock::Clusterer;
use Moose;
use Carp qw(croak);
use File::Basename;
use lib qw(/home/bruno/lib/Zdock/lib);
use lib qw(/home/bruno/lib/PerlMol/lib);
use Zdock::MiniPDB;
extends 'Chemistry::Clusterer';
my @roles = qw(
   Zdock::ResultParser
   Zdock::Clusterer::StatsReport 
   MooseX::Traits);
with @roles;

has dir => (
   is       => 'ro',
   isa      => 'Str',
   required => 1,
   trigger  => sub {
      $_[0]->_load_pdbs() unless $_[0]->structure_count > 0;
   },
   # This prevents reloading the structs when retrieving the object
   # from a file.
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
      my $pdb = Zdock::MiniPDB->new();
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
#
before 'store' => sub {
   map { bless $_, 'Chemistry::Cluster' } (shift)->clusters;
};

no Moose;
1;

#!/usr/bin/perl
use strict;
use warnings;
use lib qw(/home/bruno/lib/Zdock/lib);
use lib qw(/home/bruno/lib/PerlMol/lib);
use Zdock::Clusterer;

my $base_dir    = '/home/bruno/fab/';
my $decoy_dir   = '/zdocking-runs/run1/decoys/top1000/';
my $cluster_dir = '/zdocking-runs/run1/clusters/';
my $result_file = 'resultado.txt';
my $n_cluster   = 13;
my @models      = ( 'm1r' ); #, 'm1r' );

foreach my $model (@models) {

   my $clusterer = Zdock::Clusterer->new(
      dir               => $base_dir . $model . $decoy_dir,
      zdock_result_file => $base_dir . $model . $decoy_dir . $result_file,
      decoy_files       => "complex.*.pdb",
      grouping_method   => { number => $n_cluster },
      chain             => 'H|L',
   );

   $clusterer->calculate;

   $clusterer->print_stats_report( file => $base_dir
   . $model       . $cluster_dir . 'report-n'
   . $n_cluster   . '.txt' );
   $clusterer->store(
      $base_dir . $model . $cluster_dir . 'n' . $n_cluster . '.dump' );
}

# We know what's in butter rhum.

# Ok, so it works with the basic Zdock::Clusterer subclassing:
# no ResultParser, no MiniPDB with ZdockAttributes, no Clusters
# with statistics.

# It also works applying role 'Zdock::ResultParser' to Zdock::Clusterer.

# It doesn't work when Z::Clusterer creates MiniPDB with traits to apply
# the Z::Atribute role and then insert those objects into Z::Clusterer.

# It is fixed though, by subclassing C::M::MiniPDB as Z::MiniPDB with
# the role Z::Attributes;
#
# Now, it fails again when I try to load the plugin Z::C::ZdockStats
# to every Cluster object.
#
# It is fixed if, before storing $clusterer, I bless every cluster
# as Chemistry::Cluster.
# After retrieving, the plugin is obviously not loaded, so if the
# statistics of a cluster are still wanted, one should have to reload
# it. What is a real PITA is the fact that one has to assign _plugin_app_ns
# and _plugin_ns to ['Zdock'] and 'Cluster' respectively; otherwise
# it will look the plugin under Chemistry/Cluster/Plugins instead of
# Zdock/Cluster.
#
# It also works adding StatsReport, but it doesn's seem to remember
# having the role applied after retrieving it from storage.
# And if I consume the role when defining Z::Clusterer, it gives
# an error when loading the object from storage saying that the
# cluster object doesn't have the "zscore" attribute. This of course
# is true, since I haven't loaded the plugin yet. but I can't help it.
# Now, I added an extra check to the role Z::Clusterer::ReportStats:
# when its only allowed method it's called, it checks that it's clusters
# have the plugin loaded. If they don't it loads them.
# Now the only rough case that remains is if you want to access a
# cluster's stats after retrieving the clusterer from storage. In this
# case you'll have to reload the plugins first. It's solveable.

package Zdock::Cluster::ZdockStats;
use Moose::Role;
use Statistics::Descriptive;
use MooseX::Storage;
with Storage( 'format' => 'Storable', 'io' => 'File' );

has 'zscore' => (
   is => 'rw',
   lazy_build => 1,
);

sub _build_zscore {
   my $self = shift;
   my $stats = Statistics::Descriptive::Full->new;
   my @data = map { $_->zscore } $self->members;
   $stats->add_data(@data);
   $self->zscore($stats);
}

no Moose;
1;

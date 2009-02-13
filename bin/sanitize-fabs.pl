#!/usr/bin/perl
use strict;
use warnings;

use Chemistry::File::PDB;
use Chemistry::MacroMol;

my $base_dir  = '/home/bruno/fab/';
my $decoy_dir = '/zdocking-runs/run1/decoys/top1000';
my $ttg       = Chemistry::MacroMol->read(
   $base_dir . 'm1r' . $decoy_dir . '/complex.1.pdb' )->chains('A');

foreach my $n ( 1 .. 1000 ) {
   my $r1x = Chemistry::MacroMol->read(
      $base_dir . 'r1x' . $decoy_dir . '/complex.' . $n . '.pdb' );

   my $m1r = Chemistry::MacroMol->read(
      $base_dir . 'm1r' . $decoy_dir . '/complex.' . $n . '.pdb' );

   # Cadena pesada: sacarle el primero a m1r
   #                 sacarle los últimos dos a r1x
   # Cadena liviana: sacarle el primero a m1r
   #                 sacarle los últimos tres a m1r

   my ( $h_m1r, $l_m1r ) = $m1r->chains( 'H', 'L' );
   my ( $h_r1x, $l_r1x ) = $r1x->chains( 'H', 'L' );

   my @h_m1r_res = $h_m1r->domains;
   my @l_m1r_res = $l_m1r->domains;
   my @h_r1x_res = $h_r1x->domains;
   my @l_r1x_res = $l_r1x->domains;

   shift @h_m1r_res;
   pop @h_r1x_res;
   pop @h_r1x_res;
   pop @h_r1x_res;

   shift @l_m1r_res;
   pop @l_m1r_res;
   pop @l_m1r_res;
   pop @l_m1r_res;

   reorder( \@h_m1r_res );
   reorder( \@l_m1r_res );
   reorder( \@h_r1x_res );
   reorder( \@l_r1x_res );

   my $new_m1r = Chemistry::MacroMol->new;
   map { $new_m1r->add_domain($_) }
       ( $ttg->domains, @h_m1r_res, @l_m1r_res );
   foreach my $residue ( $ttg->domains, @h_m1r_res, @l_m1r_res ) {
      foreach my $atom ( $residue->atoms ) {
         $new_m1r->add_atom($atom);
      }
   }

   my $new_r1x = Chemistry::MacroMol->new;
   map { $new_r1x->add_domain($_) }
       ( $ttg->domains, @h_r1x_res, @l_r1x_res );
   foreach my $residue ( $ttg->domains, @h_r1x_res, @l_r1x_res ) {
      foreach my $atom ( $residue->atoms ) {
         $new_r1x->add_atom($atom);
      }
   }

   warn $base_dir . 'm1r' . $decoy_dir . '/complex.' . $n . '.pdb', "\n";
   warn $base_dir . 'r1x' . $decoy_dir . '/complex.' . $n . '.pdb', "\n";

   $new_m1r->write(
      $base_dir . 'm1r' . $decoy_dir . '/complex.' . $n . '.pdb' );
   $new_r1x->write(
      $base_dir . 'r1x' . $decoy_dir . '/complex.' . $n . '.pdb' );
   ++$n;
}

sub reorder {
   my $residues = shift;
   my $i        = 1;
   foreach my $res (@$residues) {
      $res->{attr}->{'pdb/sequence_number'} = $i;
      ++$i;
   }
   return @$residues;
}


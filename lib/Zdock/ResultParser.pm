package Zdock::ResultParser;
use Moose::Role;
use Text::CSV::Simple;

=head1 NAME

Zdock::ResultParser - A Role to parse Zdock run results.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

   package MyClass;
   use Moose;
   with 'Zdock::ResultParser';

   package main;
   my $parser = MyClass->new( zdock_result_file => '/some/file' )
   my $zdocking_scores = $parser->zdock_results;


=head1 ATTRIBUTES

=head2 zdock_result_file

The name of the file that contains the zdock run information. This file
should have three fields separated by tabs. The fields are: decoy name,
decoy RMSD, and zdock score.

=cut

has delimiter => (
   is      => 'rw',
   isa     => 'Str',
   default => "\t",
);

has zdock_result_file => (
   is       => 'rw',
   isa      => 'Str',
   required => 1,
);

=head2 zdock_results

returns a hashref keyed by decoy name.
This hash allows to access each decoys's run information easily:

   my $scores = $parser->zdock_results;

   $scores->{'complex.23.pdb'}->{rmsd}; 
   $scores->{'complex.23.pdb'}->{zscore};

=cut

has zdock_results => (
   is      => 'ro',
   isa     => 'HashRef',
   lazy    => 1,
   builder => '_parse_zdock_result_file',
);

sub _parse_zdock_result_file {

   # Takes a zdock result file as argument,
   # returns a hash keyed by decoy name.
   my $self         = shift;
   my $zdock_parser = Text::CSV::Simple->new(
      {  sep_char         => $self->delimiter,
         allow_whitespace => 1,
      }
   );
   $zdock_parser->field_map(qw(file rmsd zscore));
   my @data = $zdock_parser->read_file( $self->zdock_result_file );
   my %data
       = map { $_->{file}, { rmsd => $_->{rmsd}, zscore => $_->{zscore} } }
       @data;
   return \%data;
}

=head1 AUTHOR

Bruno Vecchi, C<< <vecchi.b at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zdock at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Zdock>.  I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Zdock::ResultParser


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Zdock>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Zdock>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Zdock>

=item * Search CPAN

L<http://search.cpan.org/dist/Zdock/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Bruno Vecchi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Zdock::ResultParser

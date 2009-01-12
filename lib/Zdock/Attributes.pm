package Zdock::Attributes;
use strict;
use warnings;
use Moose::Role;

=head1 NAME

Zdock::Attributes - Typical attributes of a Zdock run.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS
package MyClass;
use Moose;
with 'Zdock::Attributes';

package main;

my $obj->MyClass->new;

$obj->zscore('123.43');
$obj->rmsd('0.65');

=head1 Attributes

=head2 zscore

Gets or sets the zscore, a number representing the docking score of a
zdock run.

=cut

has zscore => (
   is => 'rw',
   isa => 'Num',
);

=head2 rmsd

Gets or sets the RMSD (Root Mean Square Deviation).

=cut

has rmsd => (
   is => 'rw',
   isa => 'Num',
);

=head1 AUTHOR

Bruno Vecchi, C<< <vecchi.b at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zdock at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Zdock>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Zdock::Attributes


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

1; # End of Zdock::Attributes

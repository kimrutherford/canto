package PomCur::Hooks::SessionAccepted;

=head1 NAME

PomCur::Hooks::SessionAccepted - Possibly hooks to run when a session is
                                 accepted - configured in pomcur.yaml

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PomCur::Hooks::SessionAccepted

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

use Moose;
use Carp;

=head2 set_pub_community_curatable

 Function: Called from CuratorManager::accept_session() after a session is
           accepted
 Args    : $config - the Config object
           $curs - the Curs that was just accepted
           $curator - the Person who did the accepting
 Return  : Nothing

=cut

sub set_pub_community_curatable
{
  my $config = shift;
  my $track_schema = shift;
  my $curs = shift;
  my $curator = shift;

  my $role = $curator->role();

  if (!defined $role || $role->name() ne 'admin') {
    $curs->pub()->set_community_curatable();
  }
}

1;

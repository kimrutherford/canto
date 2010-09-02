package PomCur::TrackDB::Person;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("person");
__PACKAGE__->add_columns(
  "person_id",
  {
    data_type => "integer",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "networkaddress",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "role",
  {
    data_type => "integer",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "lab",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "session_data",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "password",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("person_id");
__PACKAGE__->add_unique_constraint("networkaddress_unique", ["networkaddress"]);
__PACKAGE__->has_many(
  "pub_statuses",
  "PomCur::TrackDB::PubStatus",
  { "foreign.assigned_curator" => "self.person_id" },
);
__PACKAGE__->belongs_to("role", "PomCur::TrackDB::Cvterm", { cvterm_id => "role" });
__PACKAGE__->belongs_to("lab", "PomCur::TrackDB::Lab", { lab_id => "lab" });
__PACKAGE__->has_many(
  "curs",
  "PomCur::TrackDB::Curs",
  { "foreign.community_curator" => "self.person_id" },
);
__PACKAGE__->has_many(
  "labs",
  "PomCur::TrackDB::Lab",
  { "foreign.lab_head" => "self.person_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dc1vm3/l6i45KLKtb9wLDw

=head2

 Usage   : my $pub_status = $pub->pub_status();
 Function: Return the PubStatus object for this publication.
           DBIx::Class::Schema::Loader has created pub_statuses() for us,
           but the constraints on the pub_status.pub column mean there can be
           only one PubStatus per Pub
 Args    : None
 Return  : The PubStatus object

=cut
sub pub_status
{
  my $self = shift;

  return ($self->pub_statuses())[0];
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;

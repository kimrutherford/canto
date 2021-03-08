use utf8;
package Canto::CursDB::SymmetricGenotypeInteraction;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Canto::CursDB::SymmetricGenotypeInteraction

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<symmetric_genotype_interaction>

=cut

__PACKAGE__->table("symmetric_genotype_interaction");

=head1 ACCESSORS

=head2 asymmetric_genotype_interaction_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 interaction_type

  data_type: 'text'
  is_nullable: 0

=head2 primary_annotation_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "asymmetric_genotype_interaction_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "interaction_type",
  { data_type => "text", is_nullable => 0 },
  "primary_annotation_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</asymmetric_genotype_interaction_id>

=back

=cut

__PACKAGE__->set_primary_key("asymmetric_genotype_interaction_id");

=head1 RELATIONS

=head2 primary_annotation

Type: belongs_to

Related object: L<Canto::CursDB::GenotypeAnnotation>

=cut

__PACKAGE__->belongs_to(
  "primary_annotation",
  "Canto::CursDB::GenotypeAnnotation",
  { genotype_annotation_id => "primary_annotation_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-04-07 17:02:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lHHcQhEpW+7d+vic38ggZw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;

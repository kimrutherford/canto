package Canto::Controller::Service;

=head1 NAME

Canto::Controller::Service - Web service implementations

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Canto::Controller::Service

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009-2013 University of Cambridge, all rights reserved.

Canto is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 FUNCTIONS

=cut

use strict;
use warnings;
use Carp;

use feature ':5.10';

use base 'Catalyst::Controller';

use Canto::Track;

__PACKAGE__->config->{namespace} = 'ws';

sub _ontology_results
{
  my ($c, $arg1, $arg2) = @_;

  my ($component_name, $search_string);

  if ($c->req()->param('term')) {
    $component_name = $arg1;
    $search_string = $c->req()->param('term');
  } else {
    if (defined $arg2) {
      $component_name = $arg1;
      $search_string = $arg2;
    } else {
      # lookup by id, no ontology needed
      $search_string = $arg1;
    }
  }

  my $config = $c->config();
  my $lookup = Canto::Track::get_adaptor($config, 'ontology');

  my $max_results = $c->req()->param('max_results') || 15;

  my $ontology_name;

  if (defined $component_name &&
      defined (my $component_config =
                 $config->{annotation_types}->{$component_name})) {
    $ontology_name = $component_config->{namespace};
  } else {
    # allow looking up using the ontology name for those ontologies
    # that aren't configured as annotation types
    $ontology_name = $component_name;
  }

  my $include_definition = $c->req()->param('def');
  my $include_children = $c->req()->param('children');
  my @include_synonyms = $c->req()->param('synonyms');
  my $include_subset_ids = $c->req()->param('subset_ids');

  # we're looking up the range of an extension
  my $extension_lookup = $c->req()->param('extension_lookup') // 0;

  my $config_subsets_to_ignore =
    $config->{ontology_namespace_config}{subsets_to_ignore};

  my @exclude_subsets = ();

  if ($config_subsets_to_ignore) {
    if ($extension_lookup) {
      push @exclude_subsets, @{$config_subsets_to_ignore->{extension}};
    } else {

      if ($search_string eq ':ALL:') {
        push @exclude_subsets, @{$config_subsets_to_ignore->{primary_select}};
      } else {
        push @exclude_subsets, @{$config_subsets_to_ignore->{primary_autocomplete}};
      }
    }
  }

  if (defined $component_name) {
    if ($search_string eq ':COUNT:') {
      return { count => $lookup->get_count(ontology_name => $ontology_name,
                                           exclude_subsets => \@exclude_subsets) };
    } else {
      my @results;
      $search_string =~ s/^\s+//;
      $search_string =~ s/\s+$//;

      if ($search_string eq ':ALL:') {
        @results =
          $lookup->get_all(ontology_name => $ontology_name,
                           include_definition => $include_definition,
                           include_children => $include_children,
                           include_synonyms => \@include_synonyms,
                           include_subset_ids => $include_subset_ids,
                           exclude_subsets => \@exclude_subsets);
      } else {
        if (length $search_string == 0) {
          return [];
        }

        @results =
          @{$lookup->lookup(ontology_name => $ontology_name,
                            search_string => $search_string,
                            max_results => $max_results,
                            include_definition => $include_definition,
                            include_children => $include_children,
                            include_synonyms => \@include_synonyms,
                            include_subset_ids => $include_subset_ids,
                            exclude_subsets => \@exclude_subsets)};
      }

      map { $_->{value} = $_->{name} } @results;

      return \@results;
    }
  } else {
    $search_string =~ s/^\s+//;
    $search_string =~ s/\s+$//;

    my $result =
      $lookup->lookup_by_id(id => $search_string,
                            include_definition => $include_definition,
                            include_children => $include_children,
                            include_synonyms => \@include_synonyms,
                            include_subset_ids => $include_subset_ids);

    return $result;
  }
}

sub _gene_results
{
  my ($c, $search_string) = @_;

  my $config = $c->config();

  my $adaptor = Canto::Track::get_adaptor($config, 'gene');

  my $result;

  if (exists $config->{instance_organism}) {
    $result = $adaptor->lookup(
      {
        search_organism => {
          scientific_name => $config->{instance_organism}->{scientific_name},
        }
      },
      [$search_string]);
  } else {
    $result = $adaptor->lookup([$search_string]);
  }

  return $result;
}

sub _allele_results
{
  my ($c, $gene_primary_identifier, $search_string) = @_;

  $gene_primary_identifier ||= $c->req()->param('gene_primary_identifier');
  $search_string ||= $c->req()->param('term');
  my $ignore_case = $c->req()->param('ignore_case') // 0;

  if (lc $ignore_case eq 'false') {
    $ignore_case = 0;
  }

  my $config = $c->config();
  my $lookup = Canto::Track::get_adaptor($config, 'allele');

  if (!defined $lookup) {
    return [];
  }

  my $max_results = $c->req()->param('max_results') || 10;

  return $lookup->lookup(gene_primary_identifier => $gene_primary_identifier,
                         search_string => $search_string,
                         ignore_case => $ignore_case,
                         max_results => $max_results);
}

# provide /ws/person/name/Some%20Name => [{ details }, { details}] and
# /ws/person/email/some@emailaddress.com => { details }
sub _person_results
{
  my ($c, $search_type, $search_string) = @_;

  my $config = $c->config();

  my $lookup = Canto::Track::get_adaptor($config, 'person');

  my @results = $lookup->lookup($search_type, $search_string);

  if ($search_type eq 'name') {
    return \@results;
  } else {
    return $results[0];
  }
}

sub _pubs_results
{
  my ($c, $search_type, $search_string) = @_;

  my $lookup = Canto::Track::get_adaptor($c->config(), 'pubs');

  if ($search_type eq 'by_curator_email') {
    my $data = $lookup->lookup_by_curator_email($search_string, -1);

    return {
      pub_results => $data->{results},
      count => $data->{count},
      status => 'success',
    };
  } else {
    return { message => "Unknown search type: $search_type",
             status => 'error' };
  }
}

sub _strain_lookup
{
  my ($c, $taxonid) = @_;

  my $strain_lookup = Canto::Track::get_adaptor($c->config(), 'strain');

  return [$strain_lookup->lookup($taxonid)];
}

sub lookup : Local
{
  my $self = shift;
  my $c = shift;
  my $type_name = shift;

  my $results;

  my %dispatch = (
    gene => \&_gene_results,
    allele => \&_allele_results,
    ontology => \&_ontology_results,
    person => \&_person_results,
    pubs => \&_pubs_results,
    strains => \&_strain_lookup,
    organisms => \&_organism_lookup,
  );

  my $res_sub = $dispatch{$type_name};

  if (defined $res_sub) {
    $results = $res_sub->($c, @_);
  } else {
    $results = { error => "unknown lookup type: $type_name" };
  }

  if (defined $results) {
    $c->stash->{json_data} = $results;
  } else {
    $c->stash->{json_data} = {
      error => 'No results',
    };
  }

  # FIXME - this is a bit dodgy
  $c->cache_page(100) unless $ENV{CANTO_DEBUG};

  $c->forward('View::JSON');
}

sub _organism_lookup
{
  my ($c, $type) = @_;

  my $organism_lookup = Canto::Track::get_adaptor($c->config(), 'organism');

  return [$organism_lookup->lookup_by_type($type)];
}

sub details : Local
{
  my $self = shift;
  my $c = shift;
  my $key = shift;

  if ($key eq 'user') {
    # get logged in user
    my $email = undef;
    my $name = undef;
    my $known_as = undef;
    my $is_admin = undef;

    if ($c->user()) {
      my $user = $c->user();
      $email = $user->email_address();
      $name = $user->name();
      $known_as = $user->known_as();
      $is_admin = $user->is_admin() ? JSON::true : JSON::false;
    }

    $c->stash->{json_data} = {
      status => 'success',
      details => {
        email => $email,
        name => $name,
        known_as => $known_as,
        is_admin => $is_admin,
      }
    };
  } else {
    $c->stash->{json_data} = {
      status => 'error',
      message => qq(unknown detail type "$key"),
    };
  }

  $c->forward('View::JSON');
}

sub canto_config : Local
{
  my $self = shift;
  my $c = shift;
  my $config_key = shift;

  my $config = $c->config();

  my $allowed_keys = $config->{config_service}->{allowed_keys};

  if ($allowed_keys->{$config_key}) {
    my $key_config = $config->for_json($config_key);
    if (defined $key_config) {
      if ($config_key eq 'annotation_type_list') {
        map {
          if ($_->{admin_evidence_codes} && $_->{evidence_codes}) {

            if ($c->user()) {
              my $user = $c->user();
              my $is_admin = $user->is_admin() ? JSON::true : JSON::false;

              if ($is_admin) {
                push @{$_->{evidence_codes}}, @{$_->{admin_evidence_codes}};
              }
            }
          }
        } @$key_config;
      }

      if (ref $key_config) {
        $c->stash->{json_data} = $key_config;
      } else {
        $c->stash->{json_data} = {
          value => $key_config,
        };
      }

      # FIXME - the URL for canto_config should have a version number so
      # we can have a far future expiry date
      $c->cache_page(120) unless $ENV{CANTO_DEBUG};
    } else {
      $c->stash->{json_data} = {};
    }
  } else {
    $c->stash->{json_data} = {
      status => 'error',
      message => qq(config key "$config_key" not allowed for this service),
    };
    $c->response->status(403);
  }

  $c->forward('View::JSON');
}

1;

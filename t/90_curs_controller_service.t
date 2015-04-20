use strict;
use warnings;
use Test::More tests => 4;
use Test::Deep;

use Plack::Test;
use Plack::Util;
use HTTP::Request;

use Canto::TestUtil;

use JSON;

my $test_util = Canto::TestUtil->new();
$test_util->init_test('curs_annotations_2');

my $config = $test_util->config();
my $app = $test_util->plack_app()->{app};

my $curs_key = 'aaaa0007';
my $curs_schema = Canto::Curs::get_schema_for_key($config, $curs_key);

my $root_url = "http://localhost:5000/curs/$curs_key";

my $first_genotype =
 $curs_schema->resultset('Genotype')->find({ identifier => 'aaaa0007-genotype-test-1' });

my $first_genotype_annotation = $first_genotype->annotations()->first();

my $first_genotype_annotation_id = $first_genotype_annotation->annotation_id();
my $first_genotype_id = $first_genotype->genotype_id();

test_psgi $app, sub {
  my $cb = shift;

  my $uri = new URI("$root_url/ws/annotation/$first_genotype_annotation_id/new/change");

  my $req = HTTP::Request->new(POST => $uri);
  $req->header('Content-Type' => 'application/json');
  my $new_comment = "new service comment";
  my $changes = {
    key => $curs_key,
    submitter_comment => $new_comment,
  };

  ok(!defined($first_genotype_annotation->data()->{submitter_comment}));

  $req->content(to_json($changes));

  my $res = $cb->($req);

  my $perl_res = decode_json $res->content();

  is($perl_res->{status}, 'success');

  # re-query
  $first_genotype_annotation = $first_genotype->annotations()->first();

  is ($first_genotype_annotation->data()->{submitter_comment}, "$new_comment");
};

test_psgi $app, sub {
  my $cb = shift;

  # retrieve a single genotype
  my $uri = new URI("$root_url/ws/genotype/details/by_id/$first_genotype_id");

  my $req = HTTP::Request->new(GET => $uri);

  my $res = $cb->($req);

  my $perl_res = decode_json $res->content();

  cmp_deeply($perl_res,
             {
               'allele_string' => 'ssm4delta SPCC63.05delta',
               'genotype_id' => 1,
               'alleles' => [
                 {
                   'display_name' => 'ssm4delta',
                   'name' => 'ssm4delta',
                   'expression' => undef,
                   'uniquename' => 'SPAC27D7.13c:aaaa0007-1',
                   'type' => 'deletion',
                   'description' => 'deletion'
                 },
                 {
                   'uniquename' => 'SPCC63.05:aaaa0007-1',
                   'type' => 'deletion',
                   'description' => 'deletion',
                   'display_name' => 'SPCC63.05delta',
                   'expression' => undef,
                   'name' => 'SPCC63.05delta'
                 }
               ],
               'display_name' => 'h+ SPCC63.05delta ssm4KE',
               'identifier' => 'aaaa0007-genotype-test-1',
               'name' => 'h+ SPCC63.05delta ssm4KE'
             });
};

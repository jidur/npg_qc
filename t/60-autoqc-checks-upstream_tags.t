use strict;
use warnings;
use Cwd;
use File::Temp qw/ tempdir /;
use Test::More tests => 12;
use Test::Exception;
use Moose::Meta::Class;

use npg_testing::db;

my $ref_repos = cwd . '/t/data/autoqc';
my $archive_qc_path = cwd . '/t/data/autoqc/upstream_tags';
my $tag_sets_repository = cwd . '/t/data/autoqc/tag_sets';

use_ok ('npg_qc::autoqc::checks::upstream_tags');

SKIP: { skip 'require bammaskflags', 11, unless `which bammaskflags`;

  my $schema = Moose::Meta::Class->create_anon_class(
          roles => [qw/npg_testing::db/])
          ->new_object({})->create_test_db(q[npg_tracking::Schema]);

  my $dir = tempdir(CLEANUP => 1);
  `touch $dir/BamIndexDecoder.jar`;
  local $ENV{CLASSPATH} = $dir;

  my %h = (
    repository          => $ref_repos,
    qc_in               => $archive_qc_path,
    tag_sets_repository => $tag_sets_repository,
    _npgtracking_schema => $schema
          );

  my %ref = %h;
  $ref{'id_run'} = 6954;
  $ref{'position'} = 1;
  my $r = npg_qc::autoqc::checks::upstream_tags->new(\%ref);
  isa_ok ($r, 'npg_qc::autoqc::checks::upstream_tags');
  my $result;
  lives_ok { $result = $r->result; } 'No error creating result object';
  isa_ok ($result, 'npg_qc::autoqc::results::upstream_tags');
  my $expected = $ref_repos . '/tag_sets/sanger168.tags';
  is($r->barcode_filename, $expected, 'correct barcode filename');

  %ref = %h;
  $ref{'id_run'} = 13362;
  $ref{'position'} = 1;
  $r = npg_qc::autoqc::checks::upstream_tags->new(\%ref);
  $expected = $ref_repos . '/tag_sets/sanger168_6.tags';
  is($r->barcode_filename, $expected, 'correct barcode filename');

  %ref = %h;
  $ref{'id_run'} = 12920;
  $ref{'position'} = 1;
  $r = npg_qc::autoqc::checks::upstream_tags->new(\%ref);
  $expected = $ref_repos . '/tag_sets/sanger168_7.tags';
  is($r->barcode_filename, $expected, 'correct barcode filename');

  my $archive =  $dir . '/archive';
  ok(mkdir($archive), 'created archive directory');
  my $lane_dir = $dir . '/lane1';
  ok(mkdir($lane_dir), 'created lane directory');
  ok(symlink("$archive_qc_path/lane1/12920_1#0.bam", "$lane_dir/12920_1#0.bam"),
    'created a symlink');
  $ref{'qc_in'} = $archive;
  $r = npg_qc::autoqc::checks::upstream_tags->new(\%ref);
  is($r->barcode_filename, $expected, 'correct barcode filename');

  %ref = %h;
  $ref{'rpt_list'} = '12920:1';
  $ref{'qc_in'} = $archive;
  $r = npg_qc::autoqc::checks::upstream_tags->new(\%ref);
  is($r->tag0_bam_file,"$dir/lane1/12920_1#0.bam",'correct tag0 bam filename'); 
};

1;

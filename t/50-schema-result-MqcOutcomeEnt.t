use strict;
use warnings;
use Test::More tests => 9;
use Test::Exception;
use Moose::Meta::Class;
use DateTime;

use npg_testing::db;
use t::autoqc_util;

use_ok('npg_qc::Schema::Result::MqcOutcomeEnt');

my $schema = Moose::Meta::Class->create_anon_class(
     roles => [qw/npg_testing::db/])
     ->new_object({})->create_test_db(q[npg_qc::Schema], 't/data/fixtures');

my $table      = 'MqcOutcomeEnt';
my $hist_table = 'MqcOutcomeHist';
my $dict_table = 'MqcOutcomeDict';

sub _outcome {
  my $description = shift;
  return {'mqc_outcome' => $description};
}

subtest 'Misc tests' => sub {
  plan tests => 37;

  my $values = {'id_run'         => 1, 
                'position'       => 1,
                'id_mqc_outcome' => 0, 
                'username'       => 'user', 
                'last_modified'  => DateTime->now(),
                'modified_by'    => 'user'};

  throws_ok {$schema->resultset($table)->create($values)}
    qr/NOT NULL constraint failed: mqc_outcome_ent\.id_seq_composition/,
    'composition foreign key is needed';

  $values->{'id_seq_composition'} = t::autoqc_util::find_or_save_composition(
                $schema, {'id_run'    => 1,
                          'position'  => 1});
  isa_ok($schema->resultset($table)->create($values),
    'npg_qc::Schema::Result::MqcOutcomeEnt');

  is ($schema->resultset($table)->search({}), 1,
    q[one row created in the table]);

  $values = {'id_run'         => 10, 
             'position'       => 1,
             'id_mqc_outcome' => 1};
  my %values1 = %{$values};
  $values1{'username'} = 'user';
  $values1{'modified_by'} = 'user';
  $values1{'id_seq_composition'} = t::autoqc_util::find_or_save_composition(
                $schema, {'id_run'    => 10,
                          'position'  => 1});

  is ($schema->resultset($hist_table)->search($values)->count, 0,
    q[no historic entry for entity about to be inserted]);
  isa_ok($schema->resultset($table)->create(\%values1),
    'npg_qc::Schema::Result::MqcOutcomeEnt');
  is ($schema->resultset($table)->search($values), 1,
    q[one row created in the entity table]);
  is ($schema->resultset($hist_table)->search($values)->count, 1,
    q[one matching row created in the entity table]);

  $values = {'id_run'         => 1, 
             'position'       => 2,
             'id_mqc_outcome' => 0, 
             'username'       => 'user', 
             'last_modified'  => DateTime->now(),
             'modified_by'    => 'user'};
  $values->{'id_seq_composition'} = t::autoqc_util::find_or_save_composition(
                $schema, {'id_run'    => 1,
                          'position'  => 2});

  isa_ok($schema->resultset($table)->create($values),
    'npg_qc::Schema::Result::MqcOutcomeEnt');
  is ($schema->resultset($table)->search({'id_run'=>1,'position'=>2})
    ->count, 1, q[one row matches in the table]);

  $values = {'id_run'         => 1, 
             'position'       => 3,
             'id_mqc_outcome' => 0, 
             'username'       => 'user', 
             'last_modified'  => DateTime->now(),
             'modified_by'    => 'user'};
  $values->{'id_seq_composition'} = t::autoqc_util::find_or_save_composition(
                $schema, {'id_run'    => 1,
                          'position'  => 3});
  $schema->resultset($table)->create($values);
  $schema->resultset($table)->find({'id_run'=>1,'position'=>3})
    ->update({'id_mqc_outcome'=>2});
  my $rs = $schema->resultset($table)->search({'id_run'=>1, 'position'=>3});
  is ($rs->count, 1, q[one row matches in the entity table after update]);
  my $ent = $rs->next;
  is($ent->id_mqc_outcome, 2, 'correct outcome id');
  is($ent->username, $ent->modified_by, 'Username equals modified_by');

  $values = {'id_run'         => 220, 
             'position'       => 1,
             'id_mqc_outcome' => 3, 
             'username'       => 'user', 
             'last_modified'  => DateTime->now(),
             'modified_by'    => 'user'};
  $values->{'id_seq_composition'} = t::autoqc_util::find_or_save_composition(
                $schema, {'id_run'    => 220,
                          'position'  => 1});
  my $object = $schema->resultset($table)->create($values);
  isa_ok($object, 'npg_qc::Schema::Result::MqcOutcomeEnt');
  ok($object->has_final_outcome(), q[The newly created entity has a final outcome]);
  $rs = $schema->resultset($table)->search({'id_run'=>220,'position'=>1,'id_mqc_outcome'=>3});
  is ($rs->count, 1, q[one row created in the table]);
  $object = $rs->next();
  is($object->id_mqc_outcome, 3, q[The outcome scalar is there and has correct value]);
  ok(defined $object->mqc_outcome, q[The outcome is defined when searching.]);

  $values = {'id_run'         => 100, 
             'position'       => 4,
             'id_mqc_outcome' => 0, 
             'username'       => 'user', 
             'last_modified'  => DateTime->now(),
             'modified_by'    => 'user'};
  $values->{'id_seq_composition'} = t::autoqc_util::find_or_save_composition(
                $schema, {'id_run'    => 100,
                          'position'  => 4});
  my $query = {
    'id_run'         => 100,
    'position'       => 4,
    'id_mqc_outcome' => 3
  };
 
  is ($schema->resultset($hist_table)->search($query)->count, 0,
    q[no row matches in the historic table before update in entity]);
  $schema->resultset($table)->create($values);
  $schema->resultset($table)->find({'id_run'=>100, 'position'=>4})
    ->update({'id_mqc_outcome'=>3});
  is ($schema->resultset($table)->search($query)->count, 1,
    q[one row matches in the entity table after update]);
  is ($schema->resultset($hist_table)->search($query)->count, 1,
    q[one row matches in the historic table after update in entity]);

  $values = {'id_run'         => 210,
             'position'       => 1,
             'id_mqc_outcome' => 1,
             'username'       => 'user', 
             'last_modified'  => DateTime->now(),
             'modified_by'    => 'randomuser'};
  $values->{'id_seq_composition'} = t::autoqc_util::find_or_save_composition(
                $schema, {'id_run'    => 210,
                          'position'  => 1});
  isa_ok($schema->resultset($table)->create($values),
    'npg_qc::Schema::Result::MqcOutcomeEnt');

  $rs = $schema->resultset($table)->search({
    'id_run'         => 210,
    'position'       => 1,
    'id_mqc_outcome' => 1
  });
  is ($rs->count, 1, q[one row created in the table]);
  $object = $rs->next();
  is($object->id_mqc_outcome, 1, q[The outcome id is correct]);
  ok(defined $object->mqc_outcome, q[The outcome is defined when searching.]);
  ok(!$object->has_final_outcome, q[The outcome is not final]);
  is($object->username, 'user', q[username is set correctly]);
  is($object->modified_by, 'randomuser', q[modified_by is set correctly]);
  ok ($object->description(), 'outcome description is "Accepted preliminary"');

  $object->update_outcome(_outcome('Rejected final'), 'new_user', 'RT#356789');
  my $row = $schema->resultset($table)
    ->search({'id_run'  => 210,'position'=> 1,})->next;
  ok($row->is_rejected, q[The outcome is a fail]);
  ok($row->has_final_outcome, q[The outcome is final]);
  is($row->username, 'RT#356789', q[username is reset]);
  is($row->modified_by, 'new_user', q[modified_by is reset]);

  throws_ok {$object->update_outcome(_outcome('some invalid'), 'user')}
    qr/Outcome some invalid is invalid/,
    'error updating to an invalid string outcome';
  throws_ok {$object->update_outcome(_outcome(123), 'user')}
    qr/Outcome 123 is invalid/,
    'error updating to invalid integer status';
  throws_ok {$object->update_outcome(_outcome('Rejected final'))}
    qr/User name required/,
    'username should be given';
  throws_ok {$object->update_outcome(undef, 'user')}
    qr/Outcome hash is required/,
    'outcome should be given';
  throws_ok {$object->update_outcome('outcome', 'user')}
    qr/Outcome hash is required/,
    'outcome should be a hash ref';
};

subtest 'Data for historic' => sub {
  plan tests => 14;

  my $values = {
    'id_run'         => 1,
    'position'       => 3,
    'id_mqc_outcome' => 0, 
    'username'       => 'user',
    'modified_by'    => 'user',
  };
  $values->{'id_seq_composition'} = t::autoqc_util::find_or_save_composition(
                $schema, {'id_run'    => 1,
                          'position'  => 3});
  my $entity = $schema->resultset($table)->new_result($values);
  my $historic = $entity->data_for_historic;
  is($entity->id_run, $historic->{'id_run'}, 'Id run matches');
  is($entity->position, $historic->{'position'}, 'Position matches');
  is($entity->id_mqc_outcome, $historic->{'id_mqc_outcome'}, 'Id mqc outcome matches');
  is($entity->username, $historic->{'username'}, 'Username matches');
  is($entity->modified_by, $historic->{'modified_by'}, 'Modified by matches');
  is($entity->last_modified, $historic->{'last_modified'}, 'Last modified matches');
  
  $values->{'reported'} = DateTime->now();
  $entity = $schema->resultset($table)->new_result($values);
  $historic = $entity->data_for_historic;
  is($entity->id_run, $historic->{'id_run'}, 'Id run matches');
  is($entity->position, $historic->{'position'}, 'Position matches');
  is($entity->id_mqc_outcome, $historic->{'id_mqc_outcome'}, 'Id mqc outcome matches');
  is($entity->username, $historic->{'username'}, 'Username matches');
  is($entity->modified_by, $historic->{'modified_by'}, 'Modified by matches');
  is($entity->last_modified, $historic->{'last_modified'}, 'Last modified matches');
  ok($entity->reported, 'There is value for reported in entity');
  ok(!defined $historic->{'reported'}, 'There is no value for reported in historic');
};

subtest q[update on a new result] => sub {
  plan tests => 42;
  
  my $rs = $schema->resultset($table);
  my $hrs = $schema->resultset($hist_table);
  my $args = {'id_run' => 444, 'position' => 1};
  $args->{'id_seq_composition'} = t::autoqc_util::find_or_save_composition(
                $schema, $args);

  my $new_row = $rs->new_result($args);
  my $outcome = 'Accepted preliminary';
  lives_ok { $new_row->update_outcome(_outcome($outcome), 'cat') }
    'preliminary outcome saved';
  ok ($new_row->in_storage, 'new object has been saved');

  my $hist_rs = $hrs->search($args);
  is ($hist_rs->count, 1, 'one historic is created');
  my $hist_new_row = $hist_rs->next();

  ok (!$new_row->has_final_outcome, 'not final outcome');
  ok ($new_row->is_accepted, 'is accepted');
  ok (!$new_row->is_final_accepted, 'not final accepted');

  for my $row (($new_row, $hist_new_row)) {
    is ($row->mqc_outcome->short_desc(), $outcome, 'correct prelim. outcome');
    is ($row->username, 'cat', 'username');
    is ($row->modified_by, 'cat', 'modified_by');
    ok ($row->last_modified, 'timestamp is set');
    isa_ok ($row->last_modified, 'DateTime');
  } 
  
  $outcome = 'Accepted final';
 
  $new_row = $rs->new_result($args);
  throws_ok { $new_row->update_outcome(_outcome($outcome), 'dog', 'cat') }
    qr /UNIQUE constraint failed/,
    'error creating a record for existing entity';

  $args->{'position'} = 2;
  $args->{'id_seq_composition'} = t::autoqc_util::find_or_save_composition(
                $schema, {'id_run' => 444, 'position' => 2});
  $new_row = $rs->new_result($args);
  $new_row->update_outcome(_outcome($outcome), 'dog', 'cat');

  $hist_rs = $hrs->search($args);
  is ($hist_rs->count, 1, 'one historic is created');
  $hist_new_row = $hist_rs->next();

  my $new_row_via_search = $rs->search($args)->next;

  for my $row (($new_row, $new_row_via_search, $hist_new_row)) {
    is ($new_row->mqc_outcome->short_desc(), $outcome, 'correct outcome');
    is ($new_row->username, 'cat', 'username');
    is ($new_row->modified_by, 'dog', 'modified_by');
    ok ($new_row->last_modified, 'timestamp is set');
    isa_ok ($new_row->last_modified, 'DateTime');
    ok ($new_row->has_final_outcome, 'is final outcome');
    ok ($new_row->is_accepted, 'is accepted');
    ok ($new_row->is_final_accepted, 'is final accepted');
  }

  $new_row->delete();
};

subtest q[toggle final outcome] => sub {
  plan tests => 9;

  my $rs = $schema->resultset($table);

  my $args = {'id_run' => 444, 'position' => 3};
  $args->{'id_seq_composition'} = t::autoqc_util::find_or_save_composition(
                $schema, $args);
  my $new_row = $rs->new_result($args);

  throws_ok { $new_row->toggle_final_outcome('cat', 'dog') }
    qr/Record is not stored in the database yet/,
    'cannot toggle a new object';
  lives_ok { $new_row->update_outcome(_outcome('Accepted preliminary'), 'cat') }
    'prelim. outcome saved';
  throws_ok { $new_row->toggle_final_outcome('cat', 'dog') }
    qr/Cannot toggle non-final outcome Accepted preliminary/,
    'cannot toggle a non-final outcome';

  my $old_outcome = 'Accepted final';
  lives_ok { $new_row->update_outcome(_outcome($old_outcome), 'cat') }
    'final outcome saved';
  is($new_row->mqc_outcome->short_desc, $old_outcome, 'final outcome is set');

  my $outcome = 'Rejected final';
  lives_ok { $new_row->toggle_final_outcome('cat', 'dog') }
    'can toggle final outcome';
  is($new_row->mqc_outcome->short_desc, $outcome, 'new outcome');

  lives_ok { $new_row->toggle_final_outcome('cat', 'dog') }
    'can toggle final outcome once more';
  is($new_row->mqc_outcome->short_desc, $old_outcome, 'old outcome again');

  $new_row->delete();
};

subtest q[reporting] => sub {
  plan tests => 3;

  my $values = {'id_run'         => 310,
                'position'       => 1,
                'id_mqc_outcome' => 1,
                'username'       => 'user',
                'last_modified'  => DateTime->now(),
                'modified_by'    => 'user'};
  $values->{'id_seq_composition'} = t::autoqc_util::find_or_save_composition(
                $schema, {'id_run'    => 310,
                          'position'  => 1});

  my $object = $schema->resultset($table)->create($values);
  throws_ok { $object->update_reported() }
    qr/Outcome for id_run 310 position 1 is not final, cannot update/,
    'Error for an invalid update_reported transition';

  my $rs = $schema->resultset($table)->get_ready_to_report();
  is ($rs->count, 3, q[3 entities ready to be reported]);

  while (my $obj = $rs->next) {
    $obj->update_reported();
  }

  my $rs2 = $schema->resultset($table)->get_ready_to_report();
  is ($rs2->count, 0, q[No entities to be reported]);
};

subtest q[validity for update] => sub {
  plan tests => 13;

  my $values = {'id_run' => 45, 'position' => 2};
  $values->{'id_seq_composition'} = t::autoqc_util::find_or_save_composition(
                $schema, {'id_run' => 45, 'position' => 2});
  my $outcome = $schema->resultset($table)->new_result($values);

  throws_ok {$outcome->valid4update()}
    qr/Outcome hash is required/, 'outcome arg is required';
  throws_ok {$outcome->valid4update('Rejected preliminary')}
    qr/Outcome hash is required/, 'outcome arg should be a hash';
  throws_ok {$outcome->valid4update(_outcome(undef))}
    qr/Outcome description is missing/, 'outcome should be defined';
  throws_ok {$outcome->valid4update(_outcome(q[]))}
    qr/Outcome description is missing/, 'outcome cannot be an empty string';
  throws_ok {$outcome->valid4update({'some_outcome' => 'Rejected preliminary'})}
    qr/Outcome description is missing/, 'matching outcome type should be used';

  lives_and {
    is $outcome->valid4update(_outcome('Rejected preliminary')), 1 }
    'in-memory object can be updated to a prelim outcome';
  lives_and {
    is $outcome->valid4update(_outcome('Rejected final')), 1 }
    'in-memory object can be updated to a final outcome';

  my $dict_id_prel = $schema->resultset($dict_table)->search(
      {'short_desc' => 'Rejected preliminary'}
     )->next->id_mqc_outcome;
  my $dict_id_final = $schema->resultset($dict_table)->search(
      {'short_desc' => 'Rejected final'}
     )->next->id_mqc_outcome;

  $values = {
    'id_run'         => 45,
    'position'       => 7,
    'id_mqc_outcome' => $dict_id_prel,
    'username'       => 'cat',
    'modified_by'    => 'dog',
  };
  $values->{'id_seq_composition'} = t::autoqc_util::find_or_save_composition(
                $schema, {'id_run' => 45, 'position' => 7});
  $outcome = $schema->resultset($table)->create($values);
  lives_and {
    is $outcome->valid4update(_outcome('Rejected preliminary')), 0 }
    'preliminary stored outcome cannot be updated to the same outcome';
  lives_and {
    is $outcome->valid4update(_outcome('Accepted preliminary')), 1 }
    'preliminary stored outcome can be updated to another priliminary outcome';
  lives_and {
    is $outcome->valid4update(_outcome('Accepted final')), 1 }
    'preliminary stored outcome can be updated to a final outcome';

  $outcome->update({'id_mqc_outcome' => $dict_id_final});
  throws_ok { $outcome->valid4update(_outcome('Accepted final')) }
    qr/Final outcome cannot be updated/,
    'error updating a final stored outcome to another final outcome';
  throws_ok { $outcome->valid4update(_outcome('Accepted preliminary')) }
    qr/Final outcome cannot be updated/,
    'error updating a final stored outcome to a preliminary outcome';
  lives_and { is $outcome->valid4update(_outcome('Rejected final')), 0 }
    'no error updating a final stored outcome to the same outcome';
};

subtest 'dynamically defined methods exist' => sub {
  plan tests => 8;

  my @methods = qw/dict_rel_name has_final_outcome is_accepted
                   is_final_accepted is_undecided is_rejected
                   description/;
  for my $m (@methods) {
    ok (npg_qc::Schema::Result::UqcOutcomeEnt->can($m),
        "method $m exists");
  }

  throws_ok {npg_qc::Schema::Result::UqcOutcomeEnt->add_common_ent_methods()}
    qr/One of the methods is already defined/,
    'these methods cannot be added second time'; 
};

subtest 'qc outcome relationship name' => sub {
  plan tests => 2; 

  is (npg_qc::Schema::Result::MqcOutcomeEnt->dict_rel_name(),
    'mqc_outcome', 'as class method');
  my $row = $schema->resultset($table)->search({})->next();
  is ($row->dict_rel_name(), 'mqc_outcome', 'as instance method');
};

1;

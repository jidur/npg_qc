use strict;
use warnings;
use Test::More tests => 50;
use Test::Exception;
use Moose::Meta::Class;
use npg_testing::db;
use DateTime;

use_ok('npg_qc::Schema::Result::MqcOutcomeEnt');

my $schema = Moose::Meta::Class->create_anon_class(
           roles => [qw/npg_testing::db/])
           ->new_object({})->create_test_db(q[npg_qc::Schema], 't/data/fixtures', ':memory:');

my $table = 'MqcOutcomeEnt';
my $hist_table = 'MqcOutcomeHist';
my $dict_table = 'MqcOutcomeDict';

{
  my $values = {'id_run'=>1, 
    'position'=>1,
    'id_mqc_outcome'=>0, 
    'username'=>'user', 
    'last_modified'=>DateTime->now(),
    'modified_by'=>'user'};
    
  my $object = $schema->resultset($table)->create($values);
  isa_ok($object, 'npg_qc::Schema::Result::MqcOutcomeEnt');

  my $rs = $schema->resultset($table)->search({});
  is ($rs->count, 1, q[one row created in the table]);
}

{
  my $values = {'id_run'=>10, 
    'position'=>1,
    'id_mqc_outcome'=>1, 
    'username'=>'user', 
    'last_modified'=>DateTime->now(),
    'modified_by'=>'user'};

  my $hist_object_rs = $schema->resultset($hist_table)->search({
    'id_run'=>10,
    'position'=>1,
    'id_mqc_outcome'=>1
  }); #Search historic that matches latest change
  is ($hist_object_rs->count, 0, q[no row matches in the historic table before insert in entity]);

  my $object = $schema->resultset($table)->create($values);
  isa_ok($object, 'npg_qc::Schema::Result::MqcOutcomeEnt');

  my $rs = $schema->resultset($table)->search({
    'id_run'=>10,
    'position'=>1,
    'id_mqc_outcome'=>1
  });
  is ($rs->count, 1, q[one row created in the entity table]);
  
  $hist_object_rs = $schema->resultset($hist_table)->search({
    'id_run'=>10,
    'position'=>1,
    'id_mqc_outcome'=>1
  }); #Search historic that matches latest change
  is ($hist_object_rs->count, 1, q[one row matches in the historic table after insert in entity]);
}

{ 
  my $all = $schema->resultset($table)->get_ready_to_report();
  is($all->count, 0, q[There are no entities ready to report]);
}

{
  my $values = {'id_run'=>1, 
      'position'=>2,
      'id_mqc_outcome'=>0, 
      'username'=>'user', 
      'last_modified'=>DateTime->now(),
      'modified_by'=>'user'};

  my $object = $schema->resultset($table)->create($values);
  isa_ok($object, 'npg_qc::Schema::Result::MqcOutcomeEnt');

  my $rs = $schema->resultset($table)->search({
    'id_run'=>1,
    'position'=>2
  });
  is ($rs->count, 1, q[one row matches in the table]);  
}

{
  my $values = {'id_run'=>1, 
    'position'=>3,
    'id_mqc_outcome'=>0, 
    'username'=>'user', 
    'last_modified'=>DateTime->now(),
    'modified_by'=>'user'};

  my $object = $schema->resultset($table)->create($values); #Insert new entity
  my $rs = $schema->resultset($table);
  $rs->find({
    'id_run'=>1,
    'position'=>3
  })->update({'id_mqc_outcome'=>2}); #Find and update the outcome in the new outcome
  $rs = $schema->resultset($table)->search({
    'id_run'=>1,
    'position'=>3,
    'id_mqc_outcome'=>2
  }); #Search the new outcome
  is ($rs->count, 1, q[one row matches in the entity table after update]);
  my $ent = $rs->next;
  cmp_ok($ent->username, 'eq', $ent->modified_by, 'Username equals modified_by after manual update.');
}

subtest 'Data for historic' => sub {
  plan tests => 14;

  my $values = {
    'id_run'         => 1,
    'position'       => 3,
    'id_mqc_outcome' => 0, 
    'username'       => 'user',
    'modified_by'    => 'user',
  };

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

{
  my $values = {'id_run'=>100, 
    'position'=>4,
    'id_mqc_outcome'=>0, 
    'username'=>'user', 
    'last_modified'=>DateTime->now(),
    'modified_by'=>'user'};

  my $hist_object_rs = $schema->resultset($hist_table)->search({
    'id_run'=>100,
    'position'=>4,
    'id_mqc_outcome'=>3
  });
  is ($hist_object_rs->count, 0, q[no row matches in the historic table before update in entity]);

  my $object = $schema->resultset($table)->create($values);
  my $rs = $schema->resultset($table);
  $rs->find({'id_run'=>100, 'position'=>4})->update({'id_mqc_outcome'=>3}); #Find and update the outcome in the new outcome
  $rs = $schema->resultset($table)->search({
    'id_run'=>100,
    'position'=>4,
    'id_mqc_outcome'=>3
  }); #Search the new outcome
  is ($rs->count, 1, q[one row matches in the entity table after update]);
  
  $hist_object_rs = $schema->resultset($hist_table)->search({
    'id_run'=>100,
    'position'=>4,
    'id_mqc_outcome'=>3
  });
  is ($hist_object_rs->count, 1, q[one row matches in the historic table after update in entity]);
  my $all = $schema->resultset($table)->get_ready_to_report();
  is($all->count, 1, q[There is one entity ready to be reported]);
  ok($rs->next->is_accepted, q[The outcome is considered accepted.]);
}

{ 
  my $id_run = 110; 
  my $position = 1;
  my $status = 1;
  my $username = 'username';
  
  my $values = {'id_run' => $id_run, 'position' => $position};
  
  my $object = $schema->resultset($table)->find_or_new($values);
  $object->last_modified(DateTime->now());
  my $in = $object->in_storage; #Row status from database
  if($in) { #Entity exists
    my $outcome_dict = $schema->resultset($dict_table)
                              ->find($object
                              ->id_mqc_outcome);
    if($outcome_dict->is_final_outcome) {
      print("Problem trying to update final outcome");
    } else {
      $object->update({'id_mqc_outcome' => $status, 'username'=>$username});      
    }
  } else {
    $object->id_mqc_outcome($status);
    $object->insert();
  }
  my $rs = $schema->resultset($table)->search({
    'id_run'=>110,
    'position'=>1,
    'id_mqc_outcome'=>1
  });
  is ($rs->count, 1, q[one row matches in the entity table after outcome update]);
}

{
  my $values = {'id_run'=>210,
    'position'       => 1,
    'id_mqc_outcome' => 1,
    'username'       => 'user', 
    'last_modified'  => DateTime->now(),
    'modified_by'=>'user'};

  my $object = $schema->resultset($table)->create($values);
  isa_ok($object, 'npg_qc::Schema::Result::MqcOutcomeEnt');
  
  my $outcome_dict = $schema->resultset($dict_table)->find(1);
  ok(defined $outcome_dict, q[The dictionary is defined for outcome]);
  is($outcome_dict->id_mqc_outcome, 1, q[The dictionary object has correct value for key]);

  my $rs = $schema->resultset($table)->search({
    'id_run'=>210,
    'position'=>1,
    'id_mqc_outcome'=>1
  });
  is ($rs->count, 1, q[one row created in the table]);
  $object = $rs->next();
  is($object->id_mqc_outcome, 1, q[The outcome scalar is there and has correct value]);
  ok(defined $object->mqc_outcome, q[The outcome is defined when searching.]);
  ok(!$object->has_final_outcome, q[The outcome before update is not final]);
  
  my $id_run = 210;
  my $position = 1;
  my $status = 'Rejected final';
  my $username = 'randomuser';
  
  $values = {'id_run' => $id_run, 'position' => $position};
  
  $object = $schema->resultset($table)->find_or_new($values);
  $object->update_outcome($status, $username);
  
  $rs = $schema->resultset($table)->search({
    'id_run'=>210,
    'position'=>1,
    'id_mqc_outcome'=>4
  });
  is ($rs->count, 1, q[One row matches in the entity table after outcome update]);
  
  ok(!$rs->next->is_accepted, q[The outcome is not considered accepted.]);

  throws_ok {$object->update_outcome('some invalid', $username)}
    qr/Outcome some invalid is invalid/,
    'error updating to invalid string status';
  throws_ok {$object->update_outcome(123, $username)}
    qr/Outcome 123 is invalid/,
    'error updating to invalid integer status';
  throws_ok {$object->update_outcome($status, 789)}
    qr/Have a number 789 instead as username/, 'username can be an integer';
  throws_ok {$object->update_outcome($status)}
    qr/Mandatory parameter 'username' missing in call/,
    'username should be given';
  throws_ok {$object->update_outcome()}
    qr/Mandatory parameter 'outcome' missing in call/,
    'outcome should be given';
}

{
  my $values = {'id_run'=>220, 
    'position'       => 1,
    'id_mqc_outcome' => 3, 
    'username'       => 'user', 
    'last_modified'  => DateTime->now(),
    'modified_by'    => 'user'};

  my $object = $schema->resultset($table)->create($values);
  isa_ok($object, 'npg_qc::Schema::Result::MqcOutcomeEnt');
  ok($object->has_final_outcome(), q[The newly created entity has a final outcome]);
  
  my $outcome_dict = $schema->resultset($dict_table)->find(3);
  ok(defined $outcome_dict, q[The dictionary is defined for outcome]);
  is($outcome_dict->id_mqc_outcome, 3, q[The dictionary object has correct value for key]);
  
  my $rs = $schema->resultset($table)->search({
    'id_run'=>220,
    'position'=>1,
    'id_mqc_outcome'=>3
  });
  is ($rs->count, 1, q[one row created in the table]);
  $object = $rs->next();
  is($object->id_mqc_outcome, 3, q[The outcome scalar is there and has correct value]);
  ok(defined $object->mqc_outcome, q[The outcome is defined when searching.]);
  
  my $id_run = 220;
  my $position = 1;
  my $status = 4;
  my $username = 'randomuser';
  
  $values = {'id_run' => $id_run, 'position' => $position};
  
  $object = $schema->resultset($table)->find_or_new($values);
  ok($object->in_storage, 'Object is in storage.');
  ok($object->has_final_outcome, 'Object has final outcome.');
  throws_ok { $object->update_outcome($status, $username) } qr/Outcome is already final/, 'Invalid outcome transition croak';
  
  $rs = $schema->resultset($table)->search({
    'id_run'=>220,
    'position'=>1,
    'id_mqc_outcome'=>3
  });
  is ($rs->count, 1, q[One row matches in the entity table because there was no update]);
}

{
  my $values = {'id_run'=>310,
    'position'       => 1,
    'id_mqc_outcome' => 1,
    'username'       => 'user', 
    'last_modified'  => DateTime->now(),
    'modified_by'    => 'user'};

  my $object = $schema->resultset($table)->create($values);
  throws_ok { $object->update_reported() }
    qr/Outcome for id_run 310 position 1 is not final, cannot update/,
    'Error for an invalid update_reported transition';
}

{
  my $rs = $schema->resultset($table)->get_ready_to_report();
  is ($rs->count, 3, q[3 entities ready to be reported]);
  
  while (my $obj = $rs->next) {
    $obj->update_reported();
  }
  
  my $rs2 = $schema->resultset($table)->get_ready_to_report();
  is ($rs2->count, 0, q[No entities to be reported]);
}

subtest 'Update to final' => sub {
  plan tests => 9;

  my $values = {
    'id_run'         => 300,
    'position'       => 1,
    'id_mqc_outcome' => 1, #Accepted pre
    'username'       => 'user',
    'modified_by'    => 'user'
  };
  
  my $username = 'someusername';
  
  my $object = $schema->resultset($table)->create($values);
  ok ( $object->is_accepted && !$object->has_final_outcome,
         'Entity has accepted not final.');
  ok ( $object->update_to_final_outcome($username),
         'Can update as final outcome' );
  ok ( $object->is_accepted && $object->has_final_outcome,
         'Entity has accepted final.');
  
  $values->{'position'} = 2;
  $values->{'id_mqc_outcome'} = 2; #Rejected pre
  $object = $schema->resultset($table)->create($values);
  ok ( $object->is_rejected && !$object->has_final_outcome,
         'Entity has rejected not final.');
  ok ( $object->update_to_final_outcome($username),
         'Can update as final outcome' );
  ok ( $object->is_rejected && $object->has_final_outcome,
         'Entity has accepted final.');
  
  $values->{'position'} = 3;
  $values->{'id_mqc_outcome'} = 5; #Undecided
  $object = $schema->resultset($table)->create($values);
  ok ( $object->is_undecided,
         'Entity has undecided.');
  throws_ok { $object->update_to_final_outcome($username) } 
    qr/Unable to update unexpected outcome to final for id_run 300 position 3./,
    'Error trying to set as undecided final from undecided';
  ok ( $object->is_undecided && !$object->has_final_outcome,
         'Entity has undecided not final.');
};

subtest q[batch update libraries accepted final] => sub {
  plan tests => 5;

  my $id_run   = 400;
  my $position = 2;
  my $username = q[user];

  my $values_lane = {
    'id_run'         => $id_run,
    'position'       => $position,
    'id_mqc_outcome' => 1, #Accepted preeliminary
    'username'       =>$username, 
    'last_modified'  =>DateTime->now(),
    'modified_by'    =>$username};
    
  my $object_lane = $schema->resultset(q[MqcOutcomeEnt])->create($values_lane);
  isa_ok($object_lane, 'npg_qc::Schema::Result::MqcOutcomeEnt');

  my $values_plex = {
    'id_run'         => $id_run, 
    'position'       => $position,
    'username'       => $username, 
    'last_modified'  => DateTime->now(),
    'modified_by'    => $username
  };
  
  my $rs = $schema->resultset(q[MqcLibraryOutcomeEnt]);

  $values_plex->{'tag_index'}      = 10;
  $values_plex->{'id_mqc_outcome'} = 1; #Accepted preeliminary
  my $object_plex = $rs->create($values_plex);
  ok($object_plex->in_storage, q[New plex in database]);

  $values_plex->{'tag_index'}      = 20;
  $values_plex->{'id_mqc_outcome'} = 2; #Rejected preeliminary
  $object_plex = $rs->create($values_plex);
  ok($object_plex->in_storage, q[New plex in database]);

  my $tag_indexes_lims = [10, 20];
  
  $object_lane->update_outcome_with_libraries(q[Accepted final],
                                              $username,
                                              $tag_indexes_lims);

  my $values_search = {
    'id_run' => $id_run, 
    'position' => $position,
  };

  my $changed_entities_rs = $rs->search($values_search);

  my $new_desc = $changed_entities_rs->search({'tag_index' => 10})->first->mqc_outcome->short_desc;
  is($new_desc, 'Accepted final', 'Updated to Accepted final');
  $new_desc = $changed_entities_rs->search({'tag_index' => 20})->first->mqc_outcome->short_desc;
  is($new_desc, 'Rejected final', 'Updated to Rejected final');
};

subtest q[batch update libraries rejected final] => sub {
  plan tests => 6;

  my $id_run   = 401;
  my $position = 2;
  my $username = q[user];

  my $values_lane = {
    'id_run'         => $id_run,
    'position'       => $position,
    'id_mqc_outcome' => 1, #Accepted preeliminary
    'username'       =>$username, 
    'last_modified'  =>DateTime->now(),
    'modified_by'    =>$username};
    
  my $object_lane = $schema->resultset(q[MqcOutcomeEnt])->create($values_lane);
  isa_ok($object_lane, 'npg_qc::Schema::Result::MqcOutcomeEnt');

  my $values_plex = {
    'id_run'         => $id_run, 
    'position'       => $position,
    'username'       => $username, 
    'last_modified'  => DateTime->now(),
    'modified_by'    => $username
  };
  
  my $rs = $schema->resultset(q[MqcLibraryOutcomeEnt]);

  $values_plex->{'tag_index'}      = 10;
  $values_plex->{'id_mqc_outcome'} = 5; #Undecided
  my $object_plex = $rs->create($values_plex);
  ok($object_plex->in_storage, q[New plex in database]);

  $values_plex->{'tag_index'}      = 20;
  $values_plex->{'id_mqc_outcome'} = 5; #Undecided
  $object_plex = $rs->create($values_plex);
  ok($object_plex->in_storage, q[New plex in database]);

  my $tag_indexes_lims = [10, 20, 30];
  
  $object_lane->update_outcome_with_libraries(q[Rejected final],
                                              $username,
                                              $tag_indexes_lims);

  my $values_search = {
    'id_run' => $id_run, 
    'position' => $position,
  };

  my $changed_entities_rs = $rs->search($values_search);

  my $new_desc = $changed_entities_rs->search({'tag_index' => 10})->first->mqc_outcome->short_desc;
  is($new_desc, 'Undecided final', 'Updated to Undecided final');
  $new_desc = $changed_entities_rs->search({'tag_index' => 20})->first->mqc_outcome->short_desc;
  is($new_desc, 'Undecided final', 'Updated to Undecided final');
  $new_desc = $changed_entities_rs->search({'tag_index' => 30})->first->mqc_outcome->short_desc;
  is($new_desc, 'Undecided final', 'Updated to Undecided final');
};

1;

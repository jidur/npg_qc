
package npg_qc::Schema::Result::MoveZ;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

##no critic(RequirePodAtEnd RequirePodLinksIncludeText ProhibitMagicNumbers ProhibitEmptyQuotes)

=head1 NAME

npg_qc::Schema::Result::MoveZ

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::InflateColumn::Serializer>

=back

=cut

__PACKAGE__->load_components('InflateColumn::DateTime', 'InflateColumn::Serializer');

=head1 TABLE: C<move_z>

=cut

__PACKAGE__->table('move_z');

=head1 ACCESSORS

=head2 id_move_z

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 id_run_tile

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 cycle

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 currentz

  data_type: 'smallint'
  is_nullable: 0

=head2 targetz

  data_type: 'smallint'
  is_nullable: 0

=head2 newz

  data_type: 'smallint'
  is_nullable: 0

=head2 start

  data_type: 'bigint'
  is_nullable: 0

=head2 stop

  data_type: 'bigint'
  is_nullable: 0

=head2 move

  data_type: 'tinyint'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  'id_move_z',
  {
    data_type => 'bigint',
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  'id_run_tile',
  {
    data_type => 'bigint',
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  'cycle',
  { data_type => 'smallint', extra => { unsigned => 1 }, is_nullable => 0 },
  'currentz',
  { data_type => 'smallint', is_nullable => 0 },
  'targetz',
  { data_type => 'smallint', is_nullable => 0 },
  'newz',
  { data_type => 'smallint', is_nullable => 0 },
  'start',
  { data_type => 'bigint', is_nullable => 0 },
  'stop',
  { data_type => 'bigint', is_nullable => 0 },
  'move',
  { data_type => 'tinyint', extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id_move_z>

=back

=cut

__PACKAGE__->set_primary_key('id_move_z');

=head1 UNIQUE CONSTRAINTS

=head2 C<unq_idx_movez_rt_cycle>

=over 4

=item * L</id_run_tile>

=item * L</cycle>

=back

=cut

__PACKAGE__->add_unique_constraint('unq_idx_movez_rt_cycle', ['id_run_tile', 'cycle']);

=head1 RELATIONS

=head2 id_run_tile

Type: belongs_to

Related object: L<npg_qc::Schema::Result::RunTile>

=cut

__PACKAGE__->belongs_to(
  'id_run_tile',
  'npg_qc::Schema::Result::RunTile',
  { id_run_tile => 'id_run_tile' },
  { is_deferrable => 1, on_delete => 'RESTRICT', on_update => 'RESTRICT' },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2014-02-23 17:42:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2e6Xe0zE85AhWF3a9yadXQ

our $VERSION   = do { my ($r) = q$Revision$ =~ /(\d+)/mxs; $r; };

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 VERSION

$Revision$

=head1 SYNOPSIS

=head1 DESCRIPTION

Result class definition in DBIx binding for npg-qc database.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 SUBROUTINES/METHODS

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item Moose

=item MooseX::NonMoose

=item MooseX::MarkAsMethods

=item DBIx::Class::Core

=item DBIx::Class::InflateColumn::DateTime

=item DBIx::Class::InflateColumn::Serializer

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Marina Gourtovaia E<lt>mg8@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL, by Marina Gourtovaia

This file is part of NPG.

NPG is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut


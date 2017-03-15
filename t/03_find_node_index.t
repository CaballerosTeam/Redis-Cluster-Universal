use strict;
use warnings;
use Test::More;

my $hash_slot_list = [[0, 5460], [5461, 10922], [10923, 16383]];
my $hash_slot_node_map = {
    -7     => -1,
    0      => 0,
    5_050  => 0,
    5_460  => 0,
    5_461  => 1,
    10_001 => 1,
    10_922 => 1,
    10_923 => 2,
    15_546 => 2,
    16_383 => 2,
    16_500 => -1,
};

my $hash_slot_list_1 = [[0, 5460], [5461, 7777], [7778, 10922], [10923, 16383]];
my $hash_slot_node_map_1 = {
    -7     => -1,
    0      => 0,
    5_050  => 0,
    5_460  => 0,
    5_461  => 1,
    6_603  => 1,
    7_777  => 1,
    9_001  => 2,
    10_001 => 2,
    10_922 => 2,
    10_923 => 3,
    15_546 => 3,
    16_383 => 3,
    16_500 => -1,
};

BEGIN {
    my $module = 'Redis::Cluster::Universal';
    use_ok($module);
    can_ok($module, '_find_node_index');
};

while (my ($hash_slot, $expected) = each(%{$hash_slot_node_map})) {
    my $actual = Redis::Cluster::Universal::_find_node_index($hash_slot_list, $hash_slot);
    is($actual, $expected, sprintf("Node index for hash slot '%s'", $hash_slot));
}

while (my ($hash_slot, $expected) = each(%{$hash_slot_node_map_1})) {
    my $actual = Redis::Cluster::Universal::_find_node_index($hash_slot_list_1, $hash_slot);
    is($actual, $expected, sprintf("Node index for hash slot '%s'", $hash_slot));
}

done_testing();

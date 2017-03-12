use strict;
use warnings;
use Test::More;


my $expected_key_hash_slot_map = {
    spam => 1201,
    foo  => 12182,
    egg  => 15975,
};

BEGIN {
    my $module = 'Redis::Cluster::Universal';
    use_ok($module);
    can_ok($module, '_get_hash_slot_by_key');
};

while (my ($key, $expected) = each(%{$expected_key_hash_slot_map})) {
    my $actual = Redis::Cluster::Universal::_get_hash_slot_by_key($key);
    is($actual, $expected, sprintf("Hash slot for key '%s' doesn't match", $key));
}

done_testing();

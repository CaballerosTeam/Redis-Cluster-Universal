use strict;
use warnings;
use Test::More;

BEGIN {
    my $module = 'Redis::Cluster::Universal';
    use_ok($module);
    can_ok($module, '_hash_tag_to_key');
};

my $hash_tag_key_map = {
    'this{foo}key'      => 'foo',
    'another{foo}key'   => 'foo',
    'another{fookey'    => 'another{fookey',
    'anotherfoo}key'    => 'anotherfoo}key',
    'another}foo{key'   => 'another}foo{key',
    '{another}fookey'   => 'another',
    'anotherfoo{key}'   => 'key',
    '{another}{foo}key' => 'another',
    'thisfookey'        => 'thisfookey',
};

foreach my $hash_tag (keys(%{$hash_tag_key_map})) {
    my $actual = Redis::Cluster::Universal::_hash_tag_to_key($hash_tag);
    my $expected = $hash_tag_key_map->{$hash_tag};
    is($actual, $expected, sprintf("Key for hash tag '%s'", $hash_tag));
}

done_testing();

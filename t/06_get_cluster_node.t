use strict;
use warnings;
use Test::More;
use Scalar::Util;
use Redis::Cluster::Node;

my $node_list = ['127.0.0.0:7001', '127.0.0.1:7002', '127.0.0.1:7003'];
my $hash_slot_list = [[0, 5460], [5461, 10922], [10923, 16383]];
my $expected_hash_tag_node_map = {
    spam                                                           => '127.0.0.0:7001',
    foo                                                            => '127.0.0.1:7003',
    'this{foo}key'                                                 => '127.0.0.1:7003',
    'another{foo}key'                                              => '127.0.0.1:7003',
    egg                                                            => '127.0.0.1:7003',
    16384                                                          => '127.0.0.0:7001',
    'cluster-1'                                                    => '127.0.0.1:7003',
    '123testing123'                                                => '127.0.0.1:7003',
    'Redis::Cluster::Universal::_get_hash_slot_by_key(key:"spam")' => '127.0.0.0:7001',
    ''                                                             => '127.0.0.0:7001',
    'приветредис'                                                  => '127.0.0.0:7001',
};

BEGIN {
    my $module = 'Redis::Cluster::Universal';
    use_ok($module);
    can_ok($module, 'get_cluster_node');
};

SKIP: {
    my $module = 'Redis::Fast';
    eval {
        Module::Load::load($module);
    };

    skip(sprintf("Can't load '%s' module", $module)) if ($@);

    my $rcu = Redis::Cluster::Universal->new(nodes => $node_list, transport => 'Redis::Fast');
    $rcu->{_cluster_slots} = $hash_slot_list;

    foreach my $hash_tag (keys(%{$expected_hash_tag_node_map}))
    {
        my Redis::Cluster::Node $node = $rcu->get_cluster_node($hash_tag);

        ok(Scalar::Util::blessed($node), sprintf("Node for key '%s' is object", $hash_tag));
        ok($node->isa('Redis::Cluster::Node'),
            sprintf("Node for key '%s' is a 'Redis::Cluster::Node' instance", $hash_tag));

        my $actual = $node->get_address();
        my $expected = $expected_hash_tag_node_map->{$hash_tag};

        is($actual, $expected, sprintf("Node address for key '%s' match", $hash_tag));
    }
}

done_testing();

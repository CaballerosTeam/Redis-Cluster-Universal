use strict;
use warnings;
use Test::More;
use List::Util;

BEGIN {
    my $module = 'Redis::Cluster::Universal';
    use_ok($module);
};

SKIP: {
    skip("Environment variable REDIS_CLUSTER isn't defined") unless ($ENV{REDIS_CLUSTER});

    my $module = 'Redis::Fast';
#    my $module = 'Redis';
    eval {
        Module::Load::load($module);
    };

    skip(sprintf("Can't load '%s' module", $module)) if ($@);

    my $cluster_nodes = [split(/[\s,;]+/, $ENV{REDIS_CLUSTER})];
    my $rcu = Redis::Cluster::Universal->new(nodes => $cluster_nodes, transport => $module);

    my $key = 'Redis::Cluster::Universal::_get_hash_slot_by_key(key:"foo")';
    my $value = 'Some important information';

    my $hash_slot = Redis::Cluster::Universal::_get_hash_slot_by_key($key);
    my $cluster_slots = $rcu->get_cluster_slots();
    my $node_index = Redis::Cluster::Universal::_find_node_index($cluster_slots, $hash_slot);
    my $new_node_index = $node_index == 0 ? $#{$cluster_slots} : $node_index - 1;
    my $new_node_address = $cluster_nodes->[$new_node_index];

    my $new_node_id;
    foreach my $address (@{$cluster_nodes}) {
        my ($host, $port) = split(':', $address, 2);

        my $output = `redis-cli -c -h $host -p $port cluster nodes` or next;

        my $rows = [split(/[\r\n]/, $output)];
        my $row = List::Util::first {index($_, $new_node_address) != -1} @{$rows};
        $new_node_id = [split(/\s+/, $row)]->[0];

        last if (defined($new_node_id));
    }

    skip("Can't fetch node id") unless (defined($new_node_id));

    my ($host, $port) = split(':', $cluster_nodes->[$node_index], 2);

    `redis-cli -c -h $host -p $port cluster setslot $hash_slot migrating $new_node_id`
        or skip(sprintf("Can't mirgate hashslot '%s'", $hash_slot));

    ok($rcu->setex($key, 3600, $value), 'Set the value and expiration of a key');
}

done_testing();

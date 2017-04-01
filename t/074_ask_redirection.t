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

    my $raw_address_list = [split(/[\s,;]+/, $ENV{REDIS_CLUSTER})];
    my $rcu = Redis::Cluster::Universal->new(nodes => $raw_address_list, transport => $module);

    my $key = 'Redis::Cluster::Universal::_get_hash_slot_by_key(key:"foo")';
    my $value = 'Some important information';

    my $hash_slot = Redis::Cluster::Universal::_get_hash_slot_by_key($key);
    my $cluster_slots = $rcu->get_cluster_slots();
    my $node_index = Redis::Cluster::Universal::_find_node_index($cluster_slots, $hash_slot);
    my $new_node_index = $node_index == 0 ? $#{$cluster_slots} : $node_index - 1;

    my $cluster_nodes = $rcu->get_cluster_nodes();

    my Redis::Cluster::Node $node = $cluster_nodes->[$node_index];
    my $node_address = $node->get_address();

    my Redis::Cluster::Node $new_node = $cluster_nodes->[$new_node_index];
    my $new_node_address = $new_node->get_address();

    my ($node_id, $new_node_id);
    foreach my $address (@{$raw_address_list}) {
        my ($host, $port) = split(':', $address, 2);

        my $output = `redis-cli -c -h $host -p $port cluster nodes` or next;

        my $rows = [split(/[\r\n]/, $output)];

        foreach my $row (@{$rows}) {
            if (index($row, $node_address) != -1) {
                $node_id = [split(/\s+/, $row)]->[0];
            }

            if (index($row, $new_node_address) != -1) {
                $new_node_id = [split(/\s+/, $row)]->[0];
            }

            last if (defined($node_id) && defined($new_node_id));
        }

        last if (defined($node_id) && defined($new_node_id));
    }

    skip("Can't fetch importing node id") unless (defined($node_id));
    skip("Can't fetch migrating node id") unless (defined($new_node_id));

    my ($host, $port) = split(':', $node_address, 2);
    my ($new_host, $new_port) = split(':', $new_node_address, 2);

    `redis-cli -c -h $new_host -p $new_port cluster setslot $hash_slot importing $node_id`
        or skip(sprintf("Can't set hashslot '%s' importing", $hash_slot));

    `redis-cli -c -h $host -p $port cluster setslot $hash_slot migrating $new_node_id`
        or skip(sprintf("Can't set hashslot '%s' migrating", $hash_slot));

    ok($rcu->setex($key, 3600, $value), 'Set the value and expiration of a key');

    my $actual = $rcu->get($key);
    my $expected = $value;

    is($actual, $expected, 'Get value');
}

done_testing();

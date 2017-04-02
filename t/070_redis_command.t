use strict;
use warnings;
use Test::More;

BEGIN {
    my $module = 'Redis::Cluster::Universal';
    use_ok($module);
};

SKIP: {
    skip("Environment variable REDIS_CLUSTER isn't defined") unless ($ENV{REDIS_CLUSTER});

    my $cnt;
    my $module_list = [qw/Redis Redis::Fast/];

    foreach my $module (@{$module_list})
    {
        eval {
            Module::Load::load($module);
        };

        next if ($@);

        $cnt++;

        my $cluster_nodes = [split(/[\s,;]+/, $ENV{REDIS_CLUSTER})];
        my $rcu = Redis::Cluster::Universal->new(nodes => $cluster_nodes, transport => $module);

        my $key = 'Redis::Cluster::Universal::_get_hash_slot_by_key(key:"spam")';
        my $value = 'Some important information';

        ok($rcu->setex($key, 3600, $value), 'Set the value and expiration of a key');

        my $actual = $rcu->get($key);
        my $expected = $value;

        is($actual, $expected, 'Get the value');
    }

    skip(sprintf("Can't load any of the modules: %s", join(', ', @{$module_list}))) unless ($cnt);
}

done_testing();

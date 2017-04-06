use strict;
use warnings;
use Test::More;

BEGIN {
    my $module = 'Redis::Cluster::Universal';
    use_ok($module);
};

my $key_value_map = {
    hello         => 'world',
    sparta        => 300,
    'egg{foo}key' => 'spam',
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
        my $expected = 'Some important information';

        ok($rcu->setex($key, 3600, $expected), 'Set the value and expiration of a key');
        my $actual = $rcu->get($key);
        is($actual, $expected, 'Get the value');

        my $tail = ' here';
        $expected .= $tail;
        ok($rcu->append($key, $tail), 'Append some value to existing key');
        $actual = $rcu->get($key);
        is($actual, $expected, 'Get the value');

        $key = 'some{foo}key';
        my $delta = 5;
        $expected = 10;
        ok($rcu->set($key, $expected - $delta), 'Set integer value');
        ok($rcu->incrby($key, $delta), 'Increments integer value');
        $actual = $rcu->get($key);
        is($actual, $expected, 'Get the value');

        foreach my $k (keys(%{$key_value_map})) {
            my $v = $key_value_map->{$k};

            ok($rcu->set($k, $v), sprintf('SET %s %s', $k, $v));
            is($rcu->get($k), $v, sprintf('GET %s', $k));
        }
    }

    skip(sprintf("Can't load any of the modules: %s", join(', ', @{$module_list}))) unless ($cnt);
}

done_testing();

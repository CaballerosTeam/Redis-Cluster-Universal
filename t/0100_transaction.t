use strict;
use warnings;
use Test::More;


BEGIN {
    my $module = 'Redis::Cluster::Universal';
    use_ok($module);
};

my $key_value_map = {
    'foo{spam}' => 1,
    'bar{spam}' => 1,
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

        my $first_hashtag = [keys(%{$key_value_map})]->[0];
        ok($rcu->multi($first_hashtag), 'Mark the start of a transaction block');

        my $hashtag_list = [sort keys(%{$key_value_map})];
        foreach my $hash_tag (@{$hashtag_list}) {
            ok($rcu->incr($hash_tag), sprintf("Increment key '%s'", $hash_tag));
        }

        my $expected = [map $key_value_map->{$_}, @{$hashtag_list}];
        my $actual = $rcu->exec($first_hashtag);

        is_deeply($actual, $expected, 'Transaction ok');

        ok($rcu->multi($first_hashtag), 'Mark the start of a transaction block');

        foreach my $hash_tag (@{$hashtag_list}) {
            ok($rcu->incr($hash_tag), sprintf("Increment key '%s'", $hash_tag));
        }

        ok($rcu->discard($first_hashtag), 'Discard all commands issued after MULTI');

        $actual = $rcu->mget(@{$hashtag_list});

        is_deeply($actual, $expected, 'Transaction discard');

        # clean up
        $rcu->del(@{$hashtag_list});
    }

    skip(sprintf("Can't load any of the modules: %s", join(', ', @{$module_list}))) unless ($cnt);
}

done_testing();

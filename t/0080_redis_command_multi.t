use strict;
use warnings;
use Test::More;


BEGIN {
    my $module = 'Redis::Cluster::Universal';
    use_ok($module);
};

my $key_value_list = [
    {
        key_list   => ['foo{spam}spam', 'foo{spam}foo', 'foo{spam}egg'],
        value_list => ['spam', 'foo', 'egg'],
    },
    {
        key_list   => ['this{hashtag}key'],
        value_list => ['100_000'],
    },
    {
        key_list   => ['no_hashtag'],
        value_list => [100_000],
    },
];

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

        foreach my $batch (@{$key_value_list}) {
            my %kwargs;
            @kwargs{@{$batch->{key_list}}} = @{$batch->{value_list}};

            ok($rcu->mset(%kwargs), 'Set multiple keys to multiple values');

            my $actual = $rcu->mget(@{$batch->{key_list}});
            my $expected = $batch->{value_list};

            is_deeply($actual, $expected, 'Get multiple values');

            ok($rcu->del(@{$batch->{key_list}}), 'Delete multiple keys');
        }
    }

    skip(sprintf("Can't load any of the modules: %s", join(', ', @{$module_list}))) unless ($cnt);
}

done_testing();

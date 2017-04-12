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

        my $key = 'foo{spam}key';
        my $value = 'Some important information';

        eval {
            require Test::LeakTrace;
        };

        skip("Can't load Test::LeakTrace module") if ($@);

            Test::LeakTrace::no_leaks_ok( {
                for (0 .. 999) {
                    my $rcu = Redis::Cluster::Universal->new(nodes => $cluster_nodes, transport => $module);

                    $rcu->set($key, $value);
                    $rcu->get($key);
                    $rcu->del($key);
                }
            } 'No memory leaks');


    }

    skip(sprintf("Can't load any of the modules: %s", join(', ', @{$module_list}))) unless ($cnt);
}

done_testing();

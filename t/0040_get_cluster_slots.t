use strict;
use Test::More;
use Module::Load;

BEGIN {
    my $module = 'Redis::Cluster::Universal';
    use_ok($module);
    can_ok($module, 'get_cluster_slots');
};

SKIP: {
    skip("Environment variable REDIS_CLUSTER isn't defined") unless ($ENV{REDIS_CLUSTER});

    skip("Can't find 'redis-cli'") unless (`redis-cli --version`);

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

        my $expected;
        foreach my $address (@{$cluster_nodes}) {
            my ($host, $port) = split(':', $address, 2);

            my $output = `redis-cli --csv -c -h $host -p $port cluster slots` or next;

            my $pieces = [split(/[,;]/, $output)];
            my $slots = [map {$_ % 4 == 0 ? [int($pieces->[$_]), int($pieces->[$_+1])] : ()} (0 .. $#{$pieces})];

            if (scalar(@{$slots}) == scalar(@{$cluster_nodes})) {
                $expected = [sort {$a->[0] <=> $b->[0]} @{$slots}];
                last;
            }
        }

        skip("Can't fetch cluster slots") unless (defined($expected));

        my $redis_cluster = Redis::Cluster::Universal->new(nodes => $cluster_nodes, transport => $module);
        my $actual = $redis_cluster->get_cluster_slots();

        is_deeply($actual, $expected, 'Cluster slots match');
    }

    skip(sprintf("Can't load any of the modules: %s", join(', ', @{$module_list}))) unless ($cnt);
};

done_testing();

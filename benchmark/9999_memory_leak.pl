#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use Test::LeakTrace;
use Redis::Cluster::Universal;


my $cnt;
my $module_list = [qw/Redis Redis::Fast/];

unless ($ENV{REDIS_CLUSTER}) {
    print "Environment variable REDIS_CLUSTER isn't defined\n";
    exit(0);
}

foreach my $module (@{$module_list}) {
    eval {
        Module::Load::load($module);
    };

    next if ($@);
    $cnt++;

    my $cluster_nodes = [split(/[\s,;]+/, $ENV{REDIS_CLUSTER})];

    my $key = 'foo{spam}key';
    my $value = 'Some important information';

    my @info = leaked_info {
        for (0 .. 9) {
            my $rcu = Redis::Cluster::Universal->new(nodes => $cluster_nodes, transport => $module);

            $rcu->set($key, $value);
            $rcu->get($key);
            $rcu->del($key);
        }
    };

    print join("\n", map {index($_->[1], 'Cluster/Universal') != -1 ? join(' ', @{$_}) : ()} @info);
}

printf("Can't load any of the modules: %s", join(', ', @{$module_list})) unless ($cnt);

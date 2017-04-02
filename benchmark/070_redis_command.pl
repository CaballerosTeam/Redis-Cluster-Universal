#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use FindBin;
use Benchmark;
use lib sprintf('%s/../../../local/lib/perl5/site_perl/5.18.2/x86_64-linux-thread-multi', $FindBin::Bin);
use Redis::Cluster::Universal;
use Redis::Cluster;


my $cluster_nodes = [qw/127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003/];
my $rcu = Redis::Cluster::Universal->new(nodes => $cluster_nodes, transport => 'Redis::Fast');
my $rc = Redis::Cluster->new(server => $cluster_nodes);

Benchmark::cmpthese(-10, {
        my => sub { $rcu->set('some{foo}key', 'egg'); },
        their => sub { $rc->set('some{foo}key', 'egg'); },
    });

Benchmark::cmpthese(-10, {
        my => sub { $rcu->get('some{foo}key'); },
        their => sub { $rc->get('some{foo}key'); },
    });

__END__

Redis as transport

    Set:
            Rate their    my
    their 4921/s    --  -43%
    my    8606/s   75%    --

    Get:
             Rate their    my
    their  6100/s    --  -43%
    my    10784/s   77%    --


Redis::Fast as transport

    Set:
             Rate their    my
    their  4879/s    --  -72%
    my    17278/s  254%    --

    Get:
             Rate their    my
    their  6128/s    --  -69%
    my    19574/s  219%    --

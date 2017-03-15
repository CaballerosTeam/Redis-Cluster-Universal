#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use FindBin;
use Benchmark;
use lib sprintf('%s/../../../local/lib/perl5/site_perl/5.18.2/x86_64-linux-thread-multi', $FindBin::Bin);
use List::MoreUtils 'bsearch';
use Redis::Cluster::Universal;


my $hash_slot_list = [[0, 5460], [5461, 7777], [7778, 10922], [10923, 16383]];

Benchmark::cmpthese(-10, {
        my => sub {
            my $hash_slot = int(rand(16384));
            Redis::Cluster::Universal::_find_node_index($hash_slot_list, $hash_slot);
        },
        their => sub {
            my $hash_slot = int(rand(16384));
            bsearch {
                    $hash_slot < $_->[0]
                        ? 1
                        : $hash_slot > $_->[1]
                            ? -1
                            : 0
                } @{$hash_slot_list};
        },
    });

__END__

           Rate their    my
their  439197/s    --  -82%
my    2442530/s  456%    --

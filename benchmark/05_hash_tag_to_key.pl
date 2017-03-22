#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use FindBin;
use Benchmark;
use lib sprintf('%s/../../../local/lib/perl5/site_perl/5.18.2/x86_64-linux-thread-multi', $FindBin::Bin);
use Redis::Cluster::Universal;


my $hash_tag = 'another{foo}key';

Benchmark::cmpthese(-10, {
        my    => sub { return Redis::Cluster::Universal::_hash_tag_to_key($hash_tag); },
        their => sub { return $hash_tag =~ m/{([^}]+)}/ ? $1 : $hash_tag; },
    });

__END__

           Rate their    my
their 1835742/s    --  -67%
my    5565938/s  203%    --

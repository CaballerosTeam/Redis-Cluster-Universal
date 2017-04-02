#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use FindBin;
use Benchmark;
use lib sprintf('%s/../../../local/lib/perl5/site_perl/5.18.2/x86_64-linux-thread-multi', $FindBin::Bin);
use Digest::CRC 'crc';
use Redis::Cluster::Universal;


my $key = 'somekey';

Benchmark::cmpthese(-10, {
        my => sub { Redis::Cluster::Universal::_get_hash_slot_by_key($key); },
        their => sub { crc($key, 0x10, 0, 0, 0, 0x1021, 0, 0) & 0x3fff; },
    });

__END__

            Rate  their     my
their    90249/s     --   -99%
my    11124824/s 12227%     --

use strict;
use warnings;
use Test::More;

my $positive_error_messages = [
    '[setex] ASK 13272 127.0.0.1:7002',
];

my $negative_error_messages = [
    '[get] MOVED 5285 127.0.0.1:7001',
];

BEGIN {
    my $module = 'Redis::Cluster::Universal';
    use_ok($module);
    can_ok($module, '_is_ask');
};

foreach my $error_message (@{$positive_error_messages}) {
    my $actual = Redis::Cluster::Universal->_is_ask($error_message);
    ok($actual, 'Detect ASK error');
}

foreach my $error_message (@{$negative_error_messages}) {
    my $actual = Redis::Cluster::Universal->_is_ask($error_message);
    ok(!$actual, 'Not detect ASK error');
}

done_testing();

use strict;
use warnings;
use Test::More;

my $positive_error_messages = [
    '[get] MOVED 5285 127.0.0.1:7001',
];

my $negative_error_messages = [
    '[get] ASK 5285 127.0.0.1:7001',
];

BEGIN {
    my $module = 'Redis::Cluster::Universal';
    use_ok($module);
    can_ok($module, '_is_moved');
};

foreach my $error_message (@{$positive_error_messages}) {
    my $actual = Redis::Cluster::Universal->_is_moved($error_message);
    ok($actual, 'Detect MOVED error');
}

foreach my $error_message (@{$negative_error_messages}) {
    my $actual = Redis::Cluster::Universal->_is_moved($error_message);
    ok(!$actual, 'Not detect MOVED error');
}

done_testing();

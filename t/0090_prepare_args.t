use strict;
use warnings;
use Test::More;


BEGIN {
    my $module = 'Redis::Cluster::Universal';
    use_ok($module);
    can_ok($module, '_prepare_args');
};

my $key = 'this{foo}key';
my $commands_args_map = {
    multi   => {client_args => [$key], redis_args => []},
    exec    => {client_args => [$key], redis_args => []},
    discard => {client_args => [$key], redis_args => []},
    unwatch => {client_args => [$key], redis_args => []},
    set     => {client_args => [$key, 100_000], redis_args => [$key, 100_000]},
    get     => {client_args => [$key, 100_000], redis_args => [$key, 100_000]},
};

foreach my $command_name (keys(%{$commands_args_map})) {
    my $args = $commands_args_map->{$command_name}->{client_args};
    my $expected = $commands_args_map->{$command_name}->{redis_args};
    my @actual = Redis::Cluster::Universal->_prepare_args($command_name, @{$args});

    is_deeply(\@actual, $expected, sprintf("Prepare arguments for command '%s'", $command_name));
}

done_testing();

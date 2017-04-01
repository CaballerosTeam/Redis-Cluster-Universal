package Redis::Cluster::Universal;

use 5.010001;
use strict;
use warnings;
use Carp;
use XSLoader;
use Module::Load;
use Redis::Cluster::Node;

our $VERSION = '0.0.1';
our $AUTOLOAD;

use constant {
    CLUSTER_NODES_LIST => '_cluster_nodes_list',
    CLUSTER_NODES_MAP  => '_cluster_nodes_map',
};

XSLoader::load('Redis::Cluster::Universal', $VERSION);


sub new {
    my ($class, %kwargs) = @_;

    Carp::confess("[!] Not an ARRAY ref in keyword argument 'nodes'") if (ref($kwargs{nodes}) ne 'ARRAY');
    Carp::confess("[!] Transport module not specified") unless(defined($kwargs{transport}));

    my $self = bless(\%kwargs, $class);

    $self->set_cluster_nodes($kwargs{nodes});

    return $self;
}

sub AUTOLOAD {
    my ($self, @args) = @_;

    my $command_name = [split('::', $AUTOLOAD)]->[-1];

    {
        no strict 'refs';
        *{$AUTOLOAD} = sub { $self->_exec_command($command_name, @args); };
    }

    goto &{$AUTOLOAD};
}

#@method
sub _exec_command {
    my ($self, $command_name, @args) = @_;

    my $hash_tag = $args[0];
    my $node = $self->get_node_by_hash_tag($hash_tag);

    Carp::confess(sprintf("[!] Couldn't fetch node for key: '%s'", $hash_tag)) unless (defined($node));

    my $handler = $node->get_handler();

    my $result;
    eval {
        $result = $handler->$command_name(@args);
    };

    my $refresh = $self->_get_refresh();

    if ($@) {
        if ($self->_is_moved($@)) {
            if ($refresh) {
                Carp::confess("[!] Twice got MOVED error, can't refresh cluster nodes info");
            }
            else {
                $self->_set_refresh(1);
                return $self->_exec_command($command_name, @args);
            }
        }
        elsif ($self->_is_ask($@)) {
            my $rows = [split(/[\r\n]+/, $@)];
            my $destination_node_address = [split(/,?\s+/, $rows->[0])]->[3];
            my $destination_node = $self->get_node_by_address($destination_node_address);

            Carp::confess(sprintf("[!] ASK redirection detected, couldn't fetch destination node: '%s'",
                $destination_node_address)) unless (defined($destination_node));

            my $destination_handler = $destination_node->get_handler();

            $destination_handler->asking();
            $result = $destination_handler->$command_name(@args);
        }
        else {
            die($@);
        }
    }

    $self->_set_refresh(0) if ($refresh);

    return $result;
}

#@method
#@returns Redis::Cluster::Node
sub get_node_by_hash_tag {
    my ($self, $hash_tag) = @_;

    Carp::confess("[!] Missing required argument 'hash_tag'") unless (defined($hash_tag));

    my $key = _hash_tag_to_key($hash_tag);
    my $hash_slot = _get_hash_slot_by_key($key);
    my $cluster_slots = $self->get_cluster_slots();
    my $node_index = _find_node_index($cluster_slots, $hash_slot);
    my $cluster_nodes = $self->get_cluster_nodes();

    return $cluster_nodes->[$node_index];
}

#@method
#@returns Redis::Cluster::Node
sub get_node_by_address {
    my ($self, $node_address) = @_;

    Carp::confess("[!] Missing required argument 'node_address'") unless (defined($node_address));

    return $self->{CLUSTER_NODES_MAP()}->{$node_address};
}

#@staticmethod
#@method
sub _is_moved {
    my (undef, $error_message) = @_;

    Carp::confess("[!] Missing required argument 'error_message'") unless (defined($error_message));

    return index($error_message, ' MOVED ') != -1 ? 1 : 0;
}

#@staticmethod
#@method
sub _is_ask {
    my (undef, $error_message) = @_;

    Carp::confess("[!] Missing required argument 'error_message'") unless (defined($error_message));

    return index($error_message, ' ASK ') != -1 ? 1 : 0;
}

#@method
sub get_cluster_slots {
    my ($self) = @_;

    my $key = '_cluster_slots';
    my $refresh = $self->_get_refresh();

    if (!defined($self->{$key}) || $refresh) {
        my $cluster_nodes = $self->get_cluster_nodes();
        Carp::confess("[!] Not an ARRAY ref in cluster nodes") if (ref($cluster_nodes) ne 'ARRAY');

        my $counter = 0;
        my $cluster_slots;
        foreach my Redis::Cluster::Node $node (@{$cluster_nodes}) {
            my $handler = $node->get_handler();
            $cluster_slots = $handler->cluster_slots();
            last if (ref($cluster_slots) eq 'ARRAY' && @{$cluster_slots});

            $counter++;
            Carp::confess("[!] Can't fetch cluster slots info") if ($counter > $#{$cluster_nodes});
        }

        $cluster_slots = [sort {$a->[0] <=> $b->[0]} @{$cluster_slots}];

        $self->set_cluster_nodes([map join(':', @{$_->[2]}[0..1]), @{$cluster_slots}]);

        $self->{$key} = [map [$_->[0], $_->[1]], @{$cluster_slots}];
    }

    return $self->{$key};
}

#@method
sub _get_refresh {
    my ($self) = @_;

    return $self->{refresh};
}

#@method
sub _set_refresh {
    my ($self, $flag) = @_;

    $flag //= 0;
    $self->{refresh} = $flag;

    return 1;
}

#@method
sub get_cluster_nodes {
    my ($self) = @_;

    return $self->{CLUSTER_NODES_LIST()};
}

#@method
sub set_cluster_nodes {
    my ($self, $node_list) = @_;

    Carp::confess("[!] Not an ARRAY ref in 'node_list'") if (ref($node_list) ne 'ARRAY');

    foreach my $node_address (@{$node_list})
    {
        my $node = Redis::Cluster::Node->new(
            address   => $node_address,
            transport => $self->get_transport(),
        );

        push(@{$self->{CLUSTER_NODES_LIST()}}, $node);

        $self->{CLUSTER_NODES_MAP()}->{$node_address} = $node;
    }

    return 1;
}

#@method
sub get_transport {
    my ($self) = @_;

    return $self->{transport};
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Redis::Cluster::Universal - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Redis::Cluster::Universal;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Redis::Cluster::Universal, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Sergey Yurzin, E<lt>jurzin.s@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by oper

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut

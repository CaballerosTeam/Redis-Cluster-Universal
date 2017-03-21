package Redis::Cluster::Universal;

use 5.010001;
use strict;
use warnings;
use Carp;
use XSLoader;
use Module::Load;
use Redis::Cluster::Node;

our $VERSION = '0.0.1';

use constant {
    CLUSTER_NODES_KEY => '_cluster_nodes',
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

#@method
sub get_cluster_slots {
    my ($self) = @_;

    my $key = '_cluster_slots';
    unless (defined($self->{$key})) {
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

        $self->set_cluster_nodes([map join(':', @{$_->[2]}), @{$cluster_slots}]);

        $self->{$key} = [map [$_->[0], $_->[1]], @{$cluster_slots}];
    }

    return $self->{$key};
}

#@method
sub get_cluster_nodes {
    my ($self) = @_;

    return $self->{CLUSTER_NODES_KEY()};
}

#@method
sub set_cluster_nodes {
    my ($self, $node_list) = @_;

    Carp::confess("[!] Not an ARRAY ref in 'node_list'") if (ref($node_list) ne 'ARRAY');

    $self->{CLUSTER_NODES_KEY()} = [map {Redis::Cluster::Node->new(
        address   => $_,
        transport => $self->get_transport(),
    )} @{$node_list}];

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

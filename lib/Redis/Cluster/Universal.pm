package Redis::Cluster::Universal;

use 5.010001;
use strict;
use warnings;
use Carp;
use XSLoader;
use Module::Load;

our $VERSION = '0.0.1';

use constant {
    CLUSTER_SLOTS_KEY => '_cluster_slots',
};

XSLoader::load('Redis::Cluster::Universal', $VERSION);


sub new {
    my ($class, %kwargs) = @_;

    Carp::confess("[!] Not an ARRAY ref in keyword argument 'nodes'") if (ref($kwargs{nodes}) ne 'ARRAY');
    Carp::confess("[!] Transport module not specified") unless(defined($kwargs{transport}));

    eval {
        Module::Load::load($kwargs{transport});
    };

    Carp::confess($@) if ($@);

    return bless(\%kwargs, $class);
}

##@method
#sub get_node_by_key {
#    my ($self, $key) = @_;
#
##    my $hash_slot = _get_hash_slot_by_key($key);
#}
#
##@method
#sub get_cluster_slots {
#    my ($self) = @_;
#
#    unless (defined($self->{CLUSTER_SLOTS_KEY()})) {
#
#    }
#
#    return $self->{CLUSTER_SLOTS_KEY()};
#}

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

package Redis::Cluster::Node;

use strict;
use warnings FATAL => 'all';
use Carp;


sub new {
    my ($class, %kwargs) = @_;

    Carp::confess("[!] Missing required keyword argument 'address'") unless(defined($kwargs{address}));
    Carp::confess("[!] Transport module not specified") unless(defined($kwargs{transport}));

    eval {
        Module::Load::load($kwargs{transport});
    };

    Carp::confess($@) if ($@);

    return bless(\%kwargs, $class);
}

#@method
#@returns Redis
sub get_handler {
    my ($self) = @_;

    my $key = '_handler';
    unless (defined($self->{$key})) {
        my Redis $transport = $self->get_transport();
        my $address = $self->get_address();

        $self->{$key} = $transport->new(server => $address);
    }

    return $self->{$key};
}

#@method
sub get_address {
    my ($self) = @_;

    return $self->{address};
}

#@method
#@returns Redis
sub get_transport {
    my ($self) = @_;

    return $self->{transport};
}

1;

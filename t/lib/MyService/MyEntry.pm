package MyService::MyEntry;
use Moose;
use Net::Google::DataAPI;
with 'Net::Google::DataAPI::Role::Entry';

feedurl child => (
    entry_class => 'MyService::MyEntry',
    rel => 'http://example.com/schema#myentry',
);

feedurl src_child => (
    entry_class => 'MyService::MyEntry',
    as_content_src => 1,
    query_builder => sub {
        my ($self, $args) = @_;
        return {
            foobar => $args || '',
        }
    },
    arg_builder => sub {
        my ($self, $args) = @_;
        return {
            foobar => $args || '',
        }
    }
);

feedurl atom_child => (
    entry_class => 'MyService::MyEntry',
    from_atom => sub {
        my $atom = shift;
        return $atom->id;
    }
);

feedurl null_child => (
    entry_class => 'MyService::MyEntry',
);

has foobar => (
    is => 'rw',
    isa => 'Str',
);

after from_atom => sub {
    my ($self) = @_;
    $self->{foobar} = $self->atom->get($self->atom->ns, 'foobar');
};

around to_atom => sub {
    my ($next, $self) = @_;
    my $atom = $next->($self);
    $atom->set($atom->ns, 'foobar', $self->foobar || '');
    return $atom;
};

__PACKAGE__->meta->make_immutable;

1;

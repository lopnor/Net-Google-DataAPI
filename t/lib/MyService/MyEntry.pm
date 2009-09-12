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

entry_has foobar => (
    is => 'rw',
    isa => 'Str',
    tagname => 'foobar',
);

__PACKAGE__->meta->make_immutable;

1;

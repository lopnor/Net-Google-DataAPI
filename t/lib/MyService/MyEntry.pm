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
);

__PACKAGE__->meta->make_immutable;

1;

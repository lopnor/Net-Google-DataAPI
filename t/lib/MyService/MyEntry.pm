package MyService::MyEntry;
use Moose;
use Net::Google::GData;
with 'Net::Google::GData::Role::Entry';

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

package MyService::MyEntry;
use Net::Google::GData;
with 'Net::Google::GData::Role::Entry';

feedurl child => (
    entry_class => 'MyService::MyEntry',
    rel => 'http://example.com/schema#myentry',
);

__PACKAGE__->meta->make_immutable;

1;

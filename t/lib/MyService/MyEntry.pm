package MyService::MyEntry;
use Net::Google::GData;
with 'Net::Google::GData::Role::Entry';

__PACKAGE__->meta->make_immutable;

1;

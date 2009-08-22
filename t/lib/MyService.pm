package MyService;
use Moose;
use Net::Google::GData;
with 'Net::Google::GData::Role::Service' => {
    service => 'wise',
    source => __PACKAGE__,
};
with 'Net::Google::GData::Role::Entry';

feedurl myentry => (
    entry_class => 'MyService::MyEntry',
    default => 'http://example.com/myentry',
);

feedurl fixed => (
    entry_class => 'MyService::MyEntry',
    default => 'http://example.com/fixed',
    can_add => 0,
);

__PACKAGE__->meta->make_immutable;

1;

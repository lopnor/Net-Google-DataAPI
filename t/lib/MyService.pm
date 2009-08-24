package MyService;
use Moose;
use Net::Google::DataAPI;
with 'Net::Google::DataAPI::Role::Service' => {
    service => 'wise',
    source => __PACKAGE__,
};

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

use strict;
use warnings;
use t::Util;
use Test::More;
use Test::Exception;

throws_ok {
    package MyService;
    use Moose;
    use Net::Google::DataAPI;
    with 'Net::Google::DataAPI::Role::Service' => {
        service => 'wise',
        source => __PACKAGE__
    };

    feedurl 'myentry' => (

    );
} qr{entry_class not specified};

done_testing;

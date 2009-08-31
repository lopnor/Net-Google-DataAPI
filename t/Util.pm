package t::Util;
use strict;
use warnings;
use Net::Google::AuthSub;
use Test::MockObject;

sub import {
    my ($class, %args) = @_;
    my $caller = caller;

    my $res = Test::MockObject->new;
    $res->mock(is_success => sub {1});
    $res->mock(auth => sub {'foobar'});
    {
        no warnings 'redefine';

        *Net::Google::AuthSub::login = sub { $res };
    }
}

1;

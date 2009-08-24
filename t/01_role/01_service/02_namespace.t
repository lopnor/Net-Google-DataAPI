use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockModule;

BEGIN {
    use_ok 'Net::Google::DataAPI::Role::Service';
}

{
    package MyService;
    use Moose;
    with 'Net::Google::DataAPI::Role::Service' => {
        service => 'wise',
        source => __PACKAGE__,
        ns => {
            gs => 'http://schemas.google.com/spreadsheets/2006',
        },
    };
}

{
    my $res = Test::MockObject->new;
    $res->mock(is_success => sub {1});
    $res->mock(auth => sub {'foobar'});

    my $auth = Test::MockModule->new('Net::Google::AuthSub');
    $auth->mock(login => sub {return $res});

    my $service = MyService->new(
        username => 'example@gmail.com',
        password => 'foobar',
    );
    {
        ok my $gs = $service->ns('gd');
        isa_ok $gs, 'XML::Atom::Namespace';
        is $gs->{prefix}, 'gd';
        is $gs->{uri}, 'http://schemas.google.com/g/2005';
    }
    {
        ok my $gs = $service->ns('gs');
        isa_ok $gs, 'XML::Atom::Namespace';
        is $gs->{prefix}, 'gs';
        is $gs->{uri}, 'http://schemas.google.com/spreadsheets/2006';
    }
}

done_testing;

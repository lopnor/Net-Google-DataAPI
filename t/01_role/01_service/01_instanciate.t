use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::MockObject;
use Test::MockModule;
use URI::Escape;
use HTTP::Response;

BEGIN {
    use_ok('Net::Google::DataAPI::Role::Service');
}


{
    package MyService;
    use Moose;
    with 'Net::Google::DataAPI::Role::Service' => {
        service => 'wise',
        source => __PACKAGE__,
        gdata_version => '3.0',
    };
}

{
    my $ua = Test::MockModule->new('LWP::UserAgent');
    $ua->mock(request => sub {
            my($self, $request, $arg, $size, $previous) = @_;
            is $request->method, 'POST';
            is $request->uri, 'https://www.google.com/accounts/ClientLogin';
            my $args = +{ map {uri_unescape $_} split('[&=]', $request->content) };
            is_deeply $args, {
                accountType => 'HOSTED_OR_GOOGLE',
                Email => 'example@gmail.com',
                Passwd => 'foobar',
                service => 'wise',
                source => 'MyService',
            };
            return HTTP::Response->parse(<<'END');
200 OK
Content-Type: text/plain

SID=MYSID
LSID=MYLSID
Auth=MYAuth
END
        }
    );

    my $service = MyService->new(
        username => 'example@gmail.com',
        password => 'foobar',
    );

    isa_ok $service, 'MyService';
    is $service->ua->default_headers->header('Authorization'), 'GoogleLogin auth=MYAuth';
    is $service->ua->default_headers->header('GData_Version'), '3.0';
}
{
    my $ua = Test::MockModule->new('LWP::UserAgent');
    $ua->mock(request => sub {
            my($self, $request, $arg, $size, $previous) = @_;
            return HTTP::Response->parse(<<'END');
403 Access Frobidden
Content-Type: text/plain

Url=http://www.google.com/login/captcha
Error=CaptchaRequired
CaptchaToken=MyCaptchaToken
CaptchaUrl=Captcha?ctoken=HiteT4b0Bk5Xg18_AcVoP6-yFkHPibe7O9EqxeiI7lUSN
END
        }
    );
    throws_ok {
        my $service = MyService->new(
            username => 'example@gmail.com',
            password => 'foobar',
        );
    } qr{Net::Google::AuthSub login failed};
}
{
    my $auth = Test::MockModule->new('Net::Google::AuthSub');
    $auth->mock(login => sub {
            return;
        }
    );
    throws_ok {
        my $service = MyService->new(
            username => 'example@gmail.com',
            password => 'foobar',
        );
    } qr{Net::Google::AuthSub login failed};
}
{
    my $u = 'example@gmail.com';
    my $p = 'foobar';
    my $s = 'mysource';

    my $res = Test::MockObject->new;
    $res->mock(is_success => sub {1});
    $res->mock(auth => sub {'foobar'});

    my $auth = Test::MockModule->new('Net::Google::AuthSub');
    $auth->mock(login => sub {
            my ($self, $user, $pass) = @_;
            is $self->{source}, $s;
            is $user, $u;
            is $pass, $p;
            return $res
        }
    );

    ok my $service = MyService->new(
        username => $u,
        password => $p,
        source => $s,
    );

    isa_ok $service, 'MyService';
    is $service->ua->default_headers->header('Authorization'), 'GoogleLogin auth=foobar';
    is $service->ua->default_headers->header('GData_Version'), '3.0';
}

done_testing;

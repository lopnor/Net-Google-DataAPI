use strict;
use warnings;
use Test::More;
use Test::MockModule;
use Test::Exception;
use LWP::UserAgent;
use JSON::WebToken;
use URI;
use JSON;
BEGIN {
    use_ok 'Net::Google::DataAPI::Auth::OAuth2::SignedJWT';
}
{
    throws_ok sub {
        Net::Google::DataAPI::Auth::OAuth2::SignedJWT->new(
            private_key => 'PRIVATE KEY',
        )
    }, qr/Attribute \(service_account\) is required/;
}
{
    throws_ok sub {
        Net::Google::DataAPI::Auth::OAuth2::SignedJWT->new(
            service_account => 'example@developer.gserviceaccount.com',
        )
    }, qr/Attribute \(private_key\) is required/;
}
{
    my $jwt = Test::MockModule->new('JSON::WebToken');
    $jwt->mock(encode_jwt => sub {
	my ($param, $private_key, $algorithm, $type) = @_;
	is $param->{iss}, 'example@developer.gserviceaccount.com';
	is $param->{scope}, 'https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email';
	is $param->{aud}, 'https://accounts.google.com/o/oauth2/token';
	like $param->{exp}, qr/[0-9]+/;
	like $param->{iat}, qr/[0-9]+/;
	is $private_key, 'PRIVATE KEY';
	is $algorithm, 'RS256';
	is_deeply $type, { typ => 'JWT' };
	return 'my-json-web-token';
    });

    my $ua = Test::MockModule->new('LWP::UserAgent');
    $ua->mock(request => sub {
            my ($self, $req) = @_;
            is $req->method, 'POST';
            my $q = {URI->new('?'.$req->content)->query_form};
	    is_deeply $q, {
		grant_type => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
		assertion => 'my-json-web-token',
	    };

            my $res = HTTP::Response->new(200);
            $res->header('Content-Type' => 'text/json');
            my $json = to_json({
		access_token => 'my_access_token',
		token_type => 'Bearer',
	    });
            $res->content($json);
            return $res;
        }
    );
    ok my $oauth2 = Net::Google::DataAPI::Auth::OAuth2::SignedJWT->new(
	private_key     => 'PRIVATE KEY',
	service_account => 'example@developer.gserviceaccount.com',
    );

    $oauth2->get_access_token;
    is $oauth2->access_token, 'my_access_token';
    my $req = HTTP::Request->new('get' => 'http://foo.bar.com');
    ok $oauth2->sign_request($req);
    is $req->header('Authorization'), 'Bearer my_access_token';
}

done_testing;

package Net::Google::DataAPI::Auth::OAuth2::SignedJWT;
use Any::Moose;
with 'Net::Google::DataAPI::Role::Auth';
our $VERSION = '0.01';

use LWP::UserAgent;
use HTTP::Request::Common;
use JSON;
use JSON::WebToken;
use constant OAUTH2_TOKEN_ENDPOINT => "https://accounts.google.com/o/oauth2/token";
use constant OAUTH2_CLAIM_AUDIENCE => "https://accounts.google.com/o/oauth2/token";
use constant JWT_GRANT_TYPE => "urn:ietf:params:oauth:grant-type:jwt-bearer";
use constant JWT_ALGORITHIM => "RS256";
use constant JWT_TYP => "JWT";
use constant OAUTH2_TOKEN_LIFETIME_SECS => 3600;

has private_key => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has service_account => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has scope => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    required => 1,
    auto_deref => 1,
    default => sub {[
        'https://www.googleapis.com/auth/userinfo.profile',
        'https://www.googleapis.com/auth/userinfo.email'
    ]},
);

has token_type => (
    is => 'rw',
    isa => 'Str',
);

has access_token => (
    is => 'rw',
    isa => 'Str',
);

sub get_access_token {
    my ($self) = @_;

    my $jwt_params = {
	iss   => $self->service_account,
	scope => join(' ', $self->scope),
	aud   => OAUTH2_CLAIM_AUDIENCE,
	exp   => time() + OAUTH2_TOKEN_LIFETIME_SECS,
	iat   => time()
    };

    my $jwt = JSON::WebToken::encode_jwt($jwt_params, $self->private_key, JWT_ALGORITHIM, {
	typ => JWT_TYP
    });

    my $jwt_ua = LWP::UserAgent->new;
    my $jwt_response = $jwt_ua->request(POST OAUTH2_TOKEN_ENDPOINT, {
        grant_type => JWT_GRANT_TYPE,
        assertion => $jwt
    });

    my $json_response = JSON->new->utf8->decode($jwt_response->decoded_content);
    $self->token_type($json_response->{token_type});
    $self->access_token($json_response->{access_token});
}

sub sign_request {
    my ($self, $req) = @_;
    $req->header(Authorization => join(' ',
            $self->token_type,
            $self->access_token,
        )
    );
    return $req;
}

__PACKAGE__->meta->make_immutable;

no Any::Moose;

1;

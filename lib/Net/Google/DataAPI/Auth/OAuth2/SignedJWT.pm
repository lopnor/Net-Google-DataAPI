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

# https://developers.google.com/accounts/docs/OAuth2ServiceAccount
# https://github.com/comewalk/google-api-perl-client/blob/master/lib/Google/API/OAuth2/SignedJWT.pm
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
    return $self->access_token;
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
__END__

=head1 NAME

Net::Google::DataAPI::Auth::OAuth2::SignedJWT - OAuth2 support for Server to Server Applications

=head1 SYNOPSIS

  use Net::Google::DataAPI::Auth::OAuth2::SignedJWT;

  my $oauth2 = Net::Google::DataAPI::Auth::OAuth2->new(
      private_key => <<'__KEY__',
  -----BEGIN PRIVATE KEY-----
  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  -----END PRIVATE KEY-----
  __KEY__
      service_account => 'xxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx@developer.gserviceaccount.com',
      scope => ['http://spreadsheets.google.com/feeds/'],
  );

  $oauth2->get_access_token oe die;

  # after retrieving token, you can use $oauth2 with Net::Google::DataAPI items:

  my $client = Net::Google::Spreadsheets->new(auth => $oauth2);

=head1 DESCRIPTION

Net::Google::DataAPI::Auth::OAuth2::SignedJWT interacts with google OAuth 2.0 service
and adds Authorization header to given request.

=head1 ATTRIBUTES

You can make Net::Google::DataAPI::Auth::OAuth2::SignedJWT instance with those arguments below:

=over 2

=item * private_key

private key of Crypt::OpenSSL::RSA. You can get it at L<https://code.google.com/apis/console#access>.

=item * service_account

E-mail address for service account.

=item * scope

URL identifying the service(s) to be accessed. You can see the list of the urls to use at L<http://code.google.com/intl/en-US/apis/gdata/faq.html#AuthScopes>

=back

See L<https://developers.google.com/accounts/docs/OAuth2ServiceAccount> for details.

=head1 AUTHOR

Ichinose Shogo E<lt>shogo82148@gmail.comE<gt>

=head1 SEE ALSO

L<https://developers.google.com/accounts/docs/OAuth2ServiceAccount>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

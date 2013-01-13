package Net::Google::DataAPI::Auth::OAuth2;
use Any::Moose;
use Net::Google::DataAPI::Types;
with 'Net::Google::DataAPI::Role::Auth';
use Net::OAuth2::Client;
use Net::OAuth2::Profile::WebServer;
use HTTP::Request::Common;
our $VERSION = '0.03';

has [qw(client_id client_secret)] => (is => 'ro', isa => 'Str', required => 1);
has redirect_uri => (is => 'ro', isa => 'Str', default => 'urn:ietf:wg:oauth:2.0:oob');
has scope => (is => 'ro', isa => 'ArrayRef[Str]', required => 1, auto_deref => 1,
    default => sub {[
        'https://www.googleapis.com/auth/userinfo.profile', 
        'https://www.googleapis.com/auth/userinfo.email'
    ]},
);
has site => (is => 'ro', isa => 'Str', default => 'https://accounts.google.com');
has authorize_path => (is => 'ro', isa => 'Str', default => '/o/oauth2/auth');
has access_token_path => (is => 'ro', isa => 'Str', default => '/o/oauth2/token');
has userinfo_url => (is => 'ro', isa => 'Str', default => 'https://www.googleapis.com/oauth2/v1/userinfo');
has oauth2_client => (is => 'ro', isa => 'Net::OAuth2::Client', required => 1, lazy_build => 1);
sub _build_oauth2_client {
    my $self = shift;
    Net::OAuth2::Client->new(
        $self->client_id,
        $self->client_secret,
        site => $self->site,
        authorize_path => $self->authorize_path,
        access_token_path => $self->access_token_path,
    );
}
has oauth2_webserver => (is => 'ro', isa => 'Net::OAuth2::Profile::WebServer', required => 1, lazy_build => 1);
sub _build_oauth2_webserver {
    my $self = shift;
    $self->oauth2_client->web_server( redirect_uri => $self->redirect_uri );
}
has access_token => (is => 'rw', isa => 'Net::Google::DataAPI::Types::OAuth2::AccessToken', coerce => 1);

sub authorize_url {
    my $self = shift;
    return $self->oauth2_webserver->authorize(
        scope => join(' ', $self->scope),
        @_
    );
}

sub get_access_token {
    my ($self, $code) = @_;
    my $token = $self->oauth2_webserver->get_access_token($code) or return;
    $self->access_token($token);
}

sub refresh_token {
    my ($self, $refresh_token) = @_;
    $refresh_token ||= $self->access_token->refresh_token;
    my $res = $self->oauth2_client->request(
        POST($self->oauth2_webserver->access_token_url,
            {
                refresh_token => $refresh_token,
                grant_type => 'refresh_token',
                client_id => $self->client_id,
                client_secret => $self->client_secret,
            }
        )
    );
    $res->is_success or die 'refresh_token request failed';
    my $res_params = Net::OAuth2::Profile::WebServer::_parse_json($res->content) 
        or die 'parse_json for refresh_token response failed';
    $self->access_token($res_params);
}

sub userinfo {
    my $self = shift;
    my $at = $self->access_token or die 'access_token is required';
    my $url = URI->new($self->userinfo_url);
    $url->query_form(access_token => $at->access_token);
    my $req = $self->sign_request(GET($url));
    my $res = $self->oauth2_client->request($req);
    $res->is_success or die 'userinfo request failed: '.$res->as_string;
    my $res_params = Net::OAuth2::Profile::WebServer::_parse_json($res->content) 
        or die 'parse_json for userinfo response failed';
    return $res_params;
}

sub sign_request {
    my ($self, $req) = @_;
    my $at = $self->access_token or die 'access_token is required';
    if ($at->expires_at && $at->expires_at < time) {
        $self->refresh_token or die 'refresh_token failed';
    }
    $req->header(Authorization => join(' ',
            'Bearer',
            $at->access_token,
        )
    );

    return $req;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;
__END__

=head1 NAME

Net::Google::DataAPI::Auth::OAuth2 - OAuth2 support for Google Data APIs

=head1 SYNOPSIS

  use Net::Google::DataAPI::Auth::OAuth2;

  my $oauth2 = Net::Google::DataAPI::Auth::OAuth2->new(
    client_id => 'xxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com',
    client_secret => 'mys3cr33333333333333t',
    scope => ['http://spreadsheets.google.com/feeds/'],

    # with web apps, redirect_uri is needed:
    #
    #   redirect_uri => 'http://your_app.sample.com/callback',

  );
  my $url = $oauth2->authorize_url();

  # you can add optional parameters:
  #
  #   my $url = $oauth2->authorize_url(
  #     access_type => 'offline',
  #     approval_prompt => 'force',
  #   );

  # show the user $url and get $code
  # if you're making web app, you will do:
  #
  #   return $c->redirect($auth->authorize_url());
  #
  # getting $code from the request to the 'redirect_uri' in web apps:
  #
  #   my $code = $c->req->param('code');
  #
  # in installed apps:
  #
  #   use Term::Prompt;
  #   my $code = prompt('x', 'paste the code: ', '', '');

  my $token = $oauth2->get_access_token($code) or die;

  # after retrieving $token, you can use $oauth2 with Net::Google::DataAPI items:

  my $client = Net::Google::Spreadsheets->new(auth => $oauth2);

=head1 DESCRIPTION

Net::Google::DataAPI::Auth::OAuth2 interacts with google OAuth 2.0 service
and adds Authorization header to given request.

=head1 ATTRIBUTES

You can make Net::Google::DataAPI::Auth::OAuth2 instance with those arguments below:

=over 2

=item * client_id

client id. You can get it at L<https://code.google.com/apis/console#access>.

=item * client_secret

The client secret paired with the client id.

=item * scope

URL identifying the service(s) to be accessed. You can see the list of the urls to use at L<http://code.google.com/intl/en-US/apis/gdata/faq.html#AuthScopes>

=item * redirect_url

OAuth2 redirect url. 'urn:ietf:wg:oauth:2.0:oob' will be used if you don't specify it.

=back

See L<https://developers.google.com/accounts/docs/OAuth2> for details.

=head1 AUTHOR

Nobuo Danjou E<lt>danjou@soffritto.orgE<gt>

=head1 SEE ALSO

L<Net::OAuth2>

L<https://developers.google.com/accounts/docs/OAuth2> 

you can see sample implementations for oauth2 client both as installed and web app in the eg directory of this distribution.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

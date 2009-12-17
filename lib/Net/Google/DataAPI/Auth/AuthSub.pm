package Net::Google::DataAPI::Auth::AuthSub;
use Any::Moose;
with 'Net::Google::DataAPI::Role::Auth';
use Net::Google::AuthSub;
use URI;
our $VERSION = '0.01';

has authsub => (
    is => 'ro',
    isa => 'Net::Google::AuthSub',
    required => 1,
);

sub sign_request {
    my ($self, $req) = @_;
    $req->header($self->authsub->auth_params);
    return $req;
}

1;

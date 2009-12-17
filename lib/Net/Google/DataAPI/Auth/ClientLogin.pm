package Net::Google::DataAPI::Auth::ClientLogin;
use Any::Moose;
with 'Net::Google::DataAPI::Role::Auth';
use Net::Google::AuthSub;
use URI;
our $VERSION = '0.01';

has username => ( is => 'ro', isa => 'Str', required => 1 );
has password => ( is => 'ro', isa => 'Str', required => 1 );
has service => ( is => 'ro', isa => 'Str', required => 1 );
has account_type => ( 
    is => 'ro', 
    isa => 'Str', 
    required => 1, 
    default => 'HOSTED_OR_GOOGLE', 
);
has source => ( 
    is => 'ro', 
    isa => 'Str', 
    required => 1, 
    default => sub { join '-', __PACKAGE__, $VERSION },
);
has authsub => (
    is => 'ro',
    isa => 'Net::Google::AuthSub',
    required => 1,
    lazy_build => 1,
);

sub _build_authsub {
    my ($self) = @_;
    my $authsub = Net::Google::AuthSub->new(
        service => $self->service,
        source  => $self->source,
        accountType => $self->account_type,
    );
    my $res = $authsub->login($self->username, $self->password);
    unless ( $res && $res->is_success ) {
        die 'Net::Google::AuthSub login failed';
    }
    return $authsub;
}

sub sign_request {
    my ($self, $req) = @_;
    $req->header($self->authsub->auth_params);
    return $req;
}

1;

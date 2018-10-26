package Net::Google::DataAPI::Auth::Null;
use Moose;
with 'Net::Google::DataAPI::Role::Auth';
our $VERSION = '0.02';


sub sign_request {$_[1]};

__PACKAGE__->meta->make_immutable;
no Moose;

1;

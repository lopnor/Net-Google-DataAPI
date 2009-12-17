package Net::Google::DataAPI::Auth::Null;
use Any::Moose;
with 'Net::Google::DataAPI::Role::Auth';

sub sign_request {$_[1]};

1;

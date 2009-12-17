package Net::Google::DataAPI::Auth::Noop;
use Any::Moose;
with 'Net::Google::DataAPI::Role::Auth';

sub sign_request {$_[1]};

1;

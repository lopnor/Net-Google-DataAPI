package Net::Google::DataAPI::Role::Auth;
use Any::Moose '::Role';
use namespace::autoclean;

requires 'sign_request';

1;

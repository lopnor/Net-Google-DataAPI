package Net::Google::DataAPI::Role::Auth;
use Moose::Role;
requires 'sign_request';
no Moose::Role;
our $VERSION = '0.02';

1;

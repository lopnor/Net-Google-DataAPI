package Net::Google::DataAPI::Types;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';
use Net::Google::DataAPI::Auth::AuthSub;
use Net::Google::AuthSub;

role_type 'Net::Google::DataAPI::Types::Auth'
    => {role => 'Net::Google::DataAPI::Role::Auth'};

subtype 'Net::Google::DataAPI::Types::AuthSub'
    => as 'Net::Google::AuthSub';

coerce 'Net::Google::DataAPI::Types::Auth'
    => from 'Net::Google::DataAPI::Types::AuthSub'
    => via {
        Net::Google::DataAPI::Auth::AuthSub->new(
            authsub => $_
        );
    };

1;

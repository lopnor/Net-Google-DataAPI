package Net::Google::DataAPI::Role::Types;
use Moose::Role;
use Moose::Util::TypeConstraints;
use URI;

subtype  'URL' => as 'URI';
coerce  'URL'
   => from 'Str'
      => via { URI->new( ( m{://} ) ? $_ : ($_, 'http') ) }
;





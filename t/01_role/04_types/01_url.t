#!/usr/bin/perl 

use strict;
use warnings;
use lib '../../../lib';

use Test::Most qw{no_plan};
use Carp::Always;
use URI;

#-----------------------------------------------------------------
#  
#-----------------------------------------------------------------
BEGIN {

package My::Test;
use Moose;
with qw{Net::Google::DataAPI::Role::Types};

has url => (
   is => 'rw',
   isa => 'URL',
   coerce => 1,
);

};

#-----------------------------------------------------------------
#  
#-----------------------------------------------------------------
ok( my $t = My::Test->new() );
isa_ok(  $t,
   'My::Test',
   q{[My::Test;] new()},
);

eq_or_diff(
   $t->url('test.com'),
   URI->new('test.com','http'),
   q{test.com},
);
   
eq_or_diff(
   $t->url('http://test.com'),
   URI->new('http://test.com'),
   q{http://test.com},
);
   
eq_or_diff(
   $t->url('https://test.com'),
   URI->new('https://test.com'),
   q{https://test.com},
);
   

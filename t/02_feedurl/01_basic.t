use strict;
use warnings;
use lib 't/lib';
use t::Util;
use Test::More;

BEGIN {
    use_ok 'MyService';
}

ok my $s = MyService->new(
    username => 'example@gmail.com',
    password => 'foobar',
);

isa_ok $s, 'MyService';
ok $s->can('add_myentry');
ok $s->can('myentry');
ok $s->can('myentries');

done_testing;

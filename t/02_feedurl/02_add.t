use strict;
use warnings;
use lib 't/lib';
use t::Util;
use Test::More;
use Test::Exception;
use Test::MockModule;
use Test::MockObject;
use XML::Atom::Entry;

BEGIN {
    use_ok 'MyService';
}

ok my $s = MyService->new(
    username => 'example@gmail.com',
    password => 'foobar',
);
isa_ok $s, 'MyService';

{
    my $ua = Test::MockModule->new('LWP::UserAgent');
    $ua->mock(request => sub {
            my($self, $request, $arg, $size, $previous) = @_;
            is $request->method, 'POST';
            is $request->uri, 'http://example.com/myentry';
            ok my $atom = XML::Atom::Entry->new(\($request->content));
            isa_ok $atom, 'XML::Atom::Entry';
            is $atom->title, 'my title';
            return HTTP::Response->parse(<<'END');
201 Created
Content-Type: application/atom+xml; charset=UTF-8 type=entry
Etag: "myetag"

<?xml version='1.0' encoding='UTF-8'?>
<entry xmlns='http://www.w3c.org/2005/Atom'
    xmlns:gd='http://schemas.google.com/g/2005'
    gd:etag='&quot;myetag&quot;'>
    <id>http://example.com/myidurl</id>
    <title type="text">my title</title>
    <link rel="edit"
        type="application/atom+xml"
        href="http://example.com/myediturl" />
    <link rel="self"
        type="application/atom+xml"
        href="http://example.com/myselfurl" />
    <link rel="http://example.com/schema#myentry"
        type="application/atom+xml"
        href="http://example.com/myentryfeed" />
</entry>
END
        }
    );
    
    ok my $e = $s->add_myentry(
        {
            title => 'my title'
        }
    );
    isa_ok $e, 'MyService::MyEntry';

    throws_ok {
        $s->add_fixed
    } qr{Can't locate object method "add_fixed"};
}

done_testing;


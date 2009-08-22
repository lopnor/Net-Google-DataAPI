use strict;
use warnings;
use lib 't/lib';
use t::Util;
use Test::More;
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
            is $request->method, 'GET';
            is $request->uri, 'http://example.com/myentry?title=query+title';
            return HTTP::Response->parse(<<'END');
200 OK
Content-Type: application/atom+xml; charset=UTF-8 type=feed
Etag: "myetag"

<?xml version='1.0' encoding='UTF-8'?>
<feed xmlns='http://www.w3c.org/2005/Atom'
    xmlns:gd='http://schemas.google.com/g/2005'
    gd:etag='&quot;myetag&quot;'>
    <entry gd:etag='&quot;entryetag&quot;'>
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
</feed>
END
        }
    );
    
    ok my @e = $s->myentries({title => 'query title'});
    ok scalar @e;
    isa_ok $e[0], 'MyService::MyEntry';
    is $e[0]->child_feedurl, 'http://example.com/myentryfeed';
}

done_testing;


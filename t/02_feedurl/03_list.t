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
        <content type="application/atom+xml;type=feed"
            src="http://example.com/srcofcontent" />
    </entry>
</feed>
END
        }
    );
    
    {
        ok my @e = $s->myentries({title => 'query title'});
        ok scalar @e;
        isa_ok $e[0], 'MyService::MyEntry';
        is $e[0]->child_feedurl, 'http://example.com/myentryfeed';
        is $e[0]->src_child_feedurl, 'http://example.com/srcofcontent';
    }
    {
        ok my $e = $s->myentry({title => 'query title'});
        isa_ok $e, 'MyService::MyEntry';
        is $e->child_feedurl, 'http://example.com/myentryfeed';
        is $e->src_child_feedurl, 'http://example.com/srcofcontent';
    }
}
{
    my $ua = Test::MockModule->new('LWP::UserAgent');
    $ua->mock(request => sub {
            my($self, $request, $arg, $size, $previous) = @_;
            is $request->method, 'GET';
            is $request->uri, 'http://example.com/myentry';
            return HTTP::Response->parse(<<'END');
200 OK
Content-Type: application/atom+xml; charset=UTF-8 type=feed
Etag: "myetag"

<?xml version='1.0' encoding='UTF-8'?>
<feed xmlns='http://www.w3c.org/2005/Atom'
    xmlns:gd='http://schemas.google.com/g/2005'
    gd:etag='&quot;myetag&quot;'>
    <entry gd:etag='&quot;entry2etag&quot;'>
        <id>http://example.com/myidurl</id>
        <title type="text">my 2 title</title>
        <link rel="edit"
            type="application/atom+xml"
            href="http://example.com/myediturl2" />
        <link rel="self"
            type="application/atom+xml"
            href="http://example.com/myselfurl2" />
        <link rel="http://example.com/schema#myentry"
            type="application/atom+xml"
            href="http://example.com/myentryfeed2" />
        <content type="application/atom+xml;type=feed"
            src="http://example.com/srcofcontent2" />
    </entry>
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
        <content type="application/atom+xml;type=feed"
            src="http://example.com/srcofcontent" />
    </entry>
</feed>
END
        }
    );
    
    {
        ok my @e = $s->myentries;
        is scalar @e, 2;
        isa_ok $e[0], 'MyService::MyEntry';
        is $e[0]->child_feedurl, 'http://example.com/myentryfeed2';
        is $e[0]->src_child_feedurl, 'http://example.com/srcofcontent2';
        is $e[0]->title, 'my 2 title';
    }
    {
        ok my $e = $s->myentry;
        isa_ok $e, 'MyService::MyEntry';
        is $e->child_feedurl, 'http://example.com/myentryfeed2';
        is $e->src_child_feedurl, 'http://example.com/srcofcontent2';
        is $e->title, 'my 2 title';
    }
}

done_testing;


use strict;
use warnings;
use t::Util;
use Test::More;
use Test::MockModule;
use HTTP::Response;

my $ua = Test::MockModule->new('LWP::UserAgent');
my $feed_res = HTTP::Response->parse(<<END);
200 OK
Content-Type: application/atom-xml

<?xml version='1.0' encoding='UTF-8'?>
<feed xmlns='http://www.w3c.org/2005/Atom'
    xmlns:gd='http://schemas.google.com/g/2005'
    xmlns:hoge='http://example.com/schema#hoge'>
    <entry gd:etag='&quot;entryetag&quot;'>
        <id>http://example.com/myidurl</id>
        <title type="text">my title</title>
        <link rel="edit"
            type="application/atom+xml"
            href="http://example.com/myediturl" />
        <link rel="self"
            type="application/atom+xml"
            href="http://example.com/myselfurl" />
        <hoge:foobar hoge:baz='fuga'>piyo</hoge:foobar>
    </entry>
</feed>
END
my $entry_res = HTTP::Response->parse(<<END);
200 OK
Content-Type: application/atom-xml

<?xml version='1.0' encoding='UTF-8'?>
<entry xmlns='http://www.w3c.org/2005/Atom'
    xmlns:gd='http://schemas.google.com/g/2005'
    xmlns:hoge='http://example.com/schema#hoge'
    gd:etag='&quot;entryetag2&quot;'>
        <id>http://example.com/myidurl</id>
        <title type="text">my title</title>
        <link rel="edit"
            type="application/atom+xml"
            href="http://example.com/myediturl" />
        <link rel="self"
            type="application/atom+xml"
            href="http://example.com/myselfurl" />
        <hoge:foobar hoge:baz='fuga'>nyoro</hoge:foobar>
    </entry>
END

{
    {
        package MyEntry;
        use Moose;
        use Net::Google::DataAPI;
        with 'Net::Google::DataAPI::Role::Entry';

        entry_has foobar => (
            isa => 'Str',
            is => 'rw',
        );
    }
    {
        package MyService;
        use Moose;
        use Net::Google::DataAPI;
        with 'Net::Google::DataAPI::Role::Service' => {
            service => 'wise',
            source => __PACKAGE__,
        };

        feedurl myentry => (
            entry_class => 'MyEntry',
            default => 'http://example.com/myentry',
        );
    }

    $ua->mock(request => sub {$feed_res});
    my $s = MyService->new(
        username => 'example@gmail.com',
        password => 'foobar',
    );
    ok my $e = $s->myentry;
    isa_ok $e, 'MyEntry';
    ok $e->etag;
    is $e->foobar, undef, 'access entry_has attribute without getter/setter';
    is $e->foobar('hoge'), 'hoge';
    is $e->foobar, 'hoge';
}

{
    {
        package MyEntry2;
        use Moose;
        use Net::Google::DataAPI;
        with 'Net::Google::DataAPI::Role::Entry';

        entry_has foobar => (
            isa => 'Str',
            is => 'rw',
            ns => 'hoge',
            tagname => 'foobar',
        );
    }
    {
        package MyService2;
        use Moose;
        use Net::Google::DataAPI;
        with 'Net::Google::DataAPI::Role::Service' => {
            service => 'wise',
            source => __PACKAGE__,
            ns => {
                hoge => 'http://example.com/schema#hoge',
            },
        };

        feedurl myentry => (
            entry_class => 'MyEntry2',
            default => 'http://example.com/myentry',
        );
    }

    $ua->mock(request => sub {$feed_res});
    ok my $e = MyService2->new(
        username => 'example@gmail.com',
        password => 'foobar',
    )->myentry;
    isa_ok $e, 'MyEntry2';
    is $e->foobar, 'piyo', 'getter with from_atom';

    $ua->mock(request => sub {$entry_res});
    is $e->etag, '"entryetag"';
    is $e->foobar('nyoro'), 'nyoro';
    is $e->foobar, 'nyoro';
    is $e->etag, '"entryetag2"';
}

{
    {
        package MyEntry3;
        use Moose;
        use Net::Google::DataAPI;
        with 'Net::Google::DataAPI::Role::Entry';

        entry_has foobar => (
            isa => 'Str',
            is => 'rw',
            from_atom => sub {
                my ($self, $atom) = @_;
                return $atom->get($self->ns('hoge'), 'foobar');
            },
            to_atom => sub {
                my ($self, $atom) = @_;
                $atom->set($self->ns('hoge'), 'foobar', $self->foobar);
            },
        );
    }
    {
        package MyService3;
        use Moose;
        use Net::Google::DataAPI;
        with 'Net::Google::DataAPI::Role::Service' => {
            service => 'wise',
            source => __PACKAGE__,
            ns => {
                hoge => 'http://example.com/schema#hoge',
            },
        };

        feedurl myentry => (
            entry_class => 'MyEntry3',
            default => 'http://example.com/myentry',
        );
    }

    $ua->mock(request => sub {$feed_res});
    ok my $e = MyService3->new(
        username => 'example@gmail.com',
        password => 'foobar',
    )->myentry;
    isa_ok $e, 'MyEntry3';
    is $e->foobar, 'piyo', 'getter with from_atom';

    $ua->mock(request => sub {$entry_res});
    is $e->etag, '"entryetag"';
    is $e->foobar('nyoro'), 'nyoro';
    is $e->foobar, 'nyoro';
    is $e->etag, '"entryetag2"';
}

{
    {
        package MyEntry4;
        use Moose;
        use Net::Google::DataAPI;
        with 'Net::Google::DataAPI::Role::Entry';

        entry_has foobar => (
            isa => 'Str',
            is => 'rw',
            ns => 'hoge',
            tagname => 'foobar',
        );
    }
    {
        package MyService4;
        use Moose;
        use Net::Google::DataAPI;
        with 'Net::Google::DataAPI::Role::Service' => {
            service => 'wise',
            source => __PACKAGE__,
            ns => {
                hoge => 'http://example.com/schema#hoge',
            },
        };

        feedurl myentry => (
            entry_class => 'MyEntry4',
            default => 'http://example.com/myentry',
        );
    }

    $ua->mock(request => sub {$feed_res});
    ok my $e = MyService4->new(
        username => 'example@gmail.com',
        password => 'foobar',
    )->myentry;
    isa_ok $e, 'MyEntry4';
    is $e->foobar, 'piyo', 'getter with from_atom';

    $ua->mock(request => sub {$entry_res});
    is $e->etag, '"entryetag"';
    is $e->foobar('nyoro'), 'nyoro';
    is $e->foobar, 'nyoro';
    is $e->etag, '"entryetag2"';
}

done_testing;

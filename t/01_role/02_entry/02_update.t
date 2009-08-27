use strict;
use warnings;
use Test::More;
use Test::MockModule;
use HTTP::Response;
use t::Util;

{
    package MyService;
    use Moose;
    use Net::Google::DataAPI;
    with 'Net::Google::DataAPI::Role::Service' => {
        service => 'wise',
        source => __PACKAGE__,
        ns => {
            foobar => 'http://example.com/schema#foobar'
        }
    };

    feedurl myentry => (
        default => 'http://example.com/myfeed',
        entry_class => 'MyEntry',
    );
}
{
    package MyEntry;
    use Moose;
    with 'Net::Google::DataAPI::Role::Entry';
    use XML::Atom::Util qw(textValue);

    has myattr => (
        is => 'rw',
        isa => 'Str',
        trigger => sub { $_[0]->update }
    );

    around to_atom => sub {
        my ($next, $self, @args) = @_;
        my $atom = $next->($self, @args);
        $atom->set($self->ns('foobar'), 'myattr', $self->myattr);
        return $atom;
    };

    after from_atom => sub {
        my ($self) = @_;
        $self->{myattr} = textValue($self->elem, $self->ns('foobar')->{uri}, 'myattr');
    }
}

my $e;
{
    my $xml = <<END;
201 Created

<?xml version="1.0" encoding="UTF-8"?>
<entry xmlns="http://www.w3c.org/2005/Atom"
    xmlns:foobar="http://example.com/schema#foobar"
    xmlns:gd='http://schemas.google.com/g/2005'
    gd:etag='&quot;myetag&quot;'>
    <link rel="edit" href="http://example.com/myentry" />
    <foobar:myattr>hgoehgoe</foobar:myattr>
    <title>test entry</title>
</entry>
END
    my $ua = Test::MockModule->new('LWP::UserAgent');
    $ua->mock('request' => sub {
            return HTTP::Response->parse($xml);
        }
    );
    ok my $s = MyService->new(
        username => 'example@gmail.com',
        password => 'foobar',
    );
    ok $e = $s->add_myentry(
        {
            myattr => 'hgoehgoe',
            title => 'test entry',
        }
    );
    isa_ok $e, 'MyEntry';
    isa_ok $e->service, 'MyService';
    is $e->myattr, 'hgoehgoe';
    is $e->title, 'test entry';
}
{
    my $xml = <<END;
200 OK

<?xml version="1.0" encoding="UTF-8"?>
<entry xmlns="http://www.w3c.org/2005/Atom"
    xmlns:foobar="http://example.com/schema#foobar"
    xmlns:gd='http://schemas.google.com/g/2005'
    gd:etag='&quot;myetag_updated&quot;'>
    <link rel="edit" href="http://example.com/myentry" />
    <foobar:myattr>foobar</foobar:myattr>
    <title>test entry</title>
</entry>
END
    my $ua = Test::MockModule->new('LWP::UserAgent');
    $ua->mock('request' => sub {
            return HTTP::Response->parse($xml);
        }
    );
    isa_ok $e->service, 'MyService';
    is $e->myattr('foobar'), 'foobar';
    is $e->myattr, 'foobar';
    is $e->etag, '"myetag_updated"';
}

done_testing;

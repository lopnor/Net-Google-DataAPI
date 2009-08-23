package Net::Google::GData::Role::Service;
use MooseX::Role::Parameterized;

use Carp;
use Net::Google::AuthSub;
use LWP::UserAgent;
use URI;
use XML::Atom;
use XML::Atom::Entry;
use XML::Atom::Feed;

parameter service => (
    isa => 'Str',
    required => 1,
);

parameter source => (
    isa => 'Str',
    required => 1,
);

parameter ns => (
    isa => 'HashRef',
);

role {
    my $p = shift;


    has username => ( isa => 'Str', is => 'ro', required => 1 );
    has password => ( isa => 'Str', is => 'ro', required => 1 );

    has gdata_version => (
        isa => 'Str',
        is => 'ro',
        required => 1,
        default => '2.0',
    );

    has ua => (
        isa => 'LWP::UserAgent',
        is => 'ro',
        required => 1,
        lazy_build => 1,
    );
    
    has service => (
        does => 'Net::Google::GData::Role::Service',
        is => 'ro',
        required => 1,
        lazy_build => 1,
        weak_ref => 1,
    );

    method ns => sub {
        my ($self, $name) = @_;

        return XML::Atom::Namespace->new('gd', 'http://schemas.google.com/g/2005')
            if $name eq 'gd';
        $p->ns->{$name} or croak "Namespace '$name' is not defined!";
        return XML::Atom::Namespace->new($name, $p->ns->{$name});
    };

    method _build_ua => sub {
        my $self = shift;
        my $authsub = Net::Google::AuthSub->new(
            service => $p->service,
            source => $p->source,
        );
        my $res = $authsub->login(
            $self->username,
            $self->password,
        );
        unless ($res && $res->is_success) {
            croak 'Net::Google::AuthSub login failed';
        } 
        my $ua = LWP::UserAgent->new(
            agent => $p->source,
            requests_redirectable => [],
            env_proxy => 1,
        );
        $ua->default_headers(
            HTTP::Headers->new(
                Authorization => sprintf('GoogleLogin auth=%s', $res->auth),
                GData_Version => $self->gdata_version,
            )
        );
        return $ua;
    };

    method BUILD => sub {
        my ($self) = @_;
        $self->ua; #check if login ok?
    };

    method _build_service => sub {return $_[0]};

    method request => sub {
        my ($self, $args) = @_;
        my $method = delete $args->{method};
        $method ||= $args->{content} ? 'POST' : 'GET';
        my $uri = URI->new($args->{'uri'});
        $uri->query_form($args->{query}) if $args->{query};
        my $req = HTTP::Request->new($method => "$uri");
        $req->content($args->{content}) if $args->{content};
        $req->header('Content-Type' => $args->{content_type}) if $args->{content_type};
        if ($args->{header}) {
            while (my @pair = each %{$args->{header}}) {
                $req->header(@pair);
            }
        }
        my $res = eval {$self->ua->request($req)};
        if ($ENV{DEBUG}) {
            warn $res->request->as_string;
            warn $res->as_string;
        }
        if ($@ || !$res->is_success) {
            croak sprintf(
                "request for '%s' failed:\n\t%s\n\t%s\n\t", 
                $uri, 
                $@ || $res->status_line,
                $! || $res->content
            );
        }
        my $type = $res->content_type;
        if ($res->content_length && $type !~ m{^application/atom\+xml}) {
            croak sprintf(
                "Content-Type of response for '%s' is not 'application/atom+xml':  %s",
                $uri, 
                $type
            );
        }
        if (my $res_obj = $args->{response_object}) {
            my $obj = eval {$res_obj->new(\($res->content))};
            croak sprintf(
                "response for '%s' is broken: %s", 
                $uri, 
                $@
            ) if $@;
            return $obj;
        }
        return $res;
    };

    method get_feed => sub {
        my ($self, $url, $query) = @_;
        return $self->request(
            {
                uri => $url,
                query => $query || undef,
                response_object => 'XML::Atom::Feed',
            }
        );
    };

    method get_entry => sub {
        my ($self, $url, $query) = @_;
        return $self->request(
            {
                uri => $url,
                query => $query || undef,
                response_object => 'XML::Atom::Entry',
            }
        );
    };

    method post => sub {
        my ($self, $url, $entry, $header) = @_;
        return $self->request(
            {
                uri => $url,
                content => $entry->as_xml,
                header => $header || undef,
                content_type => 'application/atom+xml',
                response_object => ref $entry,
            }
        );
    };

    method put => sub {
        my ($self, $args) = @_;
        return $self->request(
            {
                method => 'PUT',
                uri => $args->{self}->editurl,
                content => $args->{entry}->as_xml,
                header => {'If-Match' => $args->{self}->etag },
                content_type => 'application/atom+xml',
                response_object => 'XML::Atom::Entry',
            }
        );
    };

    method delete => sub {
        my ($self, $args) = @_;
        my $res = $self->request(
            {
                uri => $args->{self}->editurl,
                method => 'DELETE',
                header => {'If-Match' => $args->{self}->etag},
            }
        );
        return $res;
    };
};

1;

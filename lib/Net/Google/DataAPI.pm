package Net::Google::DataAPI;
use 5.008001;
use Any::Moose;
use Any::Moose '::Exporter';
use Carp;
use Lingua::EN::Inflect::Number qw(to_PL);
use XML::Atom;
our $VERSION = '0.10';

any_moose('::Exporter')->setup_import_methods(
    as_is => ['feedurl', 'entry_has'],
);

sub feedurl {
    my ($name, %args) = @_;

    my $class = caller;

    my $entry_class = delete $args{entry_class} 
        or confess 'entry_class not specified';
    Any::Moose::load_class($entry_class);
    my $entry_meta = any_moose('::Meta::Class')->initialize($entry_class);
    $entry_meta->does_role('Net::Google::DataAPI::Role::Entry')
        or confess "$entry_class should do Net::Google::DataAPI::Role::Entry role";

    my $can_add = delete $args{can_add};
    $can_add = 1 unless defined $can_add;

    my $arg_builder = delete $args{arg_builder}
        || sub {
            my ($self, $args) = @_;
            return $args || {};
        };

    my $query_builder = delete $args{query_builder}
        || sub {
            my ($self, $args) = @_;
            return $args || {};
        };

    my $from_atom = delete $args{from_atom};
    my $rel = delete $args{rel};
    my $as_content_src = delete $args{as_content_src};
    my $default = delete $args{default} || '';

    my $attr_name = "${name}_feedurl";

    my $class_meta = any_moose('::Meta::Class')->initialize($class);
    $class_meta->add_attribute(
        $attr_name => (
            isa => 'Str',
            is => 'ro',
            lazy_build => 1,
            %args,
        )
    );
    $class_meta->add_method(
        "_build_$attr_name" => sub {
            my $self = shift;
            return $rel ?  
            [
            map { $_->href }
            grep { $_->rel eq $rel }
            $self->atom->link
            ]->[0] :
            $as_content_src ? 
            $self->atom->content->elem->getAttribute('src') :
            $from_atom ?
            $from_atom->($self, $self->atom) : $default;
        }
    );
    my $pl_name = to_PL($name);

    if ($can_add) {
        $class_meta->add_method(
            "add_$name" => sub {
                my ($self, $args) = @_;
                $self->$attr_name or confess "$attr_name is not set";
                Any::Moose::load_class($entry_class);
                $args = $arg_builder->($self, $args);
                my %parent = 
                    $self->can('sync') ?
                    ( container => $self ) : ( service => $self );
                my $entry = $entry_class->new(
                    {
                        %parent,
                        %$args
                    }
                )->to_atom;
                my $atom = $self->service->post($self->$attr_name, $entry);
                $self->sync if $self->can('sync');
                my $e = $entry_class->new(
                    %parent,
                    atom => $atom,
                );
                return $e;
            }
        );
    }
    $class_meta->add_method(
        $pl_name => sub {
            my ($self, $cond) = @_;
            $self->$attr_name or confess "$attr_name is not set";
            Any::Moose::load_class($entry_class);
            $cond = $query_builder->($self, $cond);
            my $feed = $self->service->get_feed($self->$attr_name, $cond);
            return map {
                $entry_class->new(
                    $self->can('sync') ?
                    ( container => $self ) : ( service => $self ),
                    atom => $_,
                )
            } $feed->entries;
        }
    );
    $class_meta->add_method(
        $name => sub {
            my ($self, $cond) = @_;
            return [ $self->$pl_name($cond) ]->[0];
        }
    );

}

sub entry_has {
    my ($name, %args) = @_;

    my $class = caller;
    my $class_meta = any_moose('::Meta::Class')->initialize($class);
    $class_meta->does_role('Net::Google::DataAPI::Role::Entry') 
        or confess 'Net::Google::DataAPI::Role::Entry required to use entry_has';

    my $tagname = delete $args{tagname};
    my $ns = delete $args{ns};

    my $from_atom = delete $args{from_atom};
    my $to_atom = delete $args{to_atom};

    $class_meta->add_attribute(
        $name => (
            isa => 'Str',
            is => 'ro',
            $to_atom || $tagname ?  (
                trigger => sub {$_[0]->update }
            ) : (),
            $tagname || $from_atom ? (
                lazy_build => 1,
            ) : (),
            %args,
        )
    );
    if ($tagname) {
        $class_meta->add_around_method_modifier(
            to_atom => sub {
                my ($next, $self) = @_;
                my $entry = $next->($self);
                my $ns_obj = $ns ? $self->ns($ns) : $entry->ns;
                $entry->set($ns_obj, $tagname, $self->$name) if $self->$name;
                return $entry;
            }
        );
        $class_meta->add_method(
            "_build_$name" => sub {
                my $self = shift;
                $self->atom or return '';
                my $ns_obj = $ns ? $self->ns($ns) : $self->atom->ns;
                return $self->atom->get($ns_obj, $tagname);
            }
        );
    }
    if ($to_atom) {
        $class_meta->add_around_method_modifier(
            to_atom => sub {
                my ($next, $self) = @_;
                my $entry = $next->($self);
                $to_atom->($self, $entry) if $self->$name;
                return $entry;
            }
        );
    }
    if ($from_atom) {
        $class_meta->add_method(
            "_build_$name" => sub {
                my $self = shift;
                $self->atom or return '';
                return $from_atom->($self, $self->atom);
            }
        );
    }
}

1;
__END__

=head1 NAME

Net::Google::DataAPI - Base implementations for modules to negotiate with Google Data APIs

=head1 SYNOPSIS

  package MyService;
  use Any::Moose;
  use Net::Google::DataAPI;

  with 'Net::Google::DataAPI::Role::Service' => {
      service => 'foobar', 
        # see http://code.google.com/intl/ja/apis/gdata/faq.html#clientlogin
      source => __PACKAGE__,
        # source name to pass to Net::Google::AuthSub
      ns => {
          foobar => 'http://example.com/schema#foobar',
      }
        # registering xmlns
  };

  # registering feed url
  feedurl myentry => (
      entry_class => 'MyEntry',
        # class name for the entry
      default => 'http://example.com/myfeed',
  );

  1;

  package MyEntry;
  use Any::Moose;
  use Net::Google::DataAPI;
  with 'Net::Google::DataAPI::Role::Entry';

  entry_has some_value => (
      is => 'rw',
      isa => 'Str',
        # tagname
      tagname => 'some_value',
        # namespace
      namespace => 'gd',
  );

  1;

=head1 DESCRIPTION

Net::Google::DataAPI is base implementations for modules to negotiate with Google Data APIs. 

=head1 METHODS

=head2 feedurl

define a feed url. 

=head2 entry_has

define a entry attribute.

=head1 DEBUGGING

You can set environment variable GOOGLE_DATAAPI_DEBUG=1 to see the raw requests and responses Net::Google::DataAPI sends and receives.

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=head1 TODO

more pods.

=head1 SEE ALSO

L<Net::Google::AuthSub>

L<Net::Google::DataAPI::Role::Service>

L<Net::Google::DataAPI::Role::Entry>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

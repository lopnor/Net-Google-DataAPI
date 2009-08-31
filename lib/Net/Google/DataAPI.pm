package Net::Google::DataAPI;
use 5.008001;
use Moose ();
use Moose::Exporter;
use Carp;
use Lingua::EN::Inflect::Number qw(to_PL);
our $VERSION = '0.02';

Moose::Exporter->setup_import_methods(
    with_caller => ['feedurl', 'entry_has'],
);

sub feedurl {
    my ($caller, $name, %args) = @_;

    my $class = Class::MOP::class_of($caller);
    $class->does_role('Net::Google::DataAPI::Role::Entry') 
        or $class->does_role('Net::Google::DataAPI::Role::Service')
        or confess 'Net::Google::DataAPI::Role::(Service|Entry) required to use feedurl';

    my $entry_class = delete $args{entry_class} 
        or confess 'entry_class not specified';
    Class::MOP::load_class($entry_class)->does_role('Net::Google::DataAPI::Role::Entry')
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

    my $attr_name = "${name}_feedurl";

    $class->add_attribute(
        $attr_name => (
            isa => 'Str',
            is => 'ro',
            %args,
        )
    );
    my $pl_name = to_PL($name);

    if ($can_add) {
        $class->add_method(
            "add_$name" => sub {
                my ($self, $args) = @_;
                $self->$attr_name or confess "$attr_name is not set";
                Class::MOP::load_class($entry_class);
                $args = $arg_builder->($self, $args);
                my %parent = 
                    $class->does_role('Net::Google::DataAPI::Role::Entry') ?
                    ( container => $self ) : ( service => $self );
                my $entry = $entry_class->new(
                    {
                        %parent,
                        %$args
                    }
                )->to_atom;
                my $atom = $self->service->post($self->$attr_name, $entry);
                $self->sync if $class->does_role('Net::Google::DataAPI::Role::Entry');
                my $e = $entry_class->new(
                    %parent,
                    atom => $atom,
                );
                return $e;
            }
        );
    }
    $class->add_method(
        $pl_name => sub {
            my ($self, $cond) = @_;
            $self->$attr_name or confess "$attr_name is not set";
            Class::MOP::load_class($entry_class);
            $cond = $query_builder->($self, $cond);
            my $feed = $self->service->get_feed($self->$attr_name, $cond);
            return map {
                $entry_class->new(
                    $class->does_role('Net::Google::DataAPI::Role::Entry') ?
                    ( container => $self ) : ( service => $self ),
                    atom => $_,
                )
            } $feed->entries;
        }
    );
    $class->add_method(
        $name => sub {
            my ($self, $cond) = @_;
            return [ $self->$pl_name($cond) ]->[0];
        }
    );

    if ( $class->find_method_by_name('from_atom') ) {
        $class->add_after_method_modifier(
            'from_atom' => sub {
                my ($self) = @_;
                $self->{$attr_name} = 
                    $rel ?  
                        [
                            map { $_->href }
                            grep { $_->rel eq $rel }
                            $self->atom->link
                        ]->[0] :
                    $as_content_src ? 
                        $self->atom->content->elem->getAttribute('src') :
                    $from_atom ?
                        $from_atom->($self->atom) : undef;
            }
        );
    }
}

sub entry_has {
    my ($caller, $name, %args) = @_;

    my $class = Class::MOP::class_of($caller);
    $class->does_role('Net::Google::DataAPI::Role::Entry') 
        or confess 'Net::Google::DataAPI::Role::Entry required to use entry_has';

    my $from_atom = delete $args{from_atom};
    my $to_atom = delete $args{to_atom};

    $class->add_attribute(
        $name => (
            isa => 'Str',
            is => 'ro',
            $to_atom ? 
                (trigger => sub {$_[0]->update }) : (),
            %args,
        )
    );
    if ($to_atom) {
        $class->add_around_method_modifier(
            to_atom => sub {
                my ($next, $self) = @_;
                my $entry = $next->($self);
                $to_atom->($self, $entry) if $self->$name;
                return $entry;
            }
        );
    }
    if ($from_atom) {
        $class->add_after_method_modifier(
            from_atom => sub {
                my $self = shift;
                $self->{$name} = $from_atom->($self, $self->atom);
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
  use Moose;
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

  feedurl myentry => (
      entry_class => 'MyEntry',
      default => 'http://example.com/myfeed',
  );

  1;


  package MyEntry;
  use Moose;

=head1 DESCRIPTION

Net::Google::DataAPI is base implementations for modules to negotiate with Google Data APIs. 

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=head1 SEE ALSO

L<Net::Google::AuthSub>

L<Net::Google::DataAPI::Role::Service>

L<Net::Google::DataAPI::Role::Entry>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

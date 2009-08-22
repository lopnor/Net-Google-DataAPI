package Net::Google::GData;
use 5.008001;
use Moose ();
use Moose::Exporter;
use Carp;
use Lingua::EN::Inflect::Number qw(to_PL);
our $VERSION = '0.02';

Moose::Exporter->setup_import_methods(
    with_caller => ['feedurl'],
    also => 'Moose',
);

sub feedurl {
    my ($caller, $name, %args) = @_;
    my $class = Class::MOP::class_of($caller);
    my $entry_class = delete $args{entry_class} 
        or croak 'entry_class not specified';
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

    my $attr_name = "${name}_feedurl";

    $class->add_attribute(
        $attr_name => (
            isa => 'Str',
            is => 'ro',
            %args,
        )
    );

    if ($can_add) {
        $class->add_method(
            "add_$name" => sub {
                my ($self, $args) = @_;
                $self->$attr_name or return;
                Class::MOP::load_class($entry_class);
                $args = $arg_builder->($self, $args);
                my $entry = $entry_class->new($args)->to_atom;
                my $atom = $self->service->post($self->$attr_name, $entry);
                $self->sync;
                return $entry_class->new(
                    container => $self,
                    atom => $atom,
                );
            }
        );
    }
    my $pl_name = to_PL($name);
    $class->add_method(
        $pl_name => sub {
            my ($self, $cond) = @_;
            $self->$attr_name or return;
            Class::MOP::load_class($entry_class);
            $cond = $query_builder->($self, $cond);
            my $feed = $self->service->get_feed($self->$attr_name, $cond);
            return map {
                $entry_class->new(
                    container => $self,
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

    if ( $class->find_method_by_name('from_atom') && $from_atom ) {
        $class->add_after_method_modifier(
            'from_atom' => sub {
                my ($self) = @_;
                $self->{$attr_name} = $from_atom->($self->atom);
            }
        );
    }
}

1;
__END__

=head1 NAME

Net::Google::GData -

=head1 SYNOPSIS

  use Net::Google::GData;

=head1 DESCRIPTION

Net::Google::GData is

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

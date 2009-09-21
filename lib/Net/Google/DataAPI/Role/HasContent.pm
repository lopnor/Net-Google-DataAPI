package Net::Google::DataAPI::Role::HasContent;
use Moose::Role;
use namespace::clean -except => 'meta';

requires 'update';

has content => (
    isa => 'HashRef',
    is => 'rw',
    default => sub { +{} },
    trigger => sub { $_[0]->update },
);

sub param {
    my ($self, $arg) = @_;
    return $self->content unless $arg;
    if (ref $arg eq 'HASH') {
        return $self->content(
            {
                %{$self->content},
                %$arg,
            }
        );
    } else {
        return $self->content->{$arg};
    }
}

1;

__END__

=pod

=head1 NAME

Net::Google::DataAPI::Role::HasContent - provides 'param' method to Entry

=head1 SYNOPSIS

    package MyEntry;
    use Moose;
    with qw(
        Net::Google::DataAPI::Role::Entry
        Net::Google::DataAPI::Role::HasContent
    );

    1;

=head1 DESCRIPTION

Net::Google::DataAPI::Role::HasContent provides 'param' method to Entry.

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

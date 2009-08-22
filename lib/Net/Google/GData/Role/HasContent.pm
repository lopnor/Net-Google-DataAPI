package Net::Google::GData::Role::HasContent;
use Moose::Role;
use namespace::clean -except => 'meta';

has content => (
    isa => 'HashRef',
    is => 'rw',
    default => sub { +{} },
    trigger => sub { $_[0]->update },
);

sub param {
    my ($self, $arg) = @_;
    return $self->content unless $arg;
    if (ref $arg && (ref $arg eq 'HASH')) {
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

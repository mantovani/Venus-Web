package Venues::Web::Model::DB;

use Moose;
BEGIN { extends 'Catalyst::Model::MongoDB' }

__PACKAGE__->config(
    host           => '127.0.0.1',
    port           => '27017',
    dbname         => 'BigData',
    collectionname => '',
    gridfs         => '',
);

has 'fq' => (
    is      => 'ro',
    isa     => 'Any',
    lazy    => 1,
    default => sub { shift->collection('PlacesFoursquare') }
);
has 'csp' => (
    is      => 'ro',
    isa     => 'Any',
    lazy    => 1,
    default => sub { shift->collection('ComplaintsSP') }
);

sub search {
    my ( $self, $param ) = @_;
    return $self->fq->find(
        { name => qr/$param/i, addr_cksum => { '$exists' => 1 } } )
      ->sort( { 'stats.checkinsCount' => -1 } );
}

sub claim {
    my ( $self, $id ) = @_;
    return $self->csp->find( { addr_cksum => int($id) } );
}

sub claim_count {
    my ( $self, $id ) = @_;
    return $self->csp->count( { addr_cksum => int($id) } );
}

=head1 NAME

Venues::Web::Model::DB - MongoDB Catalyst model component

=head1 SYNOPSIS

See L<Venues::Web>.

=head1 DESCRIPTION

MongoDB Catalyst model component.

=head1 AUTHOR

root

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

1;

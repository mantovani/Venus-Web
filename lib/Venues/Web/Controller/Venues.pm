package Venues::Web::Controller::Venues;
use Moose;
use namespace::autoclean;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Venues::Web::Controller::Venues - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub base : Chained('/') : PathPart('Venues') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{mongo_id}    = sub { $_[0]->{_id}->value };
    $c->stash->{data_dump}   = sub { print Dumper \@_ };
    $c->stash->{claim_count} = sub { $c->model('DB')->claim_count(shift) };
}

sub index : Chained('base') PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
}

sub search : Chained('base') : PathParty('search') : Args(0) {
    my ( $self, $c ) = @_;
    if ( $c->request->parameters->{search} =~ /\w+/ ) {
        $c->stash->{search_res} =
          $c->model('DB')->search( $c->req->parameters->{search} );
    }
}

sub claims : Chained('base') : ParhParty('claims') : Args(1) {
    my ( $self, $c, $id ) = @_;
    if ( $id =~ /\d+/ ) {
        $c->stash->{search_res} = $c->model('DB')->claim($id);
    }
}

=encoding utf8

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

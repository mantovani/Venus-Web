package Venues::Web::View::TT;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config({
    INCLUDE_PATH => [
        Venues::Web->path_to( 'root', 'src' ),
        Venues::Web->path_to( 'root', 'lib' )
    ],
    PRE_PROCESS  => 'config/main',
    WRAPPER      => 'site/wrapper',
    ERROR        => 'error.tt2',
    TIMER        => 0,
    render_die   => 1,
});

=head1 NAME

Venues::Web::View::TT - Catalyst TTSite View

=head1 SYNOPSIS

See L<Venues::Web>

=head1 DESCRIPTION

Catalyst TTSite View.

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;


use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Venues::Web';
use Venues::Web::Controller::Venues;

ok( request('/venues')->is_success, 'Request should succeed' );
done_testing();

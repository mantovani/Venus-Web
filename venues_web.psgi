use strict;
use warnings;

use Venues::Web;

my $app = Venues::Web->apply_default_middlewares(Venues::Web->psgi_app);
$app;


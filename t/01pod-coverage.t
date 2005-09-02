#!perl -w

use strict;
use warnings;

use Test::More;

eval "use Test::Pod::Coverage 1.00";
if ( $@ ) {
    plan skip_all =>
        "Test::Pod::Coverage 1.00 required for testing POD coverage";
}
all_pod_coverage_ok();

# vim: set ai et sw=4 syntax=perl :

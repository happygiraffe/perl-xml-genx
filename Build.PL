#!/usr/bin/perl -w
# @(#) $Id$

use strict;
use Module::Build;

# The next release of Module::Build contains a fix that we need.
# http://sourceforge.net/mailarchive/forum.php?thread_id=6080058&forum_id=10905
my %build_requires;
$build_requires{ 'Module::Build' } = 0.27
    if $^O eq 'MSWin32';

Module::Build->new(
    module_name        => 'XML::Genx',
    license            => 'bsd',
    requires           => { perl => '5.6.1' },
    build_requires     => \%build_requires,
    create_makefile_pl => 'passthrough',
    c_source           => 'src',
)->create_build_script;


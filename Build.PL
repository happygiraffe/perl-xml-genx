#!/usr/bin/perl -w
# @(#) $Id$

use strict;
use Module::Build;

my %build_requires;
if ($^O eq 'MSWin32') {
    # This release of Module::Build contains a fix that we need.
    # http://sourceforge.net/mailarchive/forum.php?thread_id=6080058&forum_id=10905
    $build_requires{ 'Module::Build' } = 0.2606;
    # Unfortunately, the author doesn't have ready access to a win32
    # development environment, and needs assistance...
    warn <<MSG;

** This module is not yet tested under Win32.  If you encounter
** problems, please contact the author, giving as much detail about the
** failure and build process as possible.

MSG
}

Module::Build->new(
    module_name        => 'XML::Genx',
    license            => 'bsd',
    requires           => { perl => '5.6.1' },
    recommends         => { 'XML::SAX::Base' => 0 },
    build_requires     => \%build_requires,
    create_makefile_pl => 'passthrough',
    c_source           => 'src',
)->create_build_script;


#!/usr/bin/perl -w
# @(#) $Id$

use strict;
use Module::Build;

Module::Build->new(
    module_name        => 'XML::Genx',
    license            => 'perl',
    requires           => { 'perl' => '5.6.1', },
    create_makefile_pl => 'passthrough',
    c_source           => 'src',
)->create_build_script;


#!/usr/bin/perl -w
# @(#) $Id: XML-Genx.t 903 2004-12-04 19:22:09Z dom $

use strict;
use warnings;

use Test::More tests => 5;

use_ok( 'XML::Genx::Simple' );

my $w = XML::Genx::Simple->new();
isa_ok( $w, 'XML::Genx' );
can_ok( $w, qw( Element ) );

my $out = '';
eval {
    $w->StartDocSender( sub { $out .= $_[0] } );
    $w->StartElementLiteral( 'root' );
    $w->Element( foo => 'bar', id => 1 );
    $w->Element( bar => 'baz', id => 2 );
    $w->EndElement;
    $w->EndDocument;
};
is( $@, '', 'That went well.' );
is( $out, '<root><foo id="1">bar</foo><bar id="2">baz</bar></root>',
    'Element()' );

# vim: set ai et sw=4 syntax=perl :

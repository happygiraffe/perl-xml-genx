#!/usr/bin/perl -w

use strict;
use warnings;

use File::Temp qw( tempfile );
use Test::More tests => 18;

use_ok('XML::Genx');

my $w = XML::Genx->new();
isa_ok( $w, 'XML::Genx' );
can_ok( $w, qw(
    StartDocFile
    LastErrorMessage
    GetErrorMessage
    StartElementLiteral
    EndElement
    EndDocument
    Comment
    PI
) );

is(
    test_basics(),
    '<!--hello world-->
<?ping pong?>
<g1:foo xmlns:g1="urn:foo">bar</g1:foo>',
    'test_basics() output'
);

is(
    test_empty_namespace(),
    '<foo></foo>',
    'test_empty_namespace() output',
);

is(
    test_undef_namespace(),
    '<foo></foo>',
    'test_undef_namespace() output',
);

sub test_basics {
    my $fh = tempfile();
    is( $w->StartDocFile( $fh ),  0,         'StartDocFile(fh)' );
    is( $w->EndElement,       0, 'EndElement()' );
    is( $w->EndDocument,      0, 'EndDocument()' );
    return fh_contents( $fh );
    is( $w->LastErrorMessage,     'Success', 'LastErrorMessage()' );
    is( $w->GetErrorMessage( 0 ), 'Success', 'GetErrorMessage(0)' );

    is( $w->Comment( 'hello world' ), 0, 'Comment(hello world)' );
    is( $w->PI( qw( ping pong ) ), 0, 'PI(ping pong)' );
    is( $w->StartElementLiteral( 'urn:foo', 'foo' ),
        0, 'StartElementLiteral(urn:foo,foo)' );
    is( $w->AddText( 'bar' ), 0, 'AddText(bar)' );
    is( $w->EndElement,       0, 'EndElement()' );
    is( $w->EndDocument,      0, 'EndDocument()' );
    return fh_contents( $fh );
}

sub test_empty_namespace {
    my $fh = tempfile();
    is( $w->StartDocFile( $fh ), 0, 'StartDocFile(fh)' );
    is(
        $w->StartElementLiteral( '', 'foo' ), 0,
        'StartElementLiteral("",foo)'
    );
    is( $w->EndElement,  0, 'EndElement()' );
    is( $w->EndDocument, 0, 'EndDocument()' );
    return fh_contents( $fh );
}

sub test_undef_namespace {
    my $fh = tempfile();
    is( $w->StartDocFile( $fh ), 0, 'StartDocFile(fh)' );
    is(
        $w->StartElementLiteral( undef, 'foo' ), 0,
        'StartElementLiteral(undef,foo)'
    );
    is( $w->EndElement,  0, 'EndElement()' );
    is( $w->EndDocument, 0, 'EndDocument()' );
    return fh_contents( $fh );
}

sub fh_contents {
    my $fh = shift;
    seek $fh, 0, 0 or die "seek: $!\n";
    local $/;
    return <$fh>;
}

# vim: set ai et sw=4 syntax=perl :

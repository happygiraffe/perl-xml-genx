#!/usr/bin/perl -w
# @(#) $Id$

use strict;
use warnings;

use File::Temp qw( tempfile );
use Test::More tests => 31;

use_ok('XML::Genx');

my $w = XML::Genx->new();
isa_ok( $w, 'XML::Genx' );
can_ok( $w, qw(
    GetVersion
    StartDocFile
    LastErrorMessage
    GetErrorMessage
    StartElementLiteral
    AddAttributeLiteral
    EndElement
    EndDocument
    Comment
    PI
    DeclareNamespace
) );

# Subtly different to VERSION()...
is( XML::Genx->GetVersion, 'beta5', 'GetVersion()' );

is(
    test_basics(),
    '<!--hello world-->
<?ping pong?>
<g1:foo xmlns:g1="urn:foo" g1:baz="quux">bar!</g1:foo>',
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

test_bad_filehandle();
test_declare_namespace();

sub test_basics {
    my $w = XML::Genx->new();
    my $fh = tempfile();
    is( $w->StartDocFile( $fh ),  0,         'StartDocFile(fh)' );
    is( $w->LastErrorMessage,     'Success', 'LastErrorMessage()' );
    is( $w->GetErrorMessage( 0 ), 'Success', 'GetErrorMessage(0)' );

    is( $w->Comment( 'hello world' ), 0, 'Comment(hello world)' );
    is( $w->PI( qw( ping pong ) ), 0, 'PI(ping pong)' );
    is( $w->StartElementLiteral( 'urn:foo', 'foo' ),
        0, 'StartElementLiteral(urn:foo,foo)' );
    is( $w->AddAttributeLiteral( 'urn:foo', 'baz', 'quux' ),
        0, 'AddAttributeLiteral(urn:foo,baz,quux)' );
    is( $w->AddText( 'bar' ), 0, 'AddText(bar)' );
    is( $w->AddCharacter( ord( "!" ) ), 0, 'AddCharacter(ord(!))' );
    is( $w->EndElement,       0, 'EndElement()' );
    is( $w->EndDocument,      0, 'EndDocument()' );
    return fh_contents( $fh );
}

sub test_empty_namespace {
    my $w = XML::Genx->new();
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
    my $w = XML::Genx->new();
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

sub test_bad_filehandle {
  SKIP: {
        skip 'Need perl 5.8 for in memory file handles.', 1
          if $] < 5.008;

        my $txt = '';
        open( my $fh, '>', \$txt ) or die "open(>\$txt): $!\n";
        my $w = XML::Genx->new;
        eval { $w->StartDocFile( $fh ) };
        like( $@, qr/Bad filehandle/i, 'StartDocFile(bad filehandle)' );
    }
}

sub test_declare_namespace {
    my $w = XML::Genx->new();
    my $ns = $w->DeclareNamespace( 'urn:foo', 'foo' );
    is( $w->LastErrorMessage, 'Success', 'DeclareNamespace()' );
    isa_ok( $ns, 'XML::Genx::Namespace' );
    can_ok( $ns, qw( GetNamespacePrefix ) );
    # This will return undef until we've actually written some XML...
    is( $ns->GetNamespacePrefix, undef, 'GetNamespacePrefix()' );
}

sub fh_contents {
    my $fh = shift;
    seek $fh, 0, 0 or die "seek: $!\n";
    local $/;
    return <$fh>;
}

# vim: set ai et sw=4 syntax=perl :

#!/usr/bin/perl -w
# @(#) $Id$

use strict;
use warnings;

use File::Temp qw( tempfile );
use Test::More tests => 95;

BEGIN {
    use_ok( 'XML::Genx' );
    use_ok( 'XML::Genx::Constants', qw( GENX_SUCCESS GENX_SEQUENCE_ERROR ) );
}

my $w = XML::Genx->new();
isa_ok( $w, 'XML::Genx' );
can_ok( $w, qw(
    GetVersion
    StartDocFile
    StartDocSender
    LastErrorMessage
    GetErrorMessage
    StartElementLiteral
    AddAttributeLiteral
    EndElement
    EndDocument
    Comment
    PI
    DeclareNamespace
    DeclareElement
    DeclareAttribute
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
    '<foo bar="baz"></foo>',
    'test_empty_namespace() output',
);

is(
    test_undef_namespace(),
    '<foo bar="baz"></foo>',
    'test_undef_namespace() output',
);

is(
    test_no_namespace(),
    '<foo bar="baz"></foo>',
    'test_no_namespace() output',
);

test_bad_filehandle();
test_declare_namespace();
test_declare_element();
test_declare_attribute();

is(
    test_declared_in_use(),
    '<foo:bar xmlns:foo="urn:foo" foo:baz="quux"></foo:bar>',
    'test_declared_in_use() output',
);

is(
    test_declared_no_namespace(),
    '<bar baz="quux"></bar>',
    'test_declared_no_namespace() output',
);

is(
    test_declared_with_namespace(),
    '<el xmlns="http://example.com/#ns" xmlns:g1="http://example.com/#ns2" g1:at="val"></el>',
    'test_declared_with_namespace() output',
);

is(
    test_sender(),
    "<foo>\x{0100}dam</foo>",
    'test_sender() output',
);

test_die_on_error();
test_constants();
test_fh_scope();
test_scrubtext();

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
    my $w  = XML::Genx->new();
    my $fh = tempfile();
    is( $w->StartDocFile( $fh ), 0, 'StartDocFile(fh)' );
    is(
        $w->StartElementLiteral( '', 'foo' ), 0,
        'StartElementLiteral("",foo)'
    );
    is(
        $w->AddAttributeLiteral( '', bar => 'baz' ), 0,
        'AddAttributeLiteral()'
    );
    is( $w->EndElement,  0, 'EndElement()' );
    is( $w->EndDocument, 0, 'EndDocument()' );
    return fh_contents( $fh );
}

sub test_undef_namespace {
    my $w  = XML::Genx->new();
    my $fh = tempfile();
    is( $w->StartDocFile( $fh ), 0, 'StartDocFile(fh)' );
    is(
        $w->StartElementLiteral( undef, 'foo' ), 0,
        'StartElementLiteral(undef,foo)'
    );
    is(
        $w->AddAttributeLiteral( undef, bar => 'baz' ), 0,
        'AddAttributeLiteral()'
    );
    is( $w->EndElement,  0, 'EndElement()' );
    is( $w->EndDocument, 0, 'EndDocument()' );
    return fh_contents( $fh );
}

sub test_no_namespace {
    my $w  = XML::Genx->new();
    my $fh = tempfile();
    is( $w->StartDocFile( $fh ), 0, 'StartDocFile(fh)' );
    is( $w->StartElementLiteral( 'foo' ), 0, 'StartElementLiteral(foo)' );
    is( $w->AddAttributeLiteral( bar => 'baz' ), 0, 'AddAttributeLiteral()' );
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
    can_ok( $ns, qw( GetNamespacePrefix AddNamespace ) );
    # This will return undef until we've actually written some XML...
    is( $ns->GetNamespacePrefix, undef, 'GetNamespacePrefix()' );
}

sub test_declare_element {
    my $w = XML::Genx->new();
    my $ns = $w->DeclareNamespace( 'urn:foo', 'foo' );
    my $el = $w->DeclareElement( $ns, 'wibble' );
    is( $w->LastErrorMessage, 'Success', 'DeclareElement()' );
    isa_ok( $el, 'XML::Genx::Element' );
    can_ok( $el, qw( StartElement ) );

    my $el2 = $w->DeclareElement( 'wobble' );
    isa_ok( $el2, 'XML::Genx::Element' );
}

sub test_declare_attribute {
    my $w = XML::Genx->new();
    my $ns = $w->DeclareNamespace( 'urn:foo', 'foo' );
    my $at = $w->DeclareAttribute( $ns, 'wobble' );
    is( $w->LastErrorMessage, 'Success', 'DeclareAttribute()' );
    isa_ok( $at, 'XML::Genx::Attribute' );
    can_ok( $at, qw( AddAttribute ) );

    my $at2 = $w->DeclareAttribute( 'weebl' );
    isa_ok( $at2, 'XML::Genx::Attribute' );
}

sub test_declared_in_use {
    my $w = XML::Genx->new();
    my $ns = $w->DeclareNamespace( 'urn:foo', 'foo' );
    my $el = $w->DeclareElement( $ns, 'bar' );
    my $at = $w->DeclareAttribute( $ns, 'baz' );
    my $fh = tempfile();

    is( $w->StartDocFile( $fh ), 0, 'StartDocFile()' );
    is( $el->StartElement(), 0, 'StartElement()' );
    is( $at->AddAttribute( 'quux' ), 0, 'AddAttribute()' );
    is( $w->EndElement(), 0, 'EndElement()' );
    is( $w->EndDocument(), 0, 'EndDocument()' );
    return fh_contents( $fh );
}

sub test_declared_no_namespace {
    my $w = XML::Genx->new();
    my $el = $w->DeclareElement( undef, 'bar' );
    my $at = $w->DeclareAttribute( undef, 'baz' );
    my $fh = tempfile();

    is( $w->StartDocFile( $fh ), 0, 'StartDocFile()' );
    is( $el->StartElement(), 0, 'StartElement()' );
    is( $at->AddAttribute( 'quux' ), 0, 'AddAttribute()' );
    is( $w->EndElement(), 0, 'EndElement()' );
    is( $w->EndDocument(), 0, 'EndDocument()' );
    return fh_contents( $fh );
}

sub test_declared_with_namespace {
    my $w = XML::Genx->new();

    # Default prefix for this namespace is "foo".
    my $nsurl = 'http://example.com/#ns';
    my $ns    = $w->DeclareNamespace( $nsurl, 'foo' );

    # Ask genx to generate a default prefix here.
    my $ns2url = 'http://example.com/#ns2';
    my $ns2    = $w->DeclareNamespace( $ns2url );

    my $fh = tempfile();
    is( $w->StartDocFile( $fh ), 0, 'StartDocFile()' );
    is( $w->StartElementLiteral( $nsurl, 'el' ), 0, 'StartElement(el)' );

    # Override and attempt to make it the default namespace.
    is( $ns->AddNamespace( '' ), 0, 'AddNamespace("")' )
        or diag $w->LastErrorMessage;

    # Let it keep whatever prefix genx allocated.
    is( $ns2->AddNamespace(), 0, 'AddNamespace()' )
        or diag $w->LastErrorMessage;
    is(
        $w->AddAttributeLiteral( $ns2url, at => 'val' ), 0,
        'AddAttributeLiteral(ns2url,at,val)'
    );
    is( $w->EndElement(),  0, 'EndElement()' );
    is( $w->EndDocument(), 0, 'EndDocument()' );
    return fh_contents( $fh );
}

sub test_sender {
    my $out = '';
    my $w   = XML::Genx->new;
    is( $w->StartDocSender( sub { $out .= $_[0] } ), 0, 'StartDocSender()' );
    is(
        $w->StartElementLiteral( undef, 'foo' ), 0,
        'StartElementLiteral(undef,foo)'
    );
    is( $w->AddText( "\x{0100}dam" ), 0, 'AddText(*utf8*)' );
    is( $w->EndElement,  0, 'EndElement()' );
    is( $w->EndDocument, 0, 'EndDocument()' );
    return $out;
}

sub test_die_on_error {
    my $w = XML::Genx->new;
    cmp_ok( $w->LastErrorCode, '==', 0, 'LastErrorCode() after new()' );
    eval { $w->EndDocument };
    like( $@, qr/^Call out of sequence/, 'EndDocument() sequence error' )
        or diag $@;

    # This is needed because I originally wrote a version that used
    # exception objects where I shouldn't have.  Now that I've switched
    # to plain strings, I expect them to report where they have croaked.
    my $thisfile = __FILE__;
    like( $@, qr/ at $thisfile/, 'Exception reports location.' );

    # This is the new way to determine more exactly what happened.
    cmp_ok( $w->LastErrorCode, '==', 8, 'LastErrorCode() after an exception.' );

    $w = XML::Genx->new;        # Clear error status.
    eval {
        my $ns = $w->DeclareNamespace( 'urn:foo', 'foo' );
        isa_ok( $ns, 'XML::Genx::Namespace' );
        $ns->AddNamespace();
    };
    like( $@, qr/^Call out of sequence/, 'ns->AddNamespace() sequence error' );
    cmp_ok( $w->LastErrorCode, '==', 8, 'LastErrorCode() after an exception.' );

    $w = XML::Genx->new;        # Clear error status.
    eval {
        my $el = $w->DeclareElement( 'foo' );
        isa_ok( $el, 'XML::Genx::Element' );
        $el->StartElement();
    };
    like( $@, qr/^Call out of sequence/, 'el->StartElement() sequence error' );
    cmp_ok( $w->LastErrorCode, '==', 8, 'LastErrorCode() after an exception.' );

    $w = XML::Genx->new;        # Clear error status.
    eval {
        my $at = $w->DeclareAttribute( 'foo' );
        isa_ok( $at, 'XML::Genx::Attribute' );
        $at->AddAttribute( 'bar' );
    };
    like( $@, qr/^Call out of sequence/, 'at->AddAttribute() sequence error' );
    cmp_ok( $w->LastErrorCode, '==', 8, 'LastErrorCode() after an exception.' );

}

sub test_constants {
    my $w = XML::Genx->new;
    is( GENX_SUCCESS, 0, 'GENX_SUCCESS' );
    eval { $w->EndDocument };
    cmp_ok( $w->LastErrorCode, '==', GENX_SEQUENCE_ERROR,
        'GENX_SEQUENCE_ERROR' );
}

sub test_fh_scope {
    my $w = XML::Genx->new;
    {
        my $fh = tempfile();
        is( $w->StartDocFile( $fh ), 0, 'StartDocFile()' );
    }
    is( $w->StartElementLiteral( 'foo' ), 0, 'StartElementLiteral(foo)' );
    is( $w->EndElement, 0, 'EndElement()' );
    is( $w->EndDocument, 0, 'EndDocument()' );
    # We don't actually care what's been written at this point.  Just
    # that it *has* been written without blowing up.
    return;
}

sub test_scrubtext {
    my $w = XML::Genx->new();
    is( $w->ScrubText( "abc" ),     "abc", 'ScrubText() all good' );
    is( $w->ScrubText( "abc\x01" ), "abc", 'ScrubText() skips non-xml chars' );
}

sub fh_contents {
    my $fh = shift;
    seek $fh, 0, 0 or die "seek: $!\n";
    local $/;
    return <$fh>;
}

# vim: set ai et sw=4 syntax=perl :

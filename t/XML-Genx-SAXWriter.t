#!/usr/bin/perl -w
# @(#) $Id$

use strict;
use warnings;

use File::Temp qw( tempfile );
use Test::More;
use XML::Genx::Constants qw( GENX_SUCCESS );

eval "use XML::SAX::Base";
if ( $@ ) {
    plan skip_all => 'Need XML::SAX::Base to run this test.';
} else {
    plan tests => 12;
}

use_ok( 'XML::Genx::SAXWriter' );

my $w = XML::Genx::SAXWriter->new();
isa_ok( $w, 'XML::Genx::SAXWriter' );
my @sax_methods = qw(
    start_document
    end_document
    start_element
    start_document
    end_document
    start_element
    end_element
    characters
    processing_instruction
    start_prefix_mapping
    end_prefix_mapping
);
can_ok( $w, @sax_methods );

test_simple();
test_namespaces();
test_misc();
test_send_to_fh();
test_send_to_filename();
test_send_to_sub();

sub test_simple {
    my $str;
    my $w = XML::Genx::SAXWriter->new( out => \$str );
    $w->start_document( {} );
    my $el = {
        Attributes => {
            '{}attr' => {
                LocalName    => 'attri',
                Name         => 'attri',
                NamespaceURI => '',
                Prefix       => '',
                Value        => 'bute',
            },
        },
        LocalName    => 'foo',
        Name         => 'foo',
        NamespaceURI => '',
        Prefix       => '',
    };
    $w->start_element( $el );
    $w->characters( { Data => 'bar' } );
    $w->end_element( $el );
    is( $w->end_document( {} ), GENX_SUCCESS, 'simple end_document()' );
    is( $str, qq{<foo attri="bute">bar</foo>}, 'simple output' );
}

sub test_namespaces {
    my $str;
    my $w = XML::Genx::SAXWriter->new( out => \$str );
    $w->start_document( {} );
    my $ns_default = {
        Prefix => '',
        NamespaceURI => 'http://example.com/ns1',
    };
    my $ns_other = {
        Prefix => 'ns2',
        NamespaceURI => 'http://example.com/ns2',
    };
    my $el = {
        Attributes => {
            '{}attr' => {
                LocalName    => 'nons',
                Name         => 'nons',
                NamespaceURI => '',
                Prefix       => '',
                Value        => '',
            },
            "{$ns_other->{NamespaceURI}}attr" => {
                LocalName    => 'attr',
                Name         => "$ns_other->{Prefix}:nsattr",
                NamespaceURI => $ns_other->{ NamespaceURI },
                Prefix       => $ns_other->{ Prefix },
                Value        => '',
            },
        },
        LocalName    => 'foo',
        Name         => 'foo',
        NamespaceURI => $ns_default->{ NamespaceURI },
        Prefix       => '',
    };
    $w->start_prefix_mapping( $ns_default );
    $w->start_prefix_mapping( $ns_other );
    $w->start_element( $el );
    $w->end_element( $el );
    $w->end_prefix_mapping( $ns_other );
    $w->end_prefix_mapping( $ns_default );

    is( $w->end_document( {} ), GENX_SUCCESS, 'namespaces end_document()' );
    is( $str, qq{<foo xmlns="$ns_default->{NamespaceURI}" xmlns:ns2="$ns_other->{NamespaceURI}" nons="" ns2:attr=""></foo>}, 'namespaces output' );
}

sub test_misc {
    my $str;
    my $w = XML::Genx::SAXWriter->new( out => \$str );
    $w->start_document( {} );
    my $el = {
        Attributes   => {},
        LocalName    => 'foo',
        Name         => 'foo',
        NamespaceURI => '',
        Prefix       => '',
    };
    $w->processing_instruction( { Target => 'target', Data => 'data' } );
    $w->start_element( $el );
    $w->characters( { Data => 'bar' } );
    $w->end_element( $el );
    $w->comment( { Data => 'END' } );
    is( $w->end_document( {} ), GENX_SUCCESS, 'misc end_document()' );
    is( $str, qq{<?target data?>\n<foo>bar</foo>\n<!--END-->}, 'misc output' );
}

sub test_send_to_fh {
    my $fh = tempfile();
    my $w = XML::Genx::SAXWriter->new( out => $fh );
    simple_sax_write( $w );
    is( file_contents( $fh ), '<foo>bar</foo>', 'output to filehandle' );
}

sub test_send_to_filename {
    my ( $fh, $fname ) = tempfile( UNLINK => 1 );
    my $w = XML::Genx::SAXWriter->new( out => $fname );
    simple_sax_write( $w );
    is( file_contents( $fh ), '<foo>bar</foo>', 'output to filename' );
}

sub test_send_to_sub {
    my $str;
    my $w = XML::Genx::SAXWriter->new( out => sub { $str .= $_[0] } );
    simple_sax_write( $w );
    is( $str, '<foo>bar</foo>', 'output to sub' );
}

# Convenience call to output a known piece of xml on a given writer.
sub simple_sax_write {
    my ( $w ) = @_;
    $w->start_document( {} );
    my $el = {
        Attributes   => {},
        LocalName    => 'foo',
        Name         => 'foo',
        NamespaceURI => '',
        Prefix       => '',
    };
    $w->start_element( $el );
    $w->characters( { Data => 'bar' } );
    $w->end_element( $el );
    return $w->end_document( {} );
}

sub file_contents {
    my ( $fh ) = @_;
    seek $fh, 0, 0 or die "seek: $!\n";
    local $/;
    return <$fh>;
}

# vim: set ai et sw=4 syntax=perl :

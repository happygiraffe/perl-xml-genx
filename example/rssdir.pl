#!/usr/bin/perl -w
#
# A small example of XML::Genx.  Given a URL and directory, output an
# RSS file linking to files in that directory (which are presumed
# served via the URL).
#
# @(#) $Id$
#

use strict;
use warnings;

use File::Spec::Functions qw( catfile );
use POSIX 'strftime';
use XML::Genx;

my ( $base_url, $dir ) = @ARGV;

die "usage: $0 base_url dir\n"
  unless $base_url && $dir;

my $w     = XML::Genx->new;
my $title = $w->DeclareElement( 'title' );
my $link  = $w->DeclareElement( 'link' );
my $item  = $w->DeclareElement( 'item' );

$w->StartDocFile( *STDOUT );
$w->StartElementLiteral( 'rss' );
$w->AddAttributeLiteral( version => '2.0' );

element( $w, $title => "Contents of $dir" );
element( $w, $link  => $base_url );
element( $w, description => "A list of all the files in $dir, in date order." );
element( $w, pubDate     => rfc822date() );
element( $w, generator   => $0 );

my @files = get_files( $dir );
my %mtime = map { $_ => ( stat catfile $dir, $_ )[9] } @files;
@files = sort { $mtime{ $b } <=> $mtime{ $a } } @files;

foreach ( @files ) {
    $item->StartElement;
    element( $w, $title, $_ );
    element( $w, $link,  "$base_url/$_" );
    element( $w, pubDate => rfc822date( $mtime{ $_ } ) );
    $w->EndElement;
}

$w->EndElement;    # </rss>
$w->EndDocument;

exit 0;

#---------------------------------------------------------------------

sub get_files {
    my ( $dir ) = @_;
    opendir my $dh, $dir
        or die "$0: opendir($dir): $!\n";
    my @files =
        grep { -f catfile( $dir, $_ ) }
        grep { !/^\./ }
        grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;
    return @files;
}

#---------------------------------------------------------------------

sub rfc822date {
    my $when = shift || time;
    return strftime "%a, %m %b %Y %H:%M:%S GMT", gmtime( $when );
}

#---------------------------------------------------------------------

sub element {
    my ( $w, $name, $text ) = @_;
    if ( ref $name && $name->can( 'StartElement' ) ) {
        $name->StartElement;
    } else {
        $w->StartElementLiteral( $name );
    }
    $w->AddText( $text );
    $w->EndElement;
}

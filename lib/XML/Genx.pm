package XML::Genx;

use strict;
use warnings;

our $VERSION = '0.01';

# Use XSLoader first if possible.
eval {
    require XSLoader;
    XSLoader::load( __PACKAGE__, $VERSION );
    1;
} or do {
    require DynaLoader;
    # Avoid inheriting from DynaLoader, simulate class method call.
    DynaLoader::bootstrap( __PACKAGE__, $VERSION );
};

1;
__END__

=head1 NAME

XML::Genx - Simple, correct XML writer

=head1 SYNOPSIS

  use XML::Genx;
  my $w = XML::Genx->new;
  $w->StartDocFile( *STDOUT );
  $w->StartElementLiteral( 'urn:foo', 'foo' ):
  $w->AddText( 'bar' );
  $w->EndElement;
  $w->EndDocument;

=head1 DESCRIPTION

This class is used for generating XML.  The underlying library (genx)
ensures that the output is well formed, canonical XML.  That is, all
characters are correctly encoded, namespaces are handled properly and
so on.

The API is mostly a wrapper over the original C library.  Consult the
genx documentation for the fine detail.

=head1 METHODS

Unless otherwise stated, all methods return a genxStatus code.  This
will be zero for success, or nonzero otherwise.  A textual explanation
of the error can be extracted.

=over 4

=item new ( )

Constructor.  Returns a new L<XML::Genx> object.

=item startDocFile ( FILEHANDLE )

Starts writing output to FILEHANDLE.

=item EndDocument ( )

Finishes writing to the output stream.

=item StartElementLiteral ( NAMESPACE, LOCALNAME )

Starts an element LOCALNAME, in NAMESPACE.  If NAMESPACE is undef, no
namespace is used.

=item EndElement ( )

Output a closing tag for the currently open element.

=item LastErrorMessage ( )

Returns the string value of the last error.

=item GetErrorMessage ( CODE )

Given a genxStatus code, return the equivalent string.

=item AddText ( STRING )

Output STRING.

=item Comment ( STRING )

Output STRING as an XML comment.

=item PI ( TARGET, STRING )

Output a processing instruction, with target TARGET and STRING as the
body.

=back

=head1 SEE ALSO

L<http://www.tbray.org/ongoing/When/200x/2004/02/20/GenxStatus>

=head1 AUTHOR

Dominic Mitchell, E<lt>dom@happygiraffe.netE<gt>

The genx library was created by Tim Bray L<http://www.tbray.org/>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Dominic Mitchell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=head1 VERSION

@(#) $Id$

=cut

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
genx documentation for the fine detail.  This code is based on genx
I<beta5>.

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

=item UnsetDefaultNamespace ( )

Insert an C< xmlns="" > attribute.  Has no effect if the default
namespace is already in effect.

=item GetVersion ( )

Return the version number of the Genx library in use.

=back

=head1 LIMITATIONS

According to the Genx manual, the things that Genx can't do include:

=over 4

=item *

Generating output in anything but UTF8.

=item *

Writing namespace-oblivious XML. That is to say, you can't have an
element or attribute named foo:bar unless foo is a prefix associated
with some namespace.

=item *

Empty-element tags.

=item *

Writing XML or <!DOCTYPE> declarations. Of course, you could squeeze
these into the output stream yourself before any Genx calls that
generate output.

=item *

Pretty-printing. Of course, you can pretty-print yourself by putting the
linebreaks in the right places and indenting appropriately, but Genx
won't do it for you. Someone might want to write a pretty-printer that
sits on top of Genx.

=back

=head1 TODO

At the moment, only a basic subset of the available API is exposed.  I
need to make the rest work.

=over 4

=item *

Provide an ability to use genxStartDocSender() so that you can pass in
code refs that get given strings.  This should be the underpinnings of a
slightly easier interface than filehandles.

=item *

We need to be able to get hold of "compiled" elements, attributes and
namespaces.  That means creating a few extra classes to hold the
genxNamespace, genxElement, and genxAttribute structs.  Also, I need to
expose the corresponding genxDeclare* methods as constructors for them.

The interface for genxDeclare* returns both a new struct and a status
code.  I'm tempted to let it return a single value, which will be an
object or undef.  If it's undef, you can call LastErrorMessage() to find
out what happened.

=item *

Make the constants available in Perl.

=item *

Expose the utility routines.  Possibly.  I'm not sure what they'd be
needed for.

=item *

Maybe make genx use Perl's malloc?

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

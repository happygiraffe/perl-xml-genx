package XML::Genx;

use strict;
use warnings;

our $VERSION = '0.02';

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

=item StartDocFile ( FILEHANDLE )

Starts writing output to FILEHANDLE.

=item StartDocSender ( CALLBACK )

Takes a coderef (C< sub {} >), which gets called each time that genx
needs to output something.  CALLBACK will be called with two
arguments: the text to output and the name of the function that called
it (one of I<write>, I<write_bounded>, or I<flush>).

  my $coderef = sub { print $_[0] if $_[1] =~ /write/ };
  $w->StartDocSender( $coderef );

In the case of I<flush>, the first argument will always be an empty
string.

The string passed to CALLBACK will always be UTF-8.

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

=item AddCharacter ( C )

Output the Unicode character with codepoint C (an integer).

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

=item DeclareNamespace ( URI, PREFIX )

Returns a new namespace object.

=item DeclareElement ( NS, NAME )

Returns a new element object.  NS must an object returned by
DeclareNamespace(), or undef to indicate no namespace.

=item DeclareAttribute ( NS, NAME )

Returns a new attribute object.  NS must an object returned by
DeclareNamespace(), or undef to indicate no namespace.

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

=over 4

=item *

Provide an ability to use genxStartDocSender() so that you can pass in
code refs that get given strings.  This should be the underpinnings of a
slightly easier interface than filehandles.

=item *

Make the constants available in Perl.

=item *

Make the interface more Perlish where possible.  I really like the way
that the Ruby interface uses blocks, but I don't think it'd be as
practical in Perl...

=item *

Clean up the XS a little; there's a lot of cut'n'paste in there.

=back

=head1 SEE ALSO

L<http://www.tbray.org/ongoing/When/200x/2004/02/20/GenxStatus>

=head1 AUTHOR

Dominic Mitchell, E<lt>dom@happygiraffe.netE<gt>

The genx library was created by Tim Bray L<http://www.tbray.org/>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Dominic Mitchell. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

=over 4

=item 1.

Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

=item 2.

Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

=back

THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

The genx library is:

Copyright (c) 2004 by Tim Bray and Sun Microsystems.  For copying
permission, see L<http://www.tbray.org/ongoing/genx/COPYING>.

=head1 VERSION

@(#) $Id$

=cut

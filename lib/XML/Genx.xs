/* @(#) $Id$ */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "genx.h"

MODULE = XML::Genx	PACKAGE = XML::Genx	PREFIX=genx

PROTOTYPES: DISABLE

# We work around the typemap and do things ourselves since it's
# otherwise hard to get the class name correct.  Doing things this way
# ensures that we are subclassable.  Example taken from Digest::MD5.
void
new( klass )
    char* klass
  INIT:
    genxWriter w;
  PPCODE:
    w = genxNew( NULL, NULL, NULL );
    ST( 0 ) = sv_newmortal();
    sv_setref_pv( ST(0), klass, (void*)w );
    SvREADONLY_on(SvRV(ST(0)));
    XSRETURN( 1 );

void
DESTROY( w )
    genxWriter w
  CODE:
    genxDispose( w );

genxStatus
genxStartDocFile( w, fh )
    genxWriter w
    FILE *fh
  INIT:
    if ( fh == NULL )
      croak( "Bad filehandle" );

genxStatus
genxEndDocument( w )
    genxWriter w

# Because xmlns can be NULL, we need to allow undef here.  However,
# the typemap for "char*" throws a warning if you pass that in.
# Instead, we have to take an SV and wing it ourselves.  That's a
# *lot* more work...
genxStatus
genxStartElementLiteral( w, xmlns_sv, name )
    genxWriter w
    SV*        xmlns_sv
    constUtf8  name
  PREINIT:
    constUtf8  xmlns;
  INIT:
    /* Undef means "no namespace". */
    if ( xmlns_sv == &PL_sv_undef ) {
        xmlns = NULL;
    } else {
        xmlns = (constUtf8)SvPV_nolen(xmlns_sv);
       /* Empty string means "no namespace" too. */
       if ( *xmlns == '\0' )
           xmlns = NULL;
    }
  CODE:
    RETVAL = genxStartElementLiteral( w, xmlns, name );
  OUTPUT:
    RETVAL

# Same issue with xmlns here as in genxStartElementLiteral().
genxStatus
genxAddAttributeLiteral( w, xmlns_sv, name, value )
    genxWriter w
    SV*        xmlns_sv
    constUtf8  name
    constUtf8  value
  PREINIT:
    constUtf8  xmlns;
  INIT:
    /* Undef means "no namespace". */
    if ( xmlns_sv == &PL_sv_undef ) {
        xmlns = NULL;
    } else {
        xmlns = (constUtf8)SvPV_nolen(xmlns_sv);
       /* Empty string means "no namespace" too. */
       if ( *xmlns == '\0' )
           xmlns = NULL;
    }
  CODE:
    RETVAL = genxAddAttributeLiteral( w, xmlns, name, value );
  OUTPUT:
    RETVAL

genxStatus
genxEndElement( w )
    genxWriter w

char *
genxLastErrorMessage( w )
    genxWriter w

char *
genxGetErrorMessage( w, st )
    genxWriter w
    genxStatus st

genxStatus
genxAddText( w, start )
    genxWriter w
    constUtf8 start

genxStatus
genxAddCharacter( w, c )
    genxWriter w
    int c

genxStatus
genxComment( w, text )
    genxWriter w
    constUtf8 text

genxStatus
genxPI( w, target, text );
    genxWriter w
    constUtf8 target
    constUtf8 text

genxStatus
genxUnsetDefaultNamespace( w )
    genxWriter w

char *
genxGetVersion( class )
    char * class
  CODE:
    RETVAL = genxGetVersion();
  OUTPUT:
    RETVAL

# Blah, blah, Need to use an SV instead of a char* in order to let
# "undef" in properly.
void
genxDeclareNamespace( w, uri, prefix_sv )
    genxWriter w
    constUtf8  uri
    SV*        prefix_sv
  PREINIT:
    constUtf8     prefix;
    genxNamespace ns;
    genxStatus    st;
  INIT:
    if ( prefix_sv == &PL_sv_undef ) {
        prefix = NULL;
    } else {
        prefix = (constUtf8)SvPV_nolen(prefix_sv);
    }
  PPCODE:
    ns = genxDeclareNamespace( w, uri, prefix, &st );
    if ( ns && st == GENX_SUCCESS ) {
        ST( 0 ) = sv_newmortal();
        sv_setref_pv( ST(0), "XML::Genx::Namespace", (void*)ns );
        SvREADONLY_on(SvRV(ST(0)));
        XSRETURN( 1 );
    } else {
        XSRETURN_UNDEF;
    }

# XXX Ensure ns is optional.
void
genxDeclareElement( w, ns, type )
    genxWriter    w
    genxNamespace ns
    constUtf8     type
  PREINIT:
    genxStatus  st;
    genxElement el;
  PPCODE:
    el = genxDeclareElement( w, ns, type, &st );
    if ( el && st == GENX_SUCCESS ) {
        ST( 0 ) = sv_newmortal();
        sv_setref_pv( ST(0), "XML::Genx::Element", (void*)el );
        SvREADONLY_on(SvRV(ST(0)));
        XSRETURN( 1 );
    } else {
        XSRETURN_UNDEF;
    }

# XXX Ensure ns is optional.
void
genxDeclareAttribute( w, ns, name )
    genxWriter    w
    genxNamespace ns
    constUtf8     name
  PREINIT:
    genxStatus    st;
    genxAttribute at;
  PPCODE:
    at = genxDeclareAttribute( w, ns, name, &st );
    if ( at && st == GENX_SUCCESS ) {
        ST( 0 ) = sv_newmortal();
        sv_setref_pv( ST(0), "XML::Genx::Attribute", (void*)at );
        SvREADONLY_on(SvRV(ST(0)));
        XSRETURN( 1 );
    } else {
        XSRETURN_UNDEF;
    }

MODULE = XML::Genx	PACKAGE = XML::Genx::Namespace	PREFIX=genx

utf8
genxGetNamespacePrefix( ns )
    genxNamespace ns

MODULE = XML::Genx	PACKAGE = XML::Genx::Element	PREFIX=genx

genxStatus
genxStartElement( e )
    genxElement e

MODULE = XML::Genx	PACKAGE = XML::Genx::Attribute	PREFIX=genx

genxStatus
genxAddAttribute( a, value )
    genxAttribute a
    constUtf8 value


/*
 * Copyright (C) 1992-2004 Dominic Mitchell. All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/* @(#) $Id$ */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "genx.h"

/* 
 * xsubpp will automatically change a double underscore into a double
 * colon meaning that we get the correct class names for free from the
 * standard typemap file.
 */

typedef genxWriter    XML_Genx;
typedef genxNamespace XML_Genx_Namespace;
typedef genxElement   XML_Genx_Element;
typedef genxAttribute XML_Genx_Attribute;

static genxStatus
sender_write( void *userData, constUtf8 s )
{
    dSP;
    SV *coderef = (SV *)userData;
    SV *str = newSVpv( (const char *)s, 0 );
    ENTER;
    SAVETMPS;

    /* genx guarantees that thus will be UTF-8, so tell Perl that. */
    SvUTF8_on(str);

    /* Set up the stack. */
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(str));
    XPUSHs(sv_2mortal(newSVpv("write", 5)));
    PUTBACK;

    /* Do the business. */
    (void)call_sv( coderef, G_VOID );

    SPAGAIN;                    /* XXX Necessary? */

    FREETMPS;
    LEAVE;
    return GENX_SUCCESS;
}

static genxStatus
sender_write_bounded( void *userData, constUtf8 start, constUtf8 end )
{
    dSP;
    SV *coderef = (SV *)userData;
    SV *str = newSVpv((const char *)start, end - start);
    ENTER;
    SAVETMPS;

    /* genx guarantees that thus will be UTF-8, so tell Perl that. */
    SvUTF8_on(str);

    /* Set up the stack. */
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(str));
    XPUSHs(sv_2mortal(newSVpv("write_bounded", 13)));
    PUTBACK;

    /* Do the business. */
    (void)call_sv( coderef, G_VOID );

    SPAGAIN;                    /* XXX Necessary? */

    FREETMPS;
    LEAVE;
    return GENX_SUCCESS;
}

static genxStatus
sender_flush( void *userData )
{
    dSP;
    SV *coderef = (SV *)userData;
    ENTER;
    SAVETMPS;

    /* Set up the stack. */
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv("", 0)));
    XPUSHs(sv_2mortal(newSVpv("flush", 5)));
    PUTBACK;

    /* Do the business. */
    (void)call_sv( coderef, G_VOID );

    SPAGAIN;                    /* XXX Necessary? */

    FREETMPS;
    LEAVE;
    return GENX_SUCCESS;
}

static genxSender sender = {
    sender_write,
    sender_write_bounded,
    sender_flush
};

MODULE = XML::Genx	PACKAGE = XML::Genx	PREFIX=genx

PROTOTYPES: DISABLE

# We work around the typemap and do things ourselves since it's
# otherwise hard to get the class name correct.  Doing things this way
# ensures that we are subclassable.  Example taken from Digest::MD5.
void
new( klass )
    char* klass
  INIT:
    XML_Genx w;
  PPCODE:
    w = genxNew( NULL, NULL, NULL );
    ST( 0 ) = sv_newmortal();
    sv_setref_pv( ST(0), klass, (void*)w );
    SvREADONLY_on(SvRV(ST(0)));
    XSRETURN( 1 );

void
DESTROY( w )
    XML_Genx w
  CODE:
    genxDispose( w );

genxStatus
genxStartDocFile( w, fh )
    XML_Genx w
    FILE *fh
  INIT:
    if ( fh == NULL )
      croak( "Bad filehandle" );
  POSTCALL:
    if ( RETVAL != GENX_SUCCESS ) croak( genxLastErrorMessage( w ) );

genxStatus
genxStartDocSender( w, callback )
    XML_Genx w
    SV *callback
  PREINIT:
    SV *oldcallback;
  CODE:
    /*
     * Based on Section 6.7.2 of "Extending and Embedding Perl".
     * First time around, we take a copy of the SV passed in.  Next
     * time around, we reuse the same SV, but still taking care to
     * ensure that the ref counts are correct.
     */
    oldcallback = (SV *)genxGetUserData( w );
    if ( oldcallback == NULL ) {
        genxSetUserData( w, (void *)newSVsv( callback ) );
    } else {
        SvSetSV( oldcallback, callback );
    }
    RETVAL = genxStartDocSender( w, &sender );
  POSTCALL:
    if ( RETVAL != GENX_SUCCESS ) croak( genxLastErrorMessage( w ) );
  OUTPUT:
    RETVAL

genxStatus
genxEndDocument( w )
    XML_Genx w
  POSTCALL:
    if ( RETVAL != GENX_SUCCESS ) croak( genxLastErrorMessage( w ) );

# Because xmlns can be NULL, we need to allow undef here.  However,
# the typemap for "char*" throws a warning if you pass that in.
# Instead, we have to take an SV and wing it ourselves.  That's a
# *lot* more work...
genxStatus
genxStartElementLiteral( w, xmlns_sv, name )
    XML_Genx w
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
  POSTCALL:
    if ( RETVAL != GENX_SUCCESS ) croak( genxLastErrorMessage( w ) );
  OUTPUT:
    RETVAL

# Same issue with xmlns here as in genxStartElementLiteral().
genxStatus
genxAddAttributeLiteral( w, xmlns_sv, name, value )
    XML_Genx w
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
  POSTCALL:
    if ( RETVAL != GENX_SUCCESS ) croak( genxLastErrorMessage( w ) );
  OUTPUT:
    RETVAL

genxStatus
genxEndElement( w )
    XML_Genx w
  POSTCALL:
    if ( RETVAL != GENX_SUCCESS ) croak( genxLastErrorMessage( w ) );

char *
genxLastErrorMessage( w )
    XML_Genx w

char *
genxGetErrorMessage( w, st )
    XML_Genx w
    genxStatus st

genxStatus
genxAddText( w, start )
    XML_Genx w
    constUtf8 start
  POSTCALL:
    if ( RETVAL != GENX_SUCCESS ) croak( genxLastErrorMessage( w ) );

genxStatus
genxAddCharacter( w, c )
    XML_Genx w
    int c
  POSTCALL:
    if ( RETVAL != GENX_SUCCESS ) croak( genxLastErrorMessage( w ) );

genxStatus
genxComment( w, text )
    XML_Genx w
    constUtf8 text
  POSTCALL:
    if ( RETVAL != GENX_SUCCESS ) croak( genxLastErrorMessage( w ) );

genxStatus
genxPI( w, target, text );
    XML_Genx w
    constUtf8 target
    constUtf8 text
  POSTCALL:
    if ( RETVAL != GENX_SUCCESS ) croak( genxLastErrorMessage( w ) );

genxStatus
genxUnsetDefaultNamespace( w )
    XML_Genx w
  POSTCALL:
    if ( RETVAL != GENX_SUCCESS ) croak( genxLastErrorMessage( w ) );

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
    XML_Genx w
    constUtf8  uri
    SV*        prefix_sv
  PREINIT:
    constUtf8     prefix;
    XML_Genx_Namespace ns;
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
    XML_Genx    w
    XML_Genx_Namespace ns
    constUtf8     type
  PREINIT:
    genxStatus  st;
    XML_Genx_Element el;
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
    XML_Genx    w
    XML_Genx_Namespace ns
    constUtf8     name
  PREINIT:
    genxStatus    st;
    XML_Genx_Attribute at;
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
    XML_Genx_Namespace ns

MODULE = XML::Genx	PACKAGE = XML::Genx::Element	PREFIX=genx

# XXX Need to die on failure...
genxStatus
genxStartElement( e )
    XML_Genx_Element e

MODULE = XML::Genx	PACKAGE = XML::Genx::Attribute	PREFIX=genx

# XXX Need to die on failure...
genxStatus
genxAddAttribute( a, value )
    XML_Genx_Attribute a
    constUtf8 value


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

static void
croak_on_genx_error( genxWriter w, genxStatus st )
{
    char *msg;
    if ( st == GENX_SUCCESS ) {
        msg = NULL;
    } else if ( w ) {
        msg = genxLastErrorMessage( w );
    } else {
        /* If we don't have a writer object handy, make one for this
         * purpose.  This is slow, but unavoidable. */
        w = genxNew( NULL, NULL, NULL );
        msg = genxGetErrorMessage( w, st );
        genxDispose( w );
    }
    if ( msg )
        croak( msg );
    return;
}

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
  PREINIT:
    struct stat st;
  INIT:
    /* 
     * Sometimes we get back a filehandle with an invalid file
     * descriptor instead of NULL.  So use fstat() to check that it's
     * actually live and usable.
     *
     * Many thanks to http://www.testdrive.hp.com/ for providing a
     * service that let me find this out when I couldn't reproduce it
     * on my own box.
     */
    if ( fh == NULL || fstat(fileno(fh), &st) == -1 )
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

# Take a variable length list so that we can make the namespace
# parameter optional.  Even when present, it will only be used if it's
# a true value.
genxStatus
genxStartElementLiteral( w, ... )
    XML_Genx w
  PREINIT:
    constUtf8  xmlns;
    constUtf8  name;
  INIT:
    if ( items == 2 ) {
        xmlns = NULL;
        name  = (constUtf8)SvPV_nolen(ST(1));
    } else if ( items == 3 ) {
        xmlns = SvTRUE(ST(1)) ? (constUtf8)SvPV_nolen(ST(1)) : NULL;
        name  = (constUtf8)SvPV_nolen(ST(2));
    } else {
        croak( "Usage: w->StartElementLiteral([xmlns],name)" );
    }
  CODE:
    RETVAL = genxStartElementLiteral( w, xmlns, name );
  POSTCALL:
    if ( RETVAL != GENX_SUCCESS ) croak( genxLastErrorMessage( w ) );
  OUTPUT:
    RETVAL

# Same design as StartElementLiteral().
genxStatus
genxAddAttributeLiteral( w, ... )
    XML_Genx w
  PREINIT:
    constUtf8  xmlns;
    constUtf8  name;
    constUtf8  value;
  INIT:
    if ( items == 3 ) {
        xmlns = NULL;
        name  = (constUtf8)SvPV_nolen(ST(1));
        value = (constUtf8)SvPV_nolen(ST(2));
    } else if ( items == 4 ) {
        xmlns = SvTRUE(ST(1)) ? (constUtf8)SvPV_nolen(ST(1)) : NULL;
        name  = (constUtf8)SvPV_nolen(ST(2));
        value = (constUtf8)SvPV_nolen(ST(3));
    } else {
        croak( "Usage: w->AddAttributeLiteral([xmlns],name,value)" );
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

# We need to map an undef prefix to NULL.  But we want to pass an
# empty prefix straight through as that means "default".
void
genxDeclareNamespace( w, uri, ... )
    XML_Genx w
    constUtf8  uri
  PREINIT:
    constUtf8     prefix;
    XML_Genx_Namespace ns;
    genxStatus    st;
  INIT:
    if ( items == 2 )
        prefix = NULL;
    else if ( items == 3 )
        prefix = ST(2) == &PL_sv_undef ? NULL : (constUtf8)SvPV_nolen(ST(2));
    else
        croak( "usage: w->DeclareNamespace(uri,[defaultPrefix])" );
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

void
genxDeclareElement( w, ... )
    XML_Genx    w
  PREINIT:
    genxStatus         st;
    XML_Genx_Element   el;
    XML_Genx_Namespace ns;
    constUtf8          type;
  PPCODE:
    if ( items == 2 ) {
        ns = (XML_Genx_Namespace) NULL;
        type = (constUtf8)SvPV_nolen(ST(1));
    } else if ( items == 3 ) {
        /*  Bleargh, would be nice to be able to reuse typemap here */
	if (ST(1) == &PL_sv_undef) {
	    ns = (XML_Genx_Namespace) NULL;
	} else if (sv_derived_from(ST(1), "XML::Genx::Namespace")) {
	    IV tmp = SvIV((SV*)SvRV(ST(1)));
	    ns = INT2PTR(XML_Genx_Namespace, tmp);
	} else {
	    croak("ns is not undef or of type XML::Genx::Namespace");
	}
        type = (constUtf8)SvPV_nolen(ST(2));
    } else {
        croak( "Usage: w->DeclareElement([ns],type)" );
    }
    el = genxDeclareElement( w, ns, type, &st );
    if ( el && st == GENX_SUCCESS ) {
        ST( 0 ) = sv_newmortal();
        sv_setref_pv( ST(0), "XML::Genx::Element", (void*)el );
        SvREADONLY_on(SvRV(ST(0)));
        XSRETURN( 1 );
    } else {
        XSRETURN_UNDEF;
    }

void
genxDeclareAttribute( w, ... )
    XML_Genx    w
  PREINIT:
    genxStatus         st;
    XML_Genx_Attribute at;
    XML_Genx_Namespace ns;
    constUtf8          name;
  PPCODE:
    if ( items == 2 ) {
        ns = (XML_Genx_Namespace) NULL;
        name = (constUtf8)SvPV_nolen(ST(1));
    } else if ( items == 3 ) {
        /*  Bleargh, would be nice to be able to reuse typemap here */
	if (ST(1) == &PL_sv_undef) {
	    ns = (XML_Genx_Namespace) NULL;
	} else if (sv_derived_from(ST(1), "XML::Genx::Namespace")) {
	    IV tmp = SvIV((SV*)SvRV(ST(1)));
	    ns = INT2PTR(XML_Genx_Namespace, tmp);
	} else {
	    croak("ns is not undef or of type XML::Genx::Namespace");
	}
        name = (constUtf8)SvPV_nolen(ST(2));
    } else {
        croak( "Usage: w->DeclareAttribute([ns],name)" );
    }
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

genxStatus
genxAddNamespace(ns, ...);
    XML_Genx_Namespace ns
  PREINIT:
    utf8 prefix;
  CODE:
    if ( items == 1 )
        prefix = NULL;
    else if ( items == 2 )
        prefix = ST(1) == &PL_sv_undef ? NULL : (utf8)SvPV_nolen(ST(1));
    else
        croak( "Usage: ns->AddNamespace([prefix])" );
    RETVAL = genxAddNamespace( ns, prefix );
  POSTCALL:
      croak_on_genx_error( NULL, RETVAL );
  OUTPUT:
    RETVAL

MODULE = XML::Genx	PACKAGE = XML::Genx::Element	PREFIX=genx

genxStatus
genxStartElement( e )
    XML_Genx_Element e
  POSTCALL:
      croak_on_genx_error( NULL, RETVAL );

MODULE = XML::Genx	PACKAGE = XML::Genx::Attribute	PREFIX=genx

genxStatus
genxAddAttribute( a, value )
    XML_Genx_Attribute a
    constUtf8 value
  POSTCALL:
      croak_on_genx_error( NULL, RETVAL );


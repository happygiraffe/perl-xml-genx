/* @(#) $Id$ */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "genx.h"

#include "ppport.h"

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

# I'm going to use the file based solution for now, since it's easier
# to work with in XS.
#
# XXX We need to croak if fileno is -1, since that really doesn't work
# well.  It's what you get when you pass in an IO::Scalar or similiar.
genxStatus
genxStartDocFile( w, fh )
    genxWriter w
    FILE *fh

genxStatus
genxEndDocument( w )
    genxWriter w

# XXX We need to ensure that we insert a NULL if xmlns is an empty
# string or undefined.
genxStatus
genxStartElementLiteral( w, xmlns, name )
    genxWriter w
    char *xmlns
    char *name

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
genxComment( w, text )
    genxWriter w
    constUtf8 text

genxStatus
genxPI( w, target, text );
    genxWriter w
    constUtf8 target
    constUtf8 text

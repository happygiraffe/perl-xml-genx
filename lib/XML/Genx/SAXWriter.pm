package XML::Genx::SAXWriter;

use strict;
use warnings;

use Carp ();
use XML::Genx::Simple;

use base 'XML::SAX::Base';

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->_init( @_ );
    return $self;
}

sub _init {
    my $self = shift;
    my %opt = @_;
    $self->_out( $opt{ out } || \*STDOUT );
    return;
}

sub start_document {
    my $self = shift;

    $self->_w( XML::Genx::Simple->new );

    if ( ref $self->_out eq 'SCALAR' ) {
        $self->_w->StartDocString;
    } elsif ( ref $self->_out eq 'GLOB' ) {
        $self->_w->StartDocFile( $self->_out );
    } elsif ( ref $self->_out eq 'CODE' ) {
        $self->_w->StartDocSender( $self->_out );
    } elsif ( ref $self->_out && $self->_out->isa( 'IO::Handle' ) ) {
        $self->_w->StartDocFile( $self->_out );
    } elsif ( defined $self->_out && length $self->_out ) {
        open( my $fh, '<', $self->_out )
          or Carp::croak( "open(".$self->_out."): $!" );
        $self->StartDocFile( $fh );
    } else {
        Carp::croak( "start_document: no output specified!" );
    }
}

sub end_document {
    my $self = shift;
    my $rv = $self->_w->EndDocument;
    if ( ref $self->_out eq 'SCALAR' ) {
        ${ $self->_out } = $self->_w->GetDocString;
    }
    return $rv;
}

sub start_element {
    my $self = shift;
    my ( $data ) = @_;

    my $ns =
        $self->_new_namespace( $data->{ NamespaceURI }, $data->{ Prefix } );
    $self->_new_element( $ns, $data->{ LocalName } )->StartElement;

    while ( my $ns = $self->_pop_ns ) {
        $self->_new_namespace( @$ns )->AddNamespace;
    }

    foreach ( values %{ $data->{ Attributes } || {} } ) {
        my $ns = $self->_new_namespace( $_->{ NamespaceURI }, $_->{ Prefix } );
        $self->_new_attribute( $ns, $_->{ LocalName } )
            ->AddAttribute( $_->{ Value } );
    }

    return;
}

sub characters {
    my $self = shift;
    my ( $data ) = @_;
    $self->_w->AddText( $data->{ Data } );
}

sub end_element {
    my $self = shift;
    my ( $data ) = @_;
    $self->_w->EndElement;
}

sub start_prefix_mapping {
    my $self = shift;
    my ( $data ) = @_;
    $self->_push_ns( $data->{ NamespaceURI }, $data->{ Prefix } );
}

sub end_prefix_mapping {
    my $self = shift;
    my ( $data ) = @_;
    # XXX Do we need to do anything here?  I don't think so.
}

sub processing_instruction {
    my $self = shift;
    my ( $data ) = @_;
    $self->_w->PI( $data->{ Target }, $data->{ Data } );
}

sub comment {
    my $self = shift;
    my ( $data ) = @_;
    $self->_w->Comment( $data->{ Data } );
}

#---------------------------------------------------------------------
# PRIVATE
#---------------------------------------------------------------------

sub _w {
    my $self = shift;
    if ( @_ ) {
        $self->{ _w } = $_[0];
        return $self;
    } else {
        return $self->{ _w };
    }
}

sub _out {
    my $self = shift;
    if ( @_ ) {
        $self->{ _out } = $_[0];
        return $self;
    } else {
        return $self->{ _out };
    }
}

sub _push_ns {
    my $self = shift;
    my ( $ns, $prefix ) = @_;
    push @{ $self->{ nstodo } }, [$ns, $prefix];
    return;
}

sub _pop_ns {
    my $self = shift;
    return pop @{ $self->{ nstodo } };
}

# Return a declared namespace object if it's present.  If no namespace
# is given, return undef.
sub _new_namespace {
    my $self = shift;
    my ( $nsuri, $prefix ) = @_;
    return unless $nsuri;
    return $self->{ namespace }{ $nsuri } ||=
        $self->_w->DeclareNamespace( $nsuri, $prefix );
}

sub _new_element {
    my $self = shift;
    my ( $ns, $lname ) = @_;
    return $self->{ element }{ $lname } ||=
        $self->_w->DeclareElement( $ns, $lname );
}

sub _new_attribute {
    my $self = shift;
    my ( $ns, $lname ) = @_;
    return $self->{ attribute }{ $lname } ||=
        $self->_w->DeclareAttribute( $ns, $lname );
}

1;
__END__

=pod

=head1 NAME

XML::Genx::SAXWriter - output a SAX stream using genx

=head1 SYNOPSIS

  # Copy input to output.
  my $w = XML::Genx::SAXWriter->new;
  my $p = XML::SAX::ParserFactory->parser( Handler => $w );
  $p->parse_file( *STDIN );

=head1 DESCRIPTION

This class provides a means of writing output from a stream of SAX
events.  See L<XML::SAX> and L<XML::SAX::Base> for more details on
what SAX is.

Essentially, this is just a wrapper over L<XML::Genx>, mapping calls
from SAX to genx.

=head1 VERSION

@(#) $Id$

=cut

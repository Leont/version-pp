package version::pp;

use 5.006;
use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT = qw//;
our @EXPORT_OK = qw/is_strict is_lax/;

use Carp;
use Scalar::Util qw//;

use overload (
    '""'       => \&stringify,
    '0+'       => \&numify,
    'cmp'      => \&vcmp,
    '<=>'      => \&vcmp,
    'bool'     => \&vbool,
    '+'        => \&vnoop,
    '-'        => \&vnoop,
    '*'        => \&vnoop,
    '/'        => \&vnoop,
    '+='        => \&vnoop,
    '-='        => \&vnoop,
    '*='        => \&vnoop,
    '/='        => \&vnoop,
    'abs'      => \&vnoop,
);

# Fraction part of a decimal version number.  This is a common part of
# both strict and lax decimal versions

my $FRACTION_PART = qr/\.[0-9]+/;

# First part of either decimal or dotted-decimal strict version number.
# Unsigned integer with no leading zeroes (except for zero itself) to
# avoid confusion with octal.

my $STRICT_INTEGER_PART = qr/0|[1-9][0-9]*/;

# First part of either decimal or dotted-decimal lax version number.
# Unsigned integer, but allowing leading zeros.  Always interpreted
# as decimal.  However, some forms of the resulting syntax give odd
# results if used as ordinary Perl expressions, due to how perl treats
# octals.  E.g.
#   version->new("010" ) == 10
#   version->new( 010  ) == 8
#   version->new( 010.2) == 82  # "8" . "2"

my $LAX_INTEGER_PART = qr/[0-9]+/;

# Second and subsequent part of a strict dotted-decimal version number.
# Leading zeroes are permitted, and the number is always decimal.
# Limited to three digits to avoid overflow when converting to decimal
# form and also avoid problematic style with excessive leading zeroes.

my $STRICT_DOTTED_DECIMAL_PART = qr/\.[0-9]{1,3}/;

# Second and subsequent part of a lax dotted-decimal version number.
# Leading zeroes are permitted, and the number is always decimal.  No
# limit on the numerical value or number of digits, so there is the
# possibility of overflow when converting to decimal form.

my $LAX_DOTTED_DECIMAL_PART = qr/\.[0-9]+/;

# Alpha suffix part of lax version number syntax.  Acts like a
# dotted-decimal part.

my $LAX_ALPHA_PART = qr/_[0-9]+/;

#--------------------------------------------------------------------------#
# Strict version regexp definitions
#--------------------------------------------------------------------------#

# Strict decimal version number.

my $STRICT_DECIMAL_VERSION = qr/ $STRICT_INTEGER_PART $FRACTION_PART? /x;

# Strict dotted-decimal version number.  Must have both leading "v" and
# at least three parts, to avoid confusion with decimal syntax.

my $STRICT_DOTTED_DECIMAL_VERSION = qr/ v $STRICT_INTEGER_PART $STRICT_DOTTED_DECIMAL_PART{2,} /x;

# Complete strict version number syntax -- should generally be used
# anchored: qr/ \A $STRICT \z /x

our $STRICT = qr/ $STRICT_DECIMAL_VERSION | $STRICT_DOTTED_DECIMAL_VERSION /x;

#--------------------------------------------------------------------------#
# Lax version regexp definitions
#--------------------------------------------------------------------------#

# Lax decimal version number.  Just like the strict one except for
# allowing an alpha suffix or allowing a leading or trailing
# decimal-point

my $LAX_DECIMAL_VERSION =
    qr/ $LAX_INTEGER_PART (?: \. | $FRACTION_PART $LAX_ALPHA_PART? )?
	|
	$FRACTION_PART $LAX_ALPHA_PART?
    /x;

# Lax dotted-decimal version number.  Distinguished by having either
# leading "v" or at least three non-alpha parts.  Alpha part is only
# permitted if there are at least two non-alpha parts. Strangely
# enough, without the leading "v", Perl takes .1.2 to mean v0.1.2,
# so when there is no "v", the leading part is optional

my $LAX_DOTTED_DECIMAL_VERSION =
    qr/
	v $LAX_INTEGER_PART (?: $LAX_DOTTED_DECIMAL_PART+ $LAX_ALPHA_PART? )?
	|
	$LAX_INTEGER_PART? $LAX_DOTTED_DECIMAL_PART{2,} $LAX_ALPHA_PART?
    /x;

# Complete lax version number syntax -- should generally be used
# anchored: qr/ \A $LAX \z /x
#
# The string 'undef' is a special case to make for easier handling
# of return values from ExtUtils::MM->parse_version

our $LAX = qr/ undef | $LAX_DECIMAL_VERSION | $LAX_DOTTED_DECIMAL_VERSION /x;

#--------------------------------------------------------------------------#

sub is_strict	{ defined $_[0] && $_[0] =~ qr/ \A $STRICT \z /x }
sub is_lax	{ defined $_[0] && $_[0] =~ qr/ \A $LAX \z /x }

use B;
use Data::Dumper;
sub _is_number {
	my $version = shift;
	my $obj = B::svref_2object(\$version);
#die sprintf "%f", $obj->NV;
#	die Dumper($obj);
}

sub new {
	my ($class, $original) = @_;
	die "$class ne version\n" if ref($class) || !$class->isa('version::pp');
	#_is_number($original);
	$original =~ s/ \A \s+//x;
	if (Scalar::Util::isvstring($original)) {
		return $class->new(sprintf 'v%vd', $original);
	}
	elsif ($original =~ / \A $LAX_DECIMAL_VERSION \z /x) {
		my $alpha = (my $argument = $original) =~ tr/_//d;
		my ($head, $tail) = split /\./, $argument, 2;
		my @tail = length $tail ? $tail =~ /\G(\d{1,3})/g : ();
		@tail = map { scalar reverse sprintf "%03d", scalar reverse $_ } @tail;
		return bless {
			alpha => $alpha,
			numified => $argument,
			stringified => $original,
			_common($head, @tail),
		}, $class;
	}
#	elsif (Scalar::Util::looks_like_number($original)) {
#		return $class->new(sprintf "%f", $original);
#	}
	elsif ($original =~ / \A $LAX_DOTTED_DECIMAL_VERSION \z /x) {
		(my $argument = $original) =~ s/^v//;
		my ($head, @tail) = map { tr/_//d ; $_ } split /[.]/, $argument;
		my $numified = "$head." . join '', map { sprintf "%03d", $_ } @tail;
		return bless {
			alpha => $argument =~ tr/_//,
			numified => $numified,
			stringified => $original,
			_common($head, @tail),
		}, $class;
	}
	elsif ($original eq 'undef' or not defined $original) {
		return bless {
			alpha => 0,
			numified => 0,
			stringified => '0',
			_common(0),
		}, $class;
	}
	else {
		Carp::croak("Invalid version format '$original'");
	}
}

sub _common {
	my @elements = @_;

	my @normalized = @elements;
	push @normalized, 0, while @normalized < 3;
	my $normalized = 'v' . join '.', @normalized;

	my @sortable = @elements;
	pop @sortable while @sortable > 1 and $sortable[-1] == 0;
	my $sortable = pack("w*", @sortable);
	return (
		version => \@elements,
		sortable => $sortable,
		normalized => $normalized,
	);
}

{
	no warnings 'once';
	*parse = *new;
}

sub stringify {
	my $self = shift;
	return $self->{stringified};
}

sub numify {
	my $self = shift;
	return $self->{numified};
}

sub normal {
	my $self = shift;
	return $self->{normalized};
}

sub vcmp {
	my ($left, $right, $swapped) = @_;
	($left, $right) = map { ref($_) && $_->isa("version::pp") ? $_ : __PACKAGE__->new($_) } $left, $right;
	return ($left->{sortable} cmp $right->{sortable}) * ($swapped ? -1 : 1);
}

sub vbool {
	my $self = shift;
    return $self->{numified};
}

sub vnoop {
    Carp::croak("operation not supported with version object");
}

sub is_alpha {
	my $self = shift;
	return $self->{alpha};
}

1;

# ABSTRACT: Sane version objects

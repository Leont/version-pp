#! perl

use Test::More 0.89;
use File::Temp qw/tempfile/;
use File::Basename qw/basename/;
use Data::Dumper;

use version::pp;

my $warning;
local $SIG{__WARN__} = sub { $warning = $_[0] };

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

# Test bare number processing
$version = version::pp->new(5.005_03);
is ( "$version" , "5.00503" , '5.005_03 eq 5.00503' );
$version = version::pp->new(1.23);
is ( "$version" , "1.23" , '1.23 eq "1.23"' );

# Test explicit integer
$version = version::pp->new(23);
is ( "$version" , 23 , '23 eq "23"' );

# Test quoted number processing
$version = version::pp->new("5.005_03");
is ( "$version" , "5.005_03" , '"5.005_03" eq "5.005_03"' );
$version = version::pp->new("v1.23");
is ( "$version" , "v1.23" , '"v1.23" eq "v1.23"' );

# Test stringify operator
$version = version::pp->new("5.005");
is ( "$version" , "5.005" , '5.005 eq "5.005"' );
$version = version::pp->new("5.006.001");
is ( "$version" , "5.006.001" , '5.006.001 eq v5.6.1' );
unlike ($warning, qr/v-string without leading 'v' deprecated/, 'No leading v');
$version = version::pp->new("v1.2.3_4");
is ( "$version" , "v1.2.3_4" , 'alpha version 1.2.3_4 eq v1.2.3_4' );

# test illegal formats
eval {my $version = version::pp->new("1.2_3_4")};
like($@, qr/Invalid version/, "Invalid version format (multiple underscores)");

eval {my $version = version::pp->new("1.2_3.4")};
like($@, qr/Invalid version/, "Invalid version format (underscores before decimal)");

eval {my $version = version::pp->new("1_2")};
like($@, qr/Invalid version/, "Invalid version format (alpha without decimal)");

eval { $version = version::pp->new("1.2b3")};
like($@, qr/Invalid version/, "Invalid version format (non-numeric data)");

eval { $version = version::pp->new("-1.23")};
like($@, qr/Invalid version/, "Invalid version format (negative version number)");

# from here on out capture the warning and test independently
{
eval{$version = version::pp->new("99 and 44/100 pure")};

like($@, qr/Invalid version format/, "Invalid version format (non-numeric data)");

eval{$version = version::pp->new("something")};
like($@, qr/Invalid version format/, "Invalid version format (non-numeric data)");

# reset the test object to something reasonable
$version = version::pp->new("1.2.3");

# Test boolean operator
ok ($version, 'boolean');

# Test class membership
isa_ok ( $version, version::pp );

# Test comparison operators with self
is ( $version <=> $version, 0, '$version <=> $version == 0' );
ok ( $version == $version, '$version == $version' );

# Test Numeric Comparison operators
# test first with non-object
$version = version::pp->new("5.006.001");
$new_version = "5.8.0";
ok ( $version == $version, '$version == $version' );
ok ( $version < $new_version, '$version < $new_version' );
ok ( $new_version > $version, '$new_version > $version' );
ok ( $version != $new_version, '$version != $new_version' );

# now test with existing object
$new_version = version::pp->new($new_version);
ok ( $version < $new_version, '$version < $new_version' );
ok ( $new_version > $version, '$new_version > $version' );
ok ( $version != $new_version, '$version != $new_version' );

# now test with actual numbers
ok ( $version->numify() == 5.006001, '$version->numify() == 5.006001' );
ok ( $version->numify() <= 5.006001, '$version->numify() <= 5.006001' );
ok ( $version->numify() < 5.008, '$version->numify() < 5.008' );
#ok ( $version->numify() > v5.005_02, '$version->numify() > 5.005_02' );

# test with long decimals
$version = version::pp->new(1.002003);
ok ( $version == "1.2.3", '$version == "1.2.3"');
ok ( $version->numify == 1.002003, '$version->numify == 1.002003');
$version = version::pp->new("2002.09.30.1");
ok ( $version == "2002.9.30.1",'$version == 2002.9.30.1');
ok ( $version->numify == 2002.009030001,
'$version->numify == 2002.009030001');

# now test with alpha version form with string
$version = version::pp->new("1.2.3");
$new_version = "1.2.3_4";
ok ( $version < $new_version, '$version < $new_version' );
ok ( $new_version > $version, '$new_version > $version' );
ok ( $version != $new_version, '$version != $new_version' );

$version = version::pp->new("1.2.4");
ok ( $version > $new_version, '$version > $new_version' );
ok ( $new_version < $version, '$new_version < $version' );
ok ( $version != $new_version, '$version != $new_version' );

# now test with alpha version form with object
$version = version::pp->new("1.2.3");
$new_version = version::pp->new("1.2.3_4");
ok ( $version < $new_version, '$version < $new_version' );
ok ( $new_version > $version, '$new_version > $version' );
ok ( $version != $new_version, '$version != $new_version' );
ok ( !$version->is_alpha, '!$version->is_alpha');
ok ( $new_version->is_alpha, '$new_version->is_alpha');

$version = version::pp->new("1.2.4");
ok ( $version > $new_version, '$version > $new_version' );
ok ( $new_version < $version, '$new_version < $version' );
ok ( $version != $new_version, '$version != $new_version' );

$version = version::pp->new("1.2.3.4");
$new_version = version::pp->new("1.2.3_4");
ok ( $version == $new_version, '$version > $new_version' );

$version = version::pp->new("v1.2.3");
$new_version = version::pp->new("1.2.3.0");
ok ( $version == $new_version, '$version == $new_version' );
$new_version = version::pp->new("1.2.3_0");
ok ( $version == $new_version, '$version == $new_version' );
$new_version = version::pp->new("1.2.3.1");
ok ( $version < $new_version, '$version < $new_version' );
$new_version = version::pp->new("1.2.3_1");
ok ( $version < $new_version, '$version < $new_version' );
$new_version = version::pp->new("1.1.999");
ok ( $version > $new_version, '$version > $new_version' );

$version = version::pp->new("v1.2.3");
eval { () = $version < 'version' };
# this test, and only this test, I have to do this or else $@ gets
# "reset" before like() has a chance to evaluate it.  Quite maddening!!!
my $err = $@;
like $err, qr/^Invalid version format/, "error with $version < 'version'";

# that which is not expressly permitted is forbidden
ok ( !eval { ++$version }, "noop ++" );
ok ( !eval { --$version }, "noop --" );
ok ( !eval { $version/1 }, "noop /" );
ok ( !eval { $version*3 }, "noop *" );
ok ( !eval { abs($version) }, "noop abs" );

# test creation from existing version object
ok (eval {$new_version = version::pp->new($version)},
	"new from existing object");
ok ($new_version == $version, "class->new($version) identical");
$new_version = ref($version)->new(0);
isa_ok ($new_version, 'version::pp') or diag explain $new_version;
is ($new_version, "0", "version->new() doesn't clone");
$new_version = ref($version)->new("1.2.3");
is ($new_version, "1.2.3" , '$version->new("1.2.3") works too');

# test the CVS revision mode
#$version = version::pp->new(qw$Revision: 1.2$);
#ok ( $version == "1.2.0", 'qw$Revision: 1.2$ == 1.2.0' );
#$version = version::pp->new(qw$Revision: 1.2.3.4$);
#ok ( $version == "1.2.3.4", 'qw$Revision: 1.2.3.4$ == 1.2.3.4' );

# test the CPAN style reduced significant digit form
$version = version::pp->new("1.23_01");
is ( "$version" , "1.23_01", "CPAN-style alpha version" );
ok ( $version > 1.23, "1.23_01 > 1.23");
ok ( $version < 1.24, "1.23_01 < 1.24");

# test reformed UNIVERSAL::VERSION

my $error_regex = $] < 5.006
? 'version \d required'
: 'does not define \$t.{7}::VERSION';

{
my ($fh, $filename) = tempfile('tXXXXXXX', SUFFIX => '.pm', UNLINK => 1);
(my $package = basename($filename)) =~ s/\.pm$//;
print $fh "package $package;\n\$$package\::VERSION=0.58;\n1;\n";
close $fh;

$version = 0.58;
eval "use lib '.'; use $package $version";
unlike($@, qr/$package version $version/,
	'Replacement eval works with exact version');

# test as class method
$new_version = $package->VERSION;
cmp_ok($new_version,'==',$version, "Called as class method");

eval "print Completely::Unknown::Module->VERSION";
if ( $] < 5.008 ) {
	unlike($@, qr/$error_regex/,
	"Don't freak if the module doesn't even exist");
}
else {
	unlike($@, qr/defines neither package nor VERSION/,
	"Don't freak if the module doesn't even exist");
}

# this should fail even with old UNIVERSAL::VERSION
$version += 0.01;
eval "use lib '.'; use $package $version";
like($@, qr/$package version $version/,
	'Replacement eval works with incremented version');

$version =~ s/0+$//; #convert to string and remove trailing 0's
chop($version);	# shorten by 1 digit, should still succeed
eval "use lib '.'; use $package $version";
unlike($@, qr/$package version $version/,
	'Replacement eval works with single digit');

# this would fail with old UNIVERSAL::VERSION
$version += 0.1;
eval "use lib '.'; use $package $version";
like($@, qr/$package version $version/,
	'Replacement eval works with incremented digit');
unlink $filename;
}

{ # dummy up some variously broken modules for testing
my ($fh, $filename) = tempfile('tXXXXXXX', SUFFIX => '.pm', UNLINK => 1);
(my $package = basename($filename)) =~ s/\.pm$//;
print $fh "1;\n";
close $fh;

eval "use lib '.'; use $package 3;";
if ( $] < 5.008 ) {
	like($@, qr/$error_regex/,
	'Replacement handles modules without package or VERSION');
}
else {
	like($@, qr/defines neither package nor VERSION/,
	'Replacement handles modules without package or VERSION');
}
eval "use lib '.'; use $package; \$version = $package->VERSION";
unlike ($@, qr/$error_regex/,
	'Replacement handles modules without package or VERSION');
ok (!defined($version), "Called as class method");
unlink $filename;
}

{ # dummy up some variously broken modules for testing
my ($fh, $filename) = tempfile('tXXXXXXX', SUFFIX => '.pm', UNLINK => 1);
(my $package = basename($filename)) =~ s/\.pm$//;
print $fh "package $package;\n#look ma no VERSION\n1;\n";
close $fh;
eval "use lib '.'; use $package 3;";
like ($@, qr/$error_regex/,
	'Replacement handles modules without VERSION');
eval "use lib '.'; use $package; print $package->VERSION";
unlike ($@, qr/$error_regex/,
	'Replacement handles modules without VERSION');
unlink $filename;
}

{ # dummy up some variously broken modules for testing
my ($fh, $filename) = tempfile('tXXXXXXX', SUFFIX => '.pm', UNLINK => 1);
(my $package = basename($filename)) =~ s/\.pm$//;
print $fh "package $package;\n\@VERSION = ();\n1;\n";
close $fh;
eval "use lib '.'; use $package 3;";
like ($@, qr/$error_regex/,
	'Replacement handles modules without VERSION');
eval "use lib '.'; use $package; print $package->VERSION";
unlike ($@, qr/$error_regex/,
	'Replacement handles modules without VERSION');
unlink $filename;
A
}

{
$version = version::pp->new(1.2.3);
ok("$version" eq "v1.2.3", '"$version" eq 1.2.3');
$version = version::pp->new(1.0.0);
$new_version = version::pp->new(1);
ok($version == $new_version, '$version == $new_version');
}

{
$version = version::pp->new(v1.2.3_4);
is($version, "v1.2.34", '"$version" eq "v1.2.3_4"');
$version = version::pp->new(eval "v1.2.3_4");
is($version, "v1.2.34", '"$version" eq "v1.2.3_4" (from eval)');
}

# trailing zero testing (reported by Andreas Koenig).
$version = version::pp->new("1");
cmp_ok($version->numify, '==', 1.000, "trailing zeros not preserved");
$version = version::pp->new("1.0");
cmp_ok($version->numify, '==', 1.000, "trailing zeros not preserved");
$version = version::pp->new("1.0.0");
cmp_ok($version->numify, '==', 1.000000, "trailing zeros not preserved");
$version = version::pp->new("1.0.0.0");
cmp_ok($version->numify, '==', 1.000000000, "trailing zeros not preserved");

# leading zero testing (reported by Andreas Koenig).
$version = version::pp->new(".7");
cmp_ok($version->numify, '==', 0.700, "leading zero inferred");

# leading space testing (reported by Andreas Koenig).
$version = version::pp->new(" 1.7");
cmp_ok($version->numify, '==', 1.700, "leading space ignored");

# RT 19517 - deal with undef and 'undef' initialization
isnt("$version", 'undef', "Undef version comparison #1");
isnt("$version", undef, "Undef version comparison #2");
$version = version::pp->new('undef');
unlike($warning, qr/^Version string 'undef' contains invalid data/,
"Version string 'undef'");

$version = version::pp->new(undef);
like($warning, qr/^Use of uninitialized value/, "Version string 'undef'");
ok($version == 'undef', "Undef version comparison #3");
ok($version ==  undef,  "Undef version comparison #4");
eval "\$version = \version::pp->new()"; # no parameter at all
unlike($@, qr/^Bizarre copy of CODE/, "No initializer at all");
ok($version == 'undef', "Undef version comparison #5");
ok($version ==  undef,  "Undef version comparison #6");

#$version = version::pp->new(0.000001);
#unlike($warning, qr/^Version string '1e-06' contains invalid data/, "Very small version objects");
}

if (0) { #XXX
my $warning;
local $SIG{__WARN__} = sub { $warning = $_[0] };
# dummy up a legal module for testing RT#19017
my ($fh, $filename) = tempfile('tXXXXXXX', SUFFIX => '.pm', UNLINK => 1);
(my $package = basename($filename)) =~ s/\.t$//;
print $fh <<"EOF";
package $package;
use version::pp; \$VERSION = ${CLASS}->new('0.0.4');
1;
EOF
close $fh;

eval "use lib '.'; use $package 0.000008;";
like ($@, qr/^$package version 0.000008 required/,
	"Make sure very small versions don't freak");
eval "use lib '.'; use $package 1;";
like ($@, qr/^$package version 1 required/,
	"Comparing vs. version with no decimal");
eval "use lib '.'; use $package 1.;";
like ($@, qr/^$package version 1 required/,
	"Comparing vs. version with decimal only");
eval "use lib '.'; use $package v0.0.8;";
my $regex = "^$package version v0.0.8 required";
like ($@, qr/$regex/, "Make sure very small versions don't freak");

$regex =~ s/8/4/; # set for second test
eval "use lib '.'; use $package v0.0.4;";
unlike($@, qr/$regex/, 'Succeed - required == VERSION');
cmp_ok ( $package->VERSION, 'eq', '0.0.4', 'No undef warnings' );
unlink $filename;
}

{
my ($fh, $filename) = tempfile('tXXXXXXX', SUFFIX => '.pm', UNLINK => 1);
(my $package = basename($filename)) =~ s/\.pm$//;
print $fh <<"EOF";
package $package;
\$VERSION = 1.0;
1;
EOF
close $fh;
eval "use lib '.'; use $package 1.001;";
like ($@, qr/^$package version 1.001 required/,
	"User typed numeric so we error with numeric");
eval "use lib '.'; use $package v1.1.0;";
like ($@, qr/^$package version v1.1.0 required/,
	"User typed extended so we error with extended");
unlink $filename;
}

eval 'my $v = version::pp->new("1._1");';
unlike($@, qr/^Invalid version format \(alpha with zero width\)/,
"Invalid version format 1._1");

{
my $warning;
local $SIG{__WARN__} = sub { $warning = $_[0] };
eval 'my $v = version::pp->new(~0);';
unlike($@, qr/Integer overflow in version/, "Too large version");
#like($warning, qr/Integer overflow in version/, "Too large version"); XXX
}

{
local $Data::Dumper::Sortkeys= 1;
# http://rt.cpan.org/Public/Bug/Display.html?id=30004
my $v1 = version::pp->new("v0.1_1");
(my $alpha1 = Dumper($v1)) =~ s/.+'alpha' => ([^,]+),.+/$1/ms;
my $v2 = version::pp->new($v1);
(my $alpha2 = Dumper($v2)) =~ s/.+'alpha' => ([^,]+),.+/$1/ms;
is $alpha2, $alpha1, "Don't fall for Data::Dumper's tricks";
}

{
# https://rt.cpan.org/Public/Bug/Display.html?id=70950
# test indirect usage of version objects
my $sum = 0;
eval '$sum += version::pp->new("v2.0.0")';
like $@, qr/operation not supported with version object/,
	'No math operations with version objects';
# test direct usage of version objects
my $v = version::pp->new("v2.0.0");
eval '$v += 1';
like $@, qr/operation not supported with version object/,
	'No math operations with version objects';
}

{
# https://rt.cpan.org/Ticket/Display.html?id=72365
# https://rt.perl.org/rt3/Ticket/Display.html?id=102586
	# https://rt.cpan.org/Ticket/Display.html?id=78328
eval 'my $v = version::pp->new("version")';
like $@, qr/Invalid version format/,
	"The string 'version' is not a version for new";
eval 'my $v = version::pp->new("ver510n")';
like $@, qr/Invalid version format/,
	'All strings starting with "v" are not versions';
}

{
# https://rt.cpan.org/Ticket/Display.html?id=49348
my $v = version::pp->new("420");
is "$v", "420", 'Correctly guesses this is not a v-string';
$v = version::pp->new(4.2.0);
is "$v", 'v4.2.0', 'Correctly guess that this is a v-string';
}

{
# https://rt.cpan.org/Ticket/Display.html?id=50347
# Check that the qv() implementation does not change

ok(version::pp->new(1.2.3) < version::pp->new(1.2.3.1), 'Compare 3 and 4 digit v-strings');
ok(version::pp->new(v1.2.3) < version::pp->new(v1.2.3.1), 'Compare 3 and 4 digit v-strings, leaving v');
ok(version::pp->new("1.2.3") < version::pp->new("1.2.3.1"), 'Compare 3 and 4 digit v-strings, quoted');
ok(version::pp->new("v1.2.3") < version::pp->new("v1.2.3.1"), 'Compare 3 and 4 digit v-strings, quoted leading v');
}

{
eval 'version::pp->new("version")';
pass("no crash with ${CLASS}->${method}('version')");
{
	package _102586;
	sub TIESCALAR { bless [] }
	sub FETCH { "version" }
	sub STORE { }
	my $v;
	tie $v, __PACKAGE__;
	$v = version::pp->new(1);
	eval 'version::pp->new($v)';
}
pass('no crash with version->new($tied) where $tied returns "version"');
}

{ # [perl #112478]
$_112478::VERSION = 9e99;
ok eval { _112478->VERSION(9e99); 1 }, '->VERSION(9e99) succeeds'
	or diag $@;
$_112478::VERSION = 1;
eval { _112478->VERSION(9e99) };
unlike $@, qr/panic/, '->VERSION(9e99) does not panic';
}

{ # https://rt.cpan.org/Ticket/Display.html?id=79259
my $v = version::pp->new("0.52_0");
ok $v->is_alpha, 'Just checking';
is $v->numify, '0.520', 'Correctly nummified';
}

{ # https://rt.cpan.org/Ticket/Display.html?id=88495
@ver::ISA = version::pp;
is ref(ver->new), 'ver', 'ver can inherit from version';
}

{ # discovered while integrating with bleadperl
eval {my $v = version::pp->new([1,2,3]) };
like $@, qr/Invalid version format/, 'Do not crash for garbage';
eval {my $v = version::pp->new({1 => 2}) };
like $@, qr/Invalid version format/, 'Do not crash for garbage';
}

done_testing;

#!/usr/bin/perl -w

=head1 NAME

test.pl - test makerpm

=head1 SYNOPSYS

tester.t

=head1 DESCRIPTION

a set of basic tests for makerpm

=cut

BEGIN {print "1..23\n"}
END {print "not ok 1\n" unless $loaded;}

use warnings;
use strict;

sub nogo {print "not "}
sub ok {my $t=shift; print "ok $t\n";}

our($loaded);
ok(1);
$loaded=1;

my $base=`rpmbuild --nobuild --eval '%{_topdir}' 2>/dev/null`;
use File::Copy;
use File::Glob;
chdir "test-data";
chomp ($base);
my @testfiles=File::Glob::bsd_glob('Getopt-Function-0.00*.tar.gz');
foreach my $testfile (@testfiles) {
  copy($testfile,"$base/SOURCES/$testfile");
}
chdir "..";

# VERSION INFO TESTS

my $outre='Summary\:.*\%description.*\%setup.*\%build.*'
  . '\%install.*\%clean.*\%files.*\%changelog';


my @args=qw(./makerpm.pl --specs --nochown --verbose --auto-desc);


foreach my $ver ( "0.002", "0.003", "0.0031", "0.0032", "0.004" ) {
  my $file="$base/SPECS/Getopt-Function-$ver.spec";
  unlink $file;
  die "Couldn't delete file $file" if -e $file;
}

our ($comm,$stat,$out);

# this command tests that makerpm can recognise newer package data in
# which case it should bomb out.

$comm = join " ", @args, "--source=Getopt-Function-0.003.tar.gz", "2>&1";

$out=`$comm`;
$stat=$? >> 8;
nogo if ($stat == 0);
ok(2);
unless ($stat == 255) {
    warn "$comm gave unexpected status got status $stat, output:\n$out\n";
    nogo;
}
ok(3);
nogo unless $out =~ m/data\s+dir.+too\s*new/;
ok(4);
nogo if -e "$base/SPECS/Getopt-Function-0.003.spec";
ok(5);

# this command should should work correctly but warn about bad version

$comm = join " ", @args, "--source=Getopt-Function-0.0031.tar.gz", "2>&1";

$out=`$comm`;
$stat=$? >> 8;

nogo unless $stat == 0; #perl die
ok(6);
nogo unless $out =~ m/$outre/ms;
ok(7);
nogo unless $out =~ m/RPM data dir is newer than makerpm/ms;
ok(8);
nogo unless -e "$base/SPECS/Getopt-Function-0.0031.spec";
ok(9);

# this command should just work

$comm = join " ", @args, "--source=Getopt-Function-0.0032.tar.gz", "2>&1";

$out=`$comm`;
$stat=$? >> 8;

nogo unless $stat == 0; #perl die
ok(10);
nogo unless $out =~ m/$outre/ms;
ok(11);
nogo unless -e "$base/SPECS/Getopt-Function-0.0032.spec";
ok(12);


# BUILD TESTS 
# should automatically derive description and build to end

$comm = join " ", @args, "--source=Getopt-Function-0.002.tar.gz", "2>&1";

$out=`$comm`;
$stat=$? >> 8;

nogo unless $stat == 0; #perl die
ok(13);
nogo unless $out =~ m/$outre/ms;
ok(14);

# we need a test for insertion of the module summary in the case of
# the description not mentioning perl modules.
#nogo unless $out =~ m/This package contains the perl module Getopt-Function.*B\<aim\>/ms;

nogo unless $out =~ m/perl/;
ok(15);
nogo unless $out =~ m/module/;
ok(16);
nogo unless -e "$base/SPECS/Getopt-Function-0.002.spec";
ok(17);

my $rpmbuild="rpmbuild -ba";

$out=`$rpmbuild $base/SPECS/Getopt-Function-0.002.spec 2>&1`;
$stat=$? >> 8;

nogo unless $stat == 0; #perl die
ok(18);

# should use package provided description and build to end

$comm = join " ", @args, "--source=Getopt-Function-0.004.tar.gz", "2>&1";

$out=`$comm`;
$stat=$? >> 8;

nogo unless $stat == 0; #perl die
ok(19);
nogo unless $out =~ m/$outre/ms;
ok(20);
nogo unless $out =~ m/Getopt::Function is an interface to Getopt::Mixed/ms;
ok(21);
nogo unless -e "$base/SPECS/Getopt-Function-0.004.spec";
ok(22);

$out=`$rpmbuild $base/SPECS/Getopt-Function-0.004.spec 2>&1`;
$stat=$? >> 8;

nogo unless $stat == 0; #perl die
ok(23);



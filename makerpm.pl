#!/usr/bin/perl -w
#
#
#	makerpm.pl - A Perl script for building binary distributions
#		     of Perl packages
#
#	This scrbipt is Copyright (C) 1999	Jochen Wiedmann
#						Am Eisteich 9
#						72555 Metzingen
#					        Germany
#
#						E-Mail: joe@ispsoft.de
#
#	You may distribute under the terms of either the GNU General
#	Public License or the Artistic License, as specified in the
#	Perl README.
#
#       Some parts of this script were modified by RedHat 2000.
#
#       This script is Copyright (C) 2000/2001  Michael De La Rue
#                                               <mikedlr@tardis.ed.ac.uk>
#
#       for reliable contact, you may call +48 601 270538 (expensive to
#       call from everywhere in the world so unlikely to be spammed to
#       death) between 18 and 21 GMT.
#
#       The same terms as above apply.  As a matter of preference You
#       are encouraged to avoid the Artistic license which is believed
#       to be somewhat legally ambiguous.  This is not a binding
#       requirement in any way.

require 5.003; #because of use of my variables etc..

use strict;

use Cwd ();
use File::Find ();
use File::Path ();
use File::Spec ();
use File::Basename ();
use Getopt::Long ();
use Config ();
use Symbol;



use vars qw($VERSTR $VERSION $ID);

( $VERSION ) = ( $VERSTR= "makerpm 0.400 2003/06/17, (C) 1999 Jochen Wiedmann (C) 2001,2003 Michael De La Rue") =~ /([0-9]+\.[0-9]+)/;
$ID = '$Id: makerpm.pl,v 1.23 2004/01/01 21:26:29 mikedlr Exp $';

=head1 NAME

makerpm - Build binary distributions of Perl packages

=head1 SYNOPSIS

Create a SPECS file:

  makerpm --specs --source=<package>-<version>.tar.gz \
          --copyright="GPL or Artistic"

Apply the SPECS file (which in turn uses makerpm.pl):

  rpm -ba <package>-<version>.spec

Create a PPM and a PPD file:

  makerpm --ppm --source=<package>-<version>.tar.gz

=head1 DESCRIPTION

The I<makerpm> script is designed for creating binary distributions of
Perl modules, for example RPM packages (Linux) or PPM files (Windows,
running ActivePerl).

=head2 Creating RPM packages

To create a new binary and source RPM, you typically store the tar.gz
file in F</usr/src/redhat/SOURCES> (F</usr/src/packages/SOURCES> in
case of SuSE and F</usr/src/OpenLinux/SOURCES> in case of Caldera) and
do a

  makerpm --specs --source=<package>-<version>.tar.gz

This will create a SPECS file in F</usr/src/redhat/SPECS>
(F</usr/src/packages/SOURCES> in case of SuSE and
F</usr/src/OpenLinux/SOURCES> in case of Caldera) which you
can use with

  rpm -ba /usr/src/redhat/SPECS/<package>-<version>.spec

If the default behaviour is fine for you, that will do. Otherwise see
the list of options below.


=head2 Creating PPM packages

A PPM package consists of two files: The PPD (Perl Package description)
file which contains XML source describing the package details and the
PPM file which is nothing else than the archived blib directory.

You can create the package with

  makerpm --ppm --source=<package>-<version>.tar.gz

=head2 Command Line Options

There are many command line options.  For the most part you don't have
to use them since makerpm will I<do the right thing>.  You should
at least consider setting --copyright however.  


Here is a full list:

=over 8

=item --auto-desc

Activate automatic building of the description field.  See full
description below.

=item --build

Compile the sources, typically by running

	perl Makefile.PL
	make

=item --build-root=<dir>

Installation of the Perl package occurs into a separate directory, the
build root directory. For example, a package DBI 1.07 could be installed
into F</var/tmp/DBI-1.07>. Binaries are installed into F<$build_root/usr/bin>
rather than F</usr/bin>, man pages in F<$build_root/usr/man> and so on.

The idea is making the build process really reproducible and building the
package without destroying an existing installation.

You don't need to supply a build root directory, a default name is
choosen.

=item --built-dir=<directory>

By default, even when just making a spec file, makerpm extracts and
builds the package in order to get information from it.  If the
package has already been built somewhere then this option allows us to
just use the given directory with no modification needed.  You must
ensure yourself that the directory contains a completely built package
otherwise things could go horribl wrong.

=item --copyright=<msg>

Set the packages copyright message. The default is

  Probably the same terms as perl.  Check.

You are suggested to change this to match the actual package copyright.

=item --nochown

Setting --nochown will stop makerpm from trying to change the
ownership of files which means that it can be run as any user. 

=item --data-dir=<directory>

The directory <directory>/<package-name> contains data for the package
in files in there.  See below.

=item --debug

Turns on debugging mode. Debugging mode prevents most things from really
being done and implies verbose mode.

=item --desc-file=<file>

Uses the file given as the description field for the RPM.

=item --find-requires

When writing the spec file this option will write lines to use the
special perl find-requires and find-provides programs which will then
automatically generate dependancies between different perl rpms.  This
is automatic with RPM version 4 so you should never need to use this
option.

=item --help

Print the usage message and exit.

=item --install

Install the sources, typically by running

	make install

Installation doesn't occur into the final destination. Instead a
so-called buildroot directory (for example F</var/tmp/build-root>)
is created and installation is adapted relative to that directory.
See the I<--build-root> option for details.

=item --make=<path>

Set path of the I<make> binary; defaults to the location read from Perl's
Config module. L<Config(3)>.

=item --makeopts=<opts>

Set options for running "make" and "make install"; defaults to none.

=item --makemakeropts=<opts>

If you need certain options for running "perl Makefile.PL", this is
your friend. By default no options are set.

N.B. New in makerpm2.  To set multiple options this should be
called multiple times.  Whitespace included in the argument is passed
through intact.

In order to get a module to work for multiple different versions of
perl, (in several different versions of RedHat, for example), you
should consider using

  "--makemakeropts=LIB=/usr/lib/perl5/site_perl"

But don't do that if you are packaging a perl module with binary parts.

=item --makeperlopts=<opts>

If you need to send certain options to the perl when running "perl
Makefile.PL", this is your friend. By default no options are set.

These are set before Makefile.PL is named on the command line.  It is
possible also to run scripts etc. using this.

=item --mode=<mode>

Set build mode, for example RPM or PPM. By default the build mode
is read from the script name: If you invoke it as I<makerpm>, then
RPM mode is choosen. When running as I<makeppm>, then PPM mode is
enabled.

=item --noname-prefix

With this option the package will be named without the prefix perl.
This instead of B<Getopt::YAGO> becoming perl-Getopt-YAGO, it will
become simply Getopt-YAGO.  

=item --package-name=<name>

=item --package-version=<version>

Set the package name and version. These options are required for --build and
--install.

=item --ppm

=item --ppm-ppdfile

=item --ppm-ppmfile

Create PPM related files.  See B<creating PPD files> above.

=item --prep

Extract the sources and prepare the source directory.

=item --requre=<package name>

Add the name of a package to the requires list for RPM

=item --rpm-base-dir=<dir>

=item --rpm-build-dir=<dir>

=item --rpm-source-dir=<dir>

=item --rpm-specs-dir=<dir>

Sets certain directory names related to RPM mode, defaults to
F</usr/src/redhat> (or F</usr/src/packages> on SuSE Linux or
F</usr/src/OpenLinux> on Caldera) F<$topdir/BUILD>, F<$topdir/SOURCES>
and F<$topdir/SPECS>.

=item --rpm-group=<group>

Sets the RPM group; defaults to Development/Languages/Perl.

=item --rpm-version=<number>

Forces the makerpm to assume the given RPM version, writing a spec
file for it as appropriate

=item --setup-dir=<dir>

Name of setup directory; defaults to <package>-<version>. The setup
directory is the name of the directory that is created by extracting
the sources. Example: DBI-1.07.

=item --source=<file>

Source file name; used to determine defaults for --package-name and
--package-version. This option is required for --specs and --prep.

=item --summary=<msg>

Summary line; defaults to "The Perl package <name>".

=item --verbose

Turn on verbose mode. Lots of debugging messages are emitted.

=item --version

Print version string and exit.

=back

=head1 INFLUENCING THE RPM WITH CONFIGURATION Files

By putting configuration files inside the module or in a given
directory it is possible to influence the building of the package.
This is currently only implemented for RPM, but could be extended to
other formats..

When it is extended to other formats, I'd expect the current mechanism
to change a little.  See below.

=over

=item the pkg-data-general directory

This is currently not implemented.  Once I get a directory name
reservation within the module directory it will be done.

The plan is that in the directory will contain those configuration
values which can be shared between different package formats.  Typical
of this would be the description.

Currently I'm not clear about what else can be shared.  Possibly the
documentation list?

=item the pkg-data-XXX directory

If the module contains a directory pkg-data-rpm in the main directory
of the distribution then files from there are used for package
information.  This is the best way for authors of perl modules to make
their module easy to automatically convert into a fully featured RPM.

=item an override file

In order to provide your own descriptions of certain RPMs, you can put
a file with the name of the module into a specified directory.  This
will then be used in the description field exactly as it is.  This
file will override all other possibilities since we assume that the
package builder could delete the override file if wanted.  Where there
turns out to be an C<pkg-data-XXX/description> as well as a description we
give a warning.

=back

=head2 files supported

=over

=item *

requires

The file requires file is used to generate requires.  Each required
package is separated from the previous by whitespace.  For example one
requirement per line.

=item *

description

This file provides the description of the module.  It is used verbatim.

=item *

docfiles

This file contains a list of documentation files.  It is added
verbatim to the file list.  If no file is given then if any of the
following: README, COPYING or doc(s|u.*) are present they are included
automatically.

=item *

build.sh install.sh clean.sh pre.sh post.sh preun.sh postun.sh
verify.sh

These give direct access to the various RPM scripts of (almost)the
same names.  The text included is copied verbatim into the spec file.

The prep and build scripts are run after makerpm's normal options.
The clean script is run before hand (whilst the build directory is
still there) install script is run after deleting the previous build
root, but before running the normal install options.  This means that
you have to create your own directories.

=back

=head1 AUTOMATIC FUNCTIONS

Using the C<--auto-desc> command line option, automatic building of
description fields can be set up.  This is designed for bulk building
of RPMs from many sources.  There are several possible ways that this
function can get the description.

=over

=item override files

Before considering automatic description discovery, the configuration
files described above.  If found the file description is used verbatim
in the description field.  This means that authors can provide a good
description themselves and that if the automatic mechanisms fail, they
can be overridden on an occasional basis whilst stil working for the
other modules being built.

=item the README file

In most modules the primary source of the description is the README
file.  In most cases, if it exists this should be a good guess.

=item the DESCRIPTION in a module

If a module can be found which seems to have a reasonable name or is
the only perl module which is found in the package then the
DESCRIPTION section of the POD documentation will be extracted and
used as the RPM description.

=back

=head1 HANDLING RPM VERSIONS

Since the format of the RPM spec file has changed in the past and will
probably change in the future, there must be some handling of the
version of RPM.  In the normal case, makerpm runs B<rpm --version> and
examines the output.  This can be overridden by using the
B<--rpm-version> option to makerpm.

Currently only RPM version 2 up to 4 are fully supported.  Earlier
versions should cause an abort.  We assume that newer versions of RPM
will attempt to keep compatibility with current versions so we proceed
with building the spec file, giving only a warning.

When later versions are verified/made correct, the program should be
updated so that it doesn't give a warning.  As always, it is up to the
user to verify that makerpm runs succesfully :-)

=head1 EXCLUDING FILES

Sometimes there is a clash between two different perl distribution
packages about the modules included.  This happens, for example,
when one module from a package becomes standard but the others aren't.

In this case the solution is to build the package as normal, but to
exclude those extensions..

=cut

package Distribution;
use Symbol;

$Distribution::TMP_DIR = '/tmp';
foreach my $dir (qw(/var/tmp /tmp C:/Windows/temp D:/Windows/temp)) {
    if (-d $dir) {
	$Distribution::TMP_DIR = $dir;
	last;
    }
}

#$Distribution::COPYRIGHT = "Artistic or GNU General Public License,"
#    . " as specified by the Perl README";
$Distribution::COPYRIGHT = "Probably the same terms as perl.  Check.";


sub new {
    my $proto = shift;
    my $self = { @_ };
    bless($self, ref($proto) || $proto);

    if ($self->{'source'}  &&
	$self->{'source'} =~ /(.*(?:\/|\\))?(.*)-(.+)
                              (\.(tar\.gz|tgz|zip))$/x) {
	$self->{'package-name'} ||= $2;
	$self->{'package-version'} ||= $3;
    }

    $self->{'name'} = $self->{'package-name'}
	or die "Missing package name";
    $self->{'version'} = $self->{'package-version'}
	or die "Missing package version";

# this used to be File::Spec->curdir() - I don't understand why.  Michael
# cwd() seems useful since it lets us use the directory we start in.
    $self->{'source_dirs'} ||= [ Cwd::cwd() ];
    $self->{'default_setup_dir'} = "$self->{'name'}-$self->{'version'}";
    $self->{'setup-dir'} ||= $self->{'default_setup_dir'};
    $self->{'build_dir'} = File::Spec->curdir();
    $self->{'make'} ||= $Config::Config{'make'};
    $self->{'build-root'} ||= File::Spec->catdir($Distribution::TMP_DIR,
						 $self->{'setup-dir'});
    $self->{'copyright'} ||= $Distribution::COPYRIGHT;
    $self->{'summary'} ||= "The Perl package $self->{'name'}";

    if (!defined($self->{'start_perl'} = $self->{'perl-path'})) {
	$self->{'start_perl'} = substr($Config::Config{'startperl'}, 2)
	    if defined $Config::Config{'startperl'};
    }
    $self->{'start_perl'} = undef
	if defined($self->{'start_perl'}) && $self->{'start_perl'} eq 'undef';

    $self;
}


sub MakeDirFor {
    my($self, $file) = @_;
    my $dir = File::Basename::dirname($file);
    if (! -d $dir) {
	print STDERR "Making directory $dir\n" if $self->{'verbose'};
        File::Path::mkpath($dir, 0, 0755)  ||
	    die "Failed to create directory $dir: $!";
    }
}


sub Extract {
    my $self = shift;  my $dir = shift || File::Spec->curdir();
    print STDERR "Changing directory to $dir\n" if $self->{'verbose'};
    chdir $dir || die "Failed to chdir to $dir: $!";

    # Look for the source file
    my $source = $self->{'source'} || die "Missing source definition";
    if (! -f $source) {
	foreach my $dir (@{$self->{'source_dirs'}}) {
	    print STDERR "Looking for $source in $dir\n" if $self->{'debug'};
	    my $s = File::Spec->catfile($dir, $source);
	    if (-f $s) {
		print STDERR "Found $source in $dir\n" if $self->{'debug'};
		$source = $s;
		last;
	    }
	}
    }

    -e $source or do {
      print STDERR "Source file doesn't exist in any sourcedir; pwd ",
	 `pwd`, "\n", join ( " ", @{$self->{'source_dirs'}} ), "\n";
      die "no source file $source";
    };

    $dir = $self->{'setup-dir'};
    if (-d $dir) {
	print STDERR "Removing directory $dir" if $self->{'verbose'};
	File::Path::rmtree($dir, 0, 0) unless $self->{'debug'};
	-e $dir && die "failed to delete directory " .
	  ( File::Spec->file_name_is_absolute($dir)
	    ? ($dir) : File::Spec->catdir( (File::Spec->curdir() , "$dir") ));
    }

    print STDERR "Extracting $source\n" if $self->{'verbose'};
    my $fallback = 0;
    eval { require Archive::Tar; require Compress::Zlib; };
    if ($@) {
	$fallback = 1;
    }
    else {
	if (Archive::Tar->can("extract_archive")) {
	    if (not defined(Archive::Tar->extract_archive($source))) {
		# Failed to extract: wonder why?
		for (Archive::Tar->error()) {
		    if (/Compression not available/) {
			# SuSE's Archive::Tar does this, even though
			# Compress::Zlib is installed.  Oh well.
			# 
			$fallback = 1;
		    }
		    else {
			die "Failed to extract archive $source: $_";
		    }
		}
	    }
	} else {
	    my $tar = Archive::Tar->new();
	    my $compressed = $source =~ /\.(?:tgz|gz|z|zip)$/i;
	    my $numFiles = $tar->read($source, $compressed);
	    die("Failed to read archive $source")
	      unless $numFiles;
	    die("Failed to store contents of archive $source: ", $tar->error())
	      if $tar->extract($tar->list_files());
	}
    }

    if ($fallback) {
	# Archive::Tar is not available; fallback to tar and gzip
	my $command = $^O eq "MSWin32" ?
	    "tar xzf $source" :
	    "gzip -cd $source | tar xf - 2>&1";
	my $output = `$command`;
	die "Archive::Tar and Compress::Zlib are not available\n"
	    . " and using tar and gzip failed.\n"
	    . " Command was: $command\n"
	    . " Output was: $output\n"
		if $output;
    }
}

#RMFiles removes files which match a given regexp and fixes the
#Manifest file to reflect these changes..  Needless to say, if this
#feature is used then we have to hope the user knows why this is a
#good idea :-)

sub RMFiles {
    my $self = shift;
    my $dir = shift || ( $self->{'built-dir'} );

    my $old_dir = Cwd::cwd();
    eval {
      print STDERR "Changing directory to $dir\n" if $self->{'verbose'};
      chdir $dir || die "Failed to chdir to $dir: $!";
      my $fh = Symbol::gensym();
      open ($fh, "<MANIFEST") || die "Failed to open MANIFEST: $!";
      my @manifest=<$fh>;
      close $fh;
      my $re = $self->{'rm-files'};
      print STDERR "Removing files matching ".$self->{'rm-files'}." in $dir\n"
	if $self->{'verbose'};
      for (my $i=$#manifest; $i > -1 ; $i--) {
	chomp $manifest[$i];
	print STDERR "checking", $manifest[$i],"\n" if $self->{'verbose'};
	$manifest[$i] =~ m/$re/o or next;
	print STDERR "Removing ", $manifest[$i],"\n" if $self->{'verbose'};
	unlink $manifest[$i] 
	  || die "Failed to unlink " . $manifest[$i] . " " . $!;
	splice (@manifest,$i,1);
      }
      open ($fh, ">MANIFEST") || die "Failed to open MANIFEST: $!";
      print $fh join ("\n", @manifest); #newlinse still included
      close $fh;
    };
    my $status = $@;
    print STDERR "Changing directory to $old_dir\n" if $self->{'verbose'};
    chdir $old_dir;
    die $@ if $status;
}

sub Modes {
    my $self = shift; my $dir = shift || File::Spec->curdir();

    return if $^O eq "MSWin32";

    print STDERR "Changing directory to $dir\n" if $self->{'verbose'};
    chdir $dir || die "Failed to chdir to $dir: $!";
    my $handler = sub {
	my($dev, $ino, $mode, $nlink, $uid, $gid) = stat;
	my $new_mode = 0444;
	$new_mode |= 0200 if $mode & 0200;
	$new_mode |= 0111 if $mode & 0100;
	chmod $new_mode, $_
	    or die "Failed to change mode of $File::Find::name: $!";
	if ($self->{chown}) {
	    chown 0, 0, $_
		or die "Try --nochown; failed chown of $File::Find::name: $!";
	}
    };

#    $dir = File::Spec->curdir();
    $dir = Cwd::cwd();
    print STDERR "Changing modes in $dir\n" if $self->{'verbose'};
    File::Find::find($handler, $dir);
}

sub Prep {
    my $self = shift;
    my $old_dir = Cwd::cwd();
    eval {
	my $dir = $self->{'build_dir'};
	print STDERR "Changing directory to $dir\n" if $self->{'verbose'};
	chdir $dir || die "Failed to chdir to $dir: $!";
	if (-d $self->{'setup-dir'}) {
	    print STDERR "Removing directory: $self->{'setup-dir'}\n"
		if $self->{'verbose'};
	    #give an absolute path for better error messages.
	    File::Path::rmtree(Cwd::cwd() . '/' . $self->{'setup-dir'}, 0, 0);
	    -e $self->{'setup-dir'} && die "failed to delete directory " .
		( File::Spec->file_name_is_absolute($self->{'setup-dir'})
		  ? ($self->{'setup-dir'})
		  : File::Spec->catdir( (Cwd::cwd() ,
					 $self->{'setup-dir'}) ) );
	}
	$self->Extract();
	$self->RMFiles() if $self->{'rm-files'};
	$self->Modes($self->{'setup-dir'});
    };
    my $status = $@;
    print STDERR "Changing directory to $old_dir\n" if $self->{'verbose'};
    chdir $old_dir;
    die $@ if $status;
}

sub PerlMakefilePL {
    my $self = shift; my $dir = shift || File::Spec->curdir();
    print STDERR "Changing directory to $dir\n" if $self->{'verbose'};
    chdir $dir || die "Failed to chdir to $dir: $!";
    my @command = ($^X, @{$self->{'makeperlopts'}}, 
		   "-e",  "do 'Makefile.PL';", @{$self->{'makemakeropts'}});
    print STDERR "Creating Makefile: ". join ("| |",@command) ." \n" 
      if $self->{'verbose'};
    exit 1 if system @command;
}

sub Make {
    my $self = shift;
    if (my $dir = shift) {
	print STDERR "Changing directory to $dir\n" if $self->{'verbose'};
	chdir $dir || die "Failed to chdir to $dir: $!";
    }
    my $command = "$self->{'make'} " . ($self->{'makeopts'} || '');
    print STDERR "Running Make: $command\n";
    exit 1 if system $command;

    if ($self->{'runtests'}) {
	$command .= " test";
	print STDERR "Running Make Test: $command\n";
	exit 1 if system $command;
    }
}

sub ReadLocations {
    my %vars;
    my $fh = Symbol::gensym();
    open($fh, "<Makefile") || die "Failed to open Makefile: $!";
    while (my $line = <$fh>) {
	# Skip comments and/or empty lines
	next if $line =~ /^\s*\#/ or $line =~ /^\s*$/;
	if ($line =~ /^\s*(\w+)\s*\=\s*(.*)\s*$/) {
	    # Variable definition
	    my $var = $1;
	    my $val = $2;
	    $val =~ s/\$(\w)/defined($vars{$1})?$vars{$1}:''/gse;
	    $val =~ s/\$\((\w+)\)/defined($vars{$1})?$vars{$1}:''/gse;
	    $val =~ s/\$\{(\w+)\}/defined($vars{$1})?$vars{$1}:''/gse;
            $vars{$var} = $val;
	}
    }
    \%vars;
}

#FIXME: Makewrite and UnMakewrite
#
#These two functions make a file temporarily writeable and then reverse
#the changes so that we can make fixes but still have the correct permissions
#in the rpm

sub Makewrite {
  my $filename=shift;
  -w $filename and return undef;
  my @stat=stat($filename);
  chmod 0700, $filename or die "couldn't make file writable $filename";
  return \@stat;
}

sub UnMakewrite {
  my $filename=shift;
  my $oldperm=shift;
  my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,
      $ctime,$blksize,$blocks) = @$oldperm;
  return chmod $mode & 07777, $filename;
}

sub AdjustPaths {
    my $self = shift; my $build_root = shift;
    my $adjustPathsSub = sub {
	my $f = $_;
	return unless -f $f && ! -z _;
	my $fh = Symbol::gensym();
	my $origstate=Makewrite($f);
 	open($fh, "+<$f")
 	  or ((chmod(0644, $f) || die "Failed to chmod $File::Find::name: $!")
 	      && open($fh, "+<$f"))
 	    or die "Failed to open $File::Find::name: $!";
	local $/ = undef;
	my $contents;
	die "Failed to read $File::Find::name: $!"
	    unless defined($contents = <$fh>);
	my $modified;
	if ($self->{'start_perl'}) {
	    $contents =~ s/^\#\!(\S*perl\S*)/\#\!$self->{'start_perl'}/si;
	    $modified = 1;
	}
	if ($contents =~ s/\Q$build_root\E//gs) {
	    $modified = 1;
	}
	if ($modified) {
	    seek($fh, 0, 0) or die "Failed to seek in $File::Find::name: $!";
	    (print $fh $contents)
		or die "Failed to write $File::Find::name: $!";
	    truncate $fh, length($contents)
		or die "Failed to truncate $File::Find::name: $!";
	}
	close($fh) or die "Failed to close $File::Find::name: $!";
	defined $origstate && UnMakewrite($f,$origstate);
    };
    File::Find::find($adjustPathsSub, $self->{'build-root'});
}


sub MakeInstall {
    my $self = shift;
    if (my $dir = shift) {
	print STDERR "Changing directory to $dir\n" if $self->{'verbose'};
	chdir $dir || die "Failed to chdir to $dir: $!";
    }

    my $locations = ReadLocations();

    my $command = "$self->{'make'} " . ($self->{'makeopts'} || '')
	. " install";
    foreach my $key (qw(INSTALLPRIVLIB INSTALLARCHLIB INSTALLSITELIB
                        INSTALLSITEARCH INSTALLBIN INSTALLSCRIPT
			INSTALLMAN1DIR INSTALLMAN3DIR)) {
	my $d = File::Spec->canonpath(File::Spec->catdir($self->{'build-root'},
							 $locations->{$key}));
	$command .= " $key=$d";
    }
    print STDERR "Running Make Install: $command\n" if $self->{'verbose'};
    exit 1 if !$self->{'debug'} and system $command;

    print STDERR "Adjusting Paths in $self->{'build-root'}\n";
    $self->AdjustPaths($self->{'build-root'});

    my($files, $dirs) = $self->Files($self->{'build-root'});
    my $fileList = '';
    foreach my $dir (sort keys %$dirs) {
	next if $dirs->{$dir};
	$fileList .= "%dir $dir\n";
    }

    if ($self->{compress_manpages}) {
      foreach my $file (sort keys %$files) {
	#FIXME: this regexp is not guaranteed.  (Maybe matching
	#'/man/man\d/' would be better?)
	($file =~ m,/usr/(.*/|)man/, ) and ($file .= ".gz");
	$fileList .= "$file\n";
      }
    } else {
      foreach my $file (sort keys %$files) {
	$fileList .= "$file\n";
      }
    }

    my($filelist_path, $specs_path) = $self->FileListPath();
    if ($filelist_path) {
	my $fh = Symbol::gensym();
	(open($fh, ">$filelist_path")  and  (print $fh $fileList)
	 and  close($fh))
	    or  die "Failed to create list of files in $filelist_path: $!";
    }
    $specs_path;
}


sub Build {
    my $self = shift;
    my $old_dir = Cwd::cwd();
    eval {
	my $dir = $self->{'build_dir'};
	print STDERR "Changing directory to $dir\n" if $self->{'verbose'};
	chdir $dir || die "Failed to chdir to $dir: $!";
	$self->PerlMakefilePL($self->{'setup-dir'});
	$self->Make();
    };
    my $status = $@;
    chdir $old_dir;
    die $@ if $status;
    $self->{"built-dir"}=$self->{'build_dir'} . '/' . $self->{'setup-dir'};
}

sub CleanBuildRoot {
    my $self = shift; my $dir = shift || die "Missing directory name";
    print STDERR "Cleaning build root $dir\n" if $self->{'verbose'};
    File::Path::rmtree($dir, 0, 0) unless $self->{'debug'};
    -e $dir && die "failed to delete directory " .
      ( File::Spec->file_name_is_absolute($dir)
	? ($dir) : File::Spec->catdir( (Cwd::cwd() , "$dir") ));
}

sub Install {
    my $self = shift;
    my $old_dir = Cwd::cwd();
    my $filelist;
    eval {
	my $dir = $self->{'build_dir'};
	print STDERR "Changing directory to $dir\n" if $self->{'verbose'};
	chdir $dir || die "Failed to chdir to $dir: $!";
	#originally we deleted all files.  This is now done at the start of
	#%install meaning that the user can add files to the RPM
	# $self->CleanBuildRoot($self->{'build-root'});
	$filelist = $self->MakeInstall($self->{'setup-dir'});
    };
    my $status = $@;
    chdir $old_dir;
    die $@ if $status;
    $filelist;
}


package Distribution::RPM;

@Distribution::RPM::ISA = qw(Distribution);

{
  my($source_dir, $build_dir, $specs_dir, $topdir);

  sub Init {
    my $self = shift; my $fatal = shift;
    die "Self must be a reference" unless (ref $self);
    die "Self must be a hash reference" unless ($self =~ m/HASH/);
    my $rpm_version;

    my $last_rpm=4; #latest version of RPM we have seen
    my $next_rpm=$last_rpm+1; #latest version of RPM we have seen

    if (defined $self->{"rpm-version"}) {
      $rpm_version = $self->{"rpm-version"};
    } else {
      my $rpm_version_string = `rpm --version`;
      if ($rpm_version_string =~ /rpm\s+version\s+([2-$last_rpm])\.+/i) {
	$rpm_version=$1;
      } elsif ($rpm_version_string =~ /rpm\s+version\s+[10]\.+/i) {
	die "Cannot handle RPM before version 2: " .
	  ($rpm_version_string || "");
      } elsif ($rpm_version_string
	       =~ /rpm\s+version\s+([$next_rpm-9]|\d\d+)/i) {
	$rpm_version=$last_rpm;
	warn "Your RPM is a new version.  I'm going to pretend it's "
	  . "rpm $last_rpm";
      } elsif ($rpm_version_string =~ /rpm\s+version\s/i) {
	$rpm_version=$last_rpm;
	warn "RPM version unkown.  I'm going to pretend it's $last_rpm";
      } else {
	die "RPM --version option didn't work as expected..";
      }
    }
    $self->{"rpm-version"}=$rpm_version;

  CASE: {
      $rpm_version == 2 && do { $self->handle_rpm_version_2() ; last CASE;};
      $rpm_version == 3 && do { $self->handle_rpm_version_3() ; last CASE;};
      $rpm_version == 4 && do { $self->handle_rpm_version_4() ; last CASE;};
      die "RPM version should be between 2 and $last_rpm";
    }

    return init_directories();
  }

  sub init_directories {
    if (!$source_dir) {
      $source_dir = $ENV{'RPM_SOURCE_DIR'} if $ENV{'RPM_SOURCE_DIR'};
      $build_dir = $ENV{'RPM_BUILD_DIR'} if $ENV{'RPM_BUILD_DIR'};

      $source_dir=`rpm --eval '%_sourcedir'` unless $source_dir;
      chomp $source_dir;
      die "Failed to work out source_dir from rpm" unless $source_dir;
      $specs_dir=`rpm --eval '%_specdir'` unless $specs_dir;
      chomp $specs_dir;
      die "Failed to work out specs_dir from rpm" unless $specs_dir;
      $build_dir=`rpm --eval '%_builddir'` unless $build_dir;
      chomp $build_dir;
      die "Failed to work out build_dir from rpm" unless $build_dir;
    }
    if (!$topdir) {
      foreach my $dir ("redhat", "packages", "OpenLinux") {
	if (-d "/usr/src/$dir") {
	  $topdir = "/usr/src/$dir";
	  last;
	}
      }
      die "Unable to determine RPM topdir" unless $topdir;
    }
    $source_dir ||= "$topdir/SOURCES";
    $specs_dir ||= "$topdir/SPECS";
    $build_dir ||= "$topdir/BUILD";
    return ($source_dir, $build_dir, $specs_dir);
  }

  sub handle_rpm_version_2 {
    my $self=shift;
    my $rpm_output = `rpm --showrc`;
    foreach my $ref (['topdir', \$topdir],
		     ['specdir', \$specs_dir],
		     ['sourcedir', \$source_dir],
		     ['builddir', \$build_dir]) {
      my $var = $ref->[0];
      if ($rpm_output =~ /^$var\s+\S+\s+(.*)/m) {
	${$ref->[1]} ||= $1;
      }
    }
  }

  sub handle_rpm_version_3 {
    my $self=shift;
    my $rpm_output = `rpm --showrc`;
    my $varfunc;
    $varfunc = sub {
      my $var = shift;
      my $val;
      if ($rpm_output =~ /^\S+\s+$var\s+(.*)/m) {
	$val = $1;
	while ($val =~ /\%\{(\S+)\}/) {
	  my $vr = $1;
	  my $vl = &$varfunc($vr);
	  if (defined($vl)) {
	    $val =~ s/^\%\{\Q$vr\E\}/$vl/gs;
	  } else {
	    return undef;
	  }
	}
	return $val;
      }
      return undef;
    };

    sub handle_rpm_version_4 {
      my $self=$_[0];
      my $ret=handle_rpm_version_3(@_);
      $self->{compress_manpages}=1;
      $self->{'find-requires'}=1 unless defined $self->{'find-requires'};
      return $ret;
    }

    foreach my $ref (['_topdir', \$topdir],
		     ['_specdir', \$specs_dir],
		     ['_sourcedir', \$source_dir],
		     ['_builddir', \$build_dir]) {
      ${$ref->[1]} ||= &$varfunc($ref->[0]);
    }
  }

}

sub new {
  my $proto = shift;
  my $self = $proto->SUPER::new(@_);
  ($self->{'rpm-source-dir'}, $self->{'rpm-build-dir'},
   $self->{'rpm-specs-dir'}) = $self->Init(1);
  # rpm-data-dir is a directory for perl authors to put RPM related
  # info into.  The name is important since it must be common
  # across all perl modules and must not be used for reasons other
  # than setting up RPM builds.  For this reason it should be agreed
  # with the rest of the perl community.
  $self->{'rpm-data-dir'} = 'pkg-data-rpm';
  if ($self->{'data-dir'}) {
    my $dir=$self->{'data-dir'}/$self->{'package-name'} ;
    if (-d $dir) {
      $self->{'user-data-dir'} = $dir;
      #FIXME: if we do bulk building then this would be a
      #normal case.
      warn "Data dir $dir found\n" if $self->{'verbose'};
    } else {
      print STDERR "Didn't find data dir $dir\n" if $self->{'verbose'};
    }
  }
  $self->{'rpm-group'} ||= 'Development/Languages/Perl';
  push(@{$self->{'source_dirs'}}, $self->{'rpm-source-dir'});
  $self->{'build_dir'} = $self->{'rpm-build-dir'};
  $self;
}

#FIXME: Files should also differentiate
#  configuration files, at least any in /etc
#  documentation??

#this funcgtion creates four hashes
#%d - directories in the build %dirs - the same but with full path
#%f - files in the build %files - the same but with full path
#
# the keys give the name.  
# 
# the value will be 1 for files
# for directories 0 means a directory to be included.  1 means a directory
# that should be skipped

sub Files {
  my $self = shift;  my $buildRoot = shift;
  my(%files, %dirs);
  my $findSub = sub {
    #FIXME: better handling of perllocal.pod might be desirable (why???).
    #For example, we could store its contents in $self and then output it
    #into the specfile in the postinst script.  This could then add it
    #to the live systems perllocal.pod.

    if (-d $_) {
      $dirs{$File::Find::name} ||= 0;
      $dirs{$File::Find::dir} = 1;
    } elsif (-f _) {
      $dirs{$File::Find::dir} = 1;
      $File::Find::name =~ m,/usr/lib/perl\d+/.*/perllocal.pod, and return;
      $files{$File::Find::name} = 1;
    } else {
      die "Unknown file type: $File::Find::name";
    }
  };
  File::Find::find($findSub, $buildRoot);

  # Remove the trailing buildRoot
  my(%f, %d);
  while (my($key, $val) = each %files) {
    $key =~ s/^\Q$buildRoot\E//;
    $f{$key} = $val
  }
  while (my($key, $val) = each %dirs) {
    $key =~ s/^\Q$buildRoot\E//;
    $d{$key} = $val
  }
  (\%f, \%d, \%files, \%dirs);
}

sub FileListPath {
  my $self = shift;
  my $fl = $self->{'setup-dir'} . ".rpmfilelist";
  ($fl, File::Spec->catdir($self->{'setup-dir'}, $fl));
}

sub CheckDocFileForDesc {
    my $self=shift;
    my $filename=shift;
    my $fh = Symbol::gensym();
    print STDERR "Try to use $filename as description\n"
      if $self->{'verbose'};
    open($fh, "<$filename") || die "Failed to open $filename: $!";
    my $desc;
    my $linecount=1;
  LINE: while ( my $line=<$fh> ) {
      $desc .= $line;
      $linecount++;
      $linecount > 30 && last LINE;
    }
    close($fh) or die "Failed to close $filename $!";
    #FIXME: quality check
    $linecount > 2 or return undef;
    return $desc if ( $desc );
}

# sub CheckPerlProgForDesc

# given a valid perl program see if there is a valid description in it.

sub CheckPerlProgForDesc {
    my $self=shift;
    my $filename=shift;
    my $desc;
    my $fh = Symbol::gensym();
    print STDERR "Try to use $filename as description\n"
      if $self->{'verbose'};
    open($fh, $filename) || die "Failed to open $filename: $!";;

    my $linecount=1;
  LINE: while (my $line=<$fh>){
      ($line =~ m/^=head1[\t ]+DESCRIPTION/) and do {
	  while ( $line=<$fh> ) {
	      ($line =~ m/^=(head1)|(cut)/) and last LINE;
	      $desc .= $line;
	      $linecount++;
	      $linecount > 30 && last LINE;
	  }
      };
      #tests to see if the descripiton is good enough
      #FIXME: mentions package name?
  }
    close($fh) or die "Failed to close $filename $!";
    ( $desc =~ m/(....\n.*){3}/m ) and do {
#Often descriptions don't say the name of the module and
#furthermore they always assume that we know they are a perl
#module so put in a little header.
	$desc =~ s/^\s*\n//;
	$desc="This package contains the perl module " .
	    $self->{"package-name"} . ".\n\n" . $desc;
	print STDERR "Found description in $filename\n" if $self->{'verbose'};
	return $desc;
    };
    print STDERR "No description found in $filename\n" if $self->{'verbose'};
    return undef;
}

# sub ProcessFileNames
# looks through a list of candidate files names and orders them
# according to desirability then cuts off those that look likely
# to do more harm than good.

# N.B. function call to here is done a bit wierdly...

sub ProcessFileNames {
    my ($self, $doclist) = @_;
    die "function miscall" unless (ref $self && (ref $doclist eq "ARRAY"));

    print STDERR "Sorting different perl file possibilities\n"
	if $self->{'verbose'};

    local $::simplename=$self->{"package-name"};
    local ($::A, $::B);
    $::simplename =~ s,[-/ ],_,g;
    $::simplename =~ tr/[A-Z]/[a-z]/;

#Ordering Heuristic
#
#best: the description in the module named the same as the package
#
#next: documentation files
#
#next: files named as package
#finally: prefer .pod to .pm to .pl
#
#N.B. sort high to low not low to high

    my @sort_list = sort {
	local $::res=0;
	$::A = $a;
	$::B = $b;
	$::A =~ s,[-/ ],_,g;
	$::A =~ tr/[A-Z]/[a-z]/;
	$::B =~ s,[-/ ],_,g;
	$::B =~ tr/[A-Z]/[a-z]/;

	#bundles seem a bad place to look from our limited experience
	#this might be better as an exception on the next rule??
	return $::res
	    if ( $::res = - (($::B =~ m/(^|_)bundle_/ )
			     <=> ($::A =~ m/(^|_)bundle_/ )) ) ;
	return $::res
	    if ( $::res = (($::B =~ m/$::simplename.(pm|pod|pod)/ )
			   <=> ($::A =~ m/$::simplename.(pm|pod|pod)/ )) ) ;
	return $::res
	    if ( $::res = (($::B =~ m/^readme/ )
			   <=> ($::A =~ m/^readme/ )) ) ;
	return $::res
	    if ( $::res = (($::B =~ m/.pod$/ )
			   <=> ($::A =~ m/.pod$/ )) ) ;
	return $::res
	    if ( $::res = (($::B =~ m/.pm$/ )
			   <=> ($::A =~ m/.pm$/ )) ) ;
	return $::res
	    if ( $::res = (($::B =~ m/.pl$/ )
			   <=> ($::A =~ m/.pl$/ )) ) ;
	return $::res
	    if ( $::res = (($::B =~ m/$::simplename/ )
			   <=> ($::A =~ m/$::simplename/ )) ) ;
	return length $::B <=> length $::A;
    } @$doclist;

    print STDERR "Checking which fies could really be used\n"
	if $self->{'verbose'};
    my $useful=0; #assume first always good
  CASE: {
      $#sort_list == 1 && do {
	  $useful=1;
	  last CASE;
      };
      while (1) {
	  $useful==$#sort_list and last CASE;
	  #non perl files in the list must be there for some reason
	  ($sort_list[$useful+1] =~ m/\.p(od|m|l)$/) or do {$useful++; next};
	  my $cmp_name=$sort_list[$useful+1];
	  $cmp_name =~ s,[-/ ],_,g;
	  $cmp_name =~ tr/[A-Z]/[a-z]/;
	  #perl files should look something like the package name???
	  ($cmp_name =~ m/$::simplename/) && do {$useful++; next};
	   last CASE;
      }
  }
    $#sort_list = $useful;

    print STDERR "Description file list is as follows:\n  " ,
        join ("\n  ", @sort_list), "\n" if $self->{'verbose'};

    #FIXME: ref return would be more efficient
    return \@sort_list;
}

# sub CheckFilesForDesc

# runs through a list of files to see if they are there and reads in a
# description if one of them is.


sub CheckFilesForDesc {

    my $doc_list=&ProcessFileNames;

    my $self = shift;
    my $desc;

  FILE: foreach my $filename ( @$doc_list ){
      -e $filename or 
	  do {print STDERR "no $filename file" if $self->{'verbose'};
	      next FILE};
      $filename =~ m/\.p(od|m|l)$/ && do  {
	  $desc=$self->CheckPerlProgForDesc($filename);
	  $desc && last FILE;
	  next FILE;
      };
      $desc=$self->CheckDocFileForDesc($filename);
      last FILE if $desc;
  }
    return $desc;
}

#Autodesc : run after Build to try to automatically guess a
#description using files in the perl archive.
#
#run this after a build.  Assumes that it's in the package's
#build directory after a setup.

sub AutoDesc {
  my $self = shift;
  my $desc = "";
  print STDERR "Hunting for files in distribution\n" if $self->{'verbose'};

  #Files for use for a description.  Names are relative to package
  #base.  Are there more names which work good?  BLURB?  INTRO?

  my (@doc_list) = ( "README", "DESCRIPTION" );

  my $dirpref =Cwd::cwd();

  my $handler=sub {
    m/\.p(od|m|l)$/ or return;
    my $name=$File::Find::name;
    $name =~ s/^$dirpref//;
    push @doc_list, $name;
  };
  &File::Find::find($handler, '.');

  $desc=$self->CheckFilesForDesc(\@doc_list);

  unless ( $desc ) {
    warn "Failed to generate any descripiton for"
      . $self->{'package-name'} . ".\n";
    return undef;
  }

  #FIXME: what's the best way to clean up whitespace?  Is it needed at all?
  #bear in mind that both perl descriptions and rpm special case
  #indentation with white space to mean something like \verbatim

  $desc=~s/^[\t ]*//mg;		#space at the start of lines
  $desc=~s/[\t ]*$//mg;		#space at the end of lines
  $desc=~s/^[_\W]*//s; #blank / punctuation lines at the start 
    $desc=~s/\s*$//;		#blank lines at the end.

  $self->{"description"}=$desc;
  return 1;
}

#AutoDocs is a method which reads through the package and generates a
#documentation list.

sub AutoDocs() {
  my $self = shift;
  my $old_dir = Cwd::cwd();
  my @docs = ();
  my $return="";
  eval {
    my $dir =  $self->{'build_dir'} . '/' . $self->{'setup-dir'};
    print STDERR "Changing directory to $dir\n" if $self->{'verbose'};
    chdir $dir || die "Failed to chdir to $dir: $!";
    opendir (BASEDIR , ".") || die "can't open package main directory $!";
    my @files=readdir (BASEDIR);
    @docs= grep {m/(^README)|(^COPYING$)|(^doc(s|u.*)?)/i} @files;
    print STDERR "Found the following documentation files\n" ,
      join ("  " , @docs ), "\n" if $self->{'verbose'};
    foreach my $doc (@docs) {
#      $return .= "\%doc " . $self->{'setup-dir'} . '/' . $doc . "\n";
      $return .= "\%doc " . $doc . "\n";
    }
  };
  my $status = $@;
  chdir $old_dir;
  die $@ if $status;
  return $return;
}



# CheckRPMDataVersion
#
#reads information in the rpm data directory.  This is a minimum shot.
#Should design a full modular system, but it's always neat to have a
#minimal implementation anyway...
#
#assume we are in the build directory
#
#
#function holds a result cache so that it can be called repeatedly
#from different places without them needing to communicate and still
#be efficient

my %CheckRPMDataVersionResult=();
sub CheckRPMDataVersion ($) {
    my $RPMDataVersion=0.001; #the minimum version???
    my $dir=shift;
    ($dir =~ m,^/,) or ($dir= Cwd::cwd() . '/' . $dir);
    return $CheckRPMDataVersionResult{$dir}
        if defined $CheckRPMDataVersionResult{$dir};
    #only called if there is?
    -d $dir or warn "No RPM data dir";
    my $vfile=$dir . '/VERSION';
    -e $vfile && do {
	my $fh = Symbol::gensym();
	open ($fh, $vfile ) || die "Failed to open rpm data version file " .
		$vfile . ": $!";
	my ($suggest, $require);
	while (<$fh>) {
	    ( ($require) = m/^REQUIRES:\s*(\S+)/ ) && do {
		die "Required version found but not positive number"
		    unless $require =~ m/^\d+\.?\d*$/ ;
		if ($require > $RPMDataVersion) {
		    die <<END
RPM data dir is too new.  You must upgrade makerpm.
(Required version in $vfile is $require, makerpm data version is $RPMDataVersion.)
END
  ;
                }
	    };
	    ( ($suggest) = m/^SUGGESTS:\s*(\S*)/ ) && do {
		die "Suggested version found but not positive number"
		    unless $suggest =~ m/^\d+\.?\d*$/ ;
		warn "RPM data dir is newer than makerpm. Consider upgrade"
		    if $suggest > $RPMDataVersion;
	    };
#	    ( $compatible = m/^COMPATIBLE:\s*(\S*)/ ) && do {};
	}
	close($fh) or die "Failed to close " . $vfile .  ": $!";
    };
    return $CheckRPMDataVersionResult{$dir}=$RPMDataVersion;
}

sub ReadFile {
    my $self=shift;
    my $filepath=shift;
    my $fh = Symbol::gensym();
    open ($fh, $filepath) || die "Failed to open file " .
	    $filepath . ": $!";
    print STDERR "Reading ". $filepath ."\n"
	if $self->{'verbose'};
    my $returnme="";
    while (<$fh>) {
	$returnme .= $_;
    }
    close($fh) or die "Failed to close " . $filepath .  ": $!";
    return $returnme;
}

#Description - drive the hunt for description information
#
#expects build to have already been done.

sub ReadDescription {
    my $self=shift;
    my $descfile=shift;
    my $fh = Symbol::gensym();
    open ($fh, $descfile )
	|| die "Failed to open description file " .
	    $descfile . ": $!";
    print STDERR "Reading description from ". $descfile ."\n"
	if $self->{'verbose'};
    $self->{"description"}="";
    while (<$fh>) {
	$self->{"description"} .= $_;
    }
    close($fh) or die "Failed to close " . $descfile .  ": $!";
}


#Description -  drive the hunt for description information
#
#expects build to have already been done.
#


sub Description {
    my $self = shift;
    my $old_dir = Cwd::cwd();
    my $desc = "";
    my $descfilename = "description";
    die "package not yet built when looking for description"
      unless $self->{"built-dir"};
    eval {
	my $dir =  $self->{"built-dir"};
	print STDERR "Changing directory to $dir\n" if $self->{'verbose'};
	chdir $dir || die "Failed to chdir to $dir: $!";
      CASE: {
	  my $pkg_own_desc = $self->{"rpm-data-dir"} . "/" . $descfilename;

	  #case 1 - a file explicitly provided by the user
	  $self->{"desc-file"} && do {
	      my $descfile = $self->{"desc-file"};
	      -e $descfile or die "File " . $descfile . " doesn't exist";
	      -e $pkg_own_desc
		  and warn "Overriding " . $self->{"package-name"}
	          . "packages own description.  Maybe new?";
	      $self->ReadDescription($descfile);
	      last CASE;
	  };

	  #case 2 - a file provided in the data-dir by the user
	  $self->{"user-data-dir"} && do {
	      CheckRPMDataVersion($self->{"user-data-dir"});
	      print STDERR "Checking for desc file in given data directory\n"
		  if $self->{'verbose'};
	      my $descfile = $self->{'user-data-dir'} . '/'
		  . $self->{"package-name"} . '/' . $descfilename;
	      -e $descfile && do {
		  -e $pkg_own_desc
		      and warn "Overriding " . $self->{"package-name"}
		  . "packages own description.  Maybe new?";
		  my $fh = Symbol::gensym();
		  $self->ReadDescription($descfile);
		  last CASE;
	      };
	      print STDERR "No description file in data-dir\n"
		  if $self->{'verbose'};
	  };

	  #case 3 - a file provided by the package author
	  -e $pkg_own_desc && do {
	      CheckRPMDataVersion($self->{"rpm-data-dir"});
	      print STDERR "Checking for desc file in rpm's data directory\n"
		  if $self->{'verbose'};
	      $self->ReadDescription($pkg_own_desc);
	      last CASE;
	  };

	  #case 4 - try to build a description automatically
	  $self->{"auto-desc"} && do {
	      $self->AutoDesc() and last CASE;
	  };

	  warn "failed to find description for" . $self->{"package-name"};
      }
    };
    my $status = $@;
    chdir $old_dir;
    die $@ if $status;
}

sub ReadRequires {
    my $self=shift;
    my $reqfile=shift;
    my $fh = Symbol::gensym();
    open ($fh, $reqfile )
	|| die "Failed to open description file " .
	    $reqfile . ": $!";
    print STDERR "Reading description from ". $reqfile ."\n"
	if $self->{'verbose'};
    while (<$fh>) {
	s/(^|\s)#.*//; #delete comments
	foreach my $req (m/(?:(\S+)\s)/g) {
	    push @{$self->{'require'}}, $req;
	}
    }
    close($fh) or die "Failed to close " . $reqfile .  ": $!";
}

#Requires -  drive the hunt for requires information
#
#expects build to have already been done.
#

my $reqfilename = "requires";

sub Requires {
    my $self = shift;
    my $old_dir = Cwd::cwd();
    my $desc = "";
    eval {
	my $dir =  $self->{'built-dir'};
	print STDERR "Changing directory to $dir\n" if $self->{'verbose'};
	chdir $dir || die "Failed to chdir to $dir: $!";
      CASE: {
	  my $pkg_own_req = $self->{"rpm-data-dir"} . "/" . $reqfilename;

	  #case 1 does not exist
	  #requires provided on the command line are additive.

	  #case 2 - a file provided in the data-dir by the user
	  $self->{"user-data-dir"} && do {
	      CheckRPMDataVersion($self->{"user-data-dir"});
	      print STDERR "Checking for requires file in given data directory\n"
		  if $self->{'verbose'};
	      my $reqfile = $self->{'user-data-dir'} . '/'
		  . $self->{"package-name"} . '/' . $reqfilename;
	      -e $reqfile && do {
		  -e $pkg_own_req
		      and warn "Overriding " . $self->{"package-name"}
		  . "packages own requires list.  Maybe new?";
		  my $fh = Symbol::gensym();
		  $self->ReadRequires($reqfile);
		  last CASE;
	      };
	      print STDERR "No description file in data-dir\n"
		  if $self->{'verbose'};
	  };

	  #case 3 - a file provided by the package author
	  -e $pkg_own_req && do {
	      CheckRPMDataVersion($self->{"rpm-data-dir"});
	      print STDERR "Checking for requires file in rpm's data directory\n"
		  if $self->{'verbose'};
	      $self->ReadRequires($pkg_own_req);
	      last CASE;
	  };

	  #case 4 - try to build requires automatically
	  #also doesn't exist.  This is the job of RPM.

      }
    };
    my $status = $@;
    chdir $old_dir;
    die $@ if $status;
}

#ReadConfigFile
#
#This function takes a filename and returns the entire contents of
#that file from the override directory or the module directory.
#

sub ReadConfigFile {
  my $self=shift;
  my $filename=shift;
  my $old_dir = Cwd::cwd();
  my $returnme=undef;
  eval {
    my $dir =  $self->{'built-dir'};
    print STDERR "Changing directory to $dir\n" if $self->{'verbose'};
    chdir $dir || die "Failed to chdir to $dir: $!";
    my $pkg_own_file = $self->{"rpm-data-dir"} . "/" . $filename;

    #a file provided in the data-dir by the user
    $self->{"user-data-dir"} && do {
      CheckRPMDataVersion($self->{"user-data-dir"});
      print STDERR "Checking for $filename in given data directory\n"
	if $self->{'verbose'};
      my $user_file = $self->{'user-data-dir'} . '/'
	. $self->{"package-name"} . '/' . $filename;
      -e $user_file && do {
	-e $pkg_own_file
	  and warn "Overriding " . $self->{"package-name"}
	    . "packages own file $pkg_own_file.  Maybe new?";
	$returnme = $self->ReadFile($user_file);
      };
      print STDERR "No override file in data-dir\n"
	if ($self->{'verbose'} and not defined $returnme);
    };
    #a file provided by the package author
    if (-e $pkg_own_file and not defined $returnme) {
      CheckRPMDataVersion($self->{"rpm-data-dir"});
      print STDERR "Checking for file $pkg_own_file in rpm's data directory\n"
	if $self->{'verbose'};
      $returnme = $self->ReadFile($pkg_own_file);
    }
    print STDERR "Didn't find file matching $filename.\n"
      if ( $self->{'verbose'} and not defined $returnme );
  };
  my $status = $@;
  chdir $old_dir;
  die $@ if $status;
  $returnme = "" unless defined $returnme;
  return $returnme;
}

sub Specs {
    my $self = shift;
    my $old_dir = Cwd::cwd();
    eval {

      # We want to do a build so that the package author has the
      # chance to create any dynamic data he wants us to be able to be
      # able to see such as platform specific scripts or text
      # format documentation derived from something else.

      unless ( $self->{"built-dir"} ) {
	$self->Prep();
	$self->Build();
      }



	$self->Description();
	$self->Requires();

	#FIXME check what side effects install has... hmm get rid of them
	#if they are important.
	my $filelist;
      #where is this file going anyway???
	$filelist = $self->{'name'}.$self->{'version'} . '.filelist'
	  unless defined $filelist;

	my($files, $dirs) = $self->Files($self->{'build-root'});

	my $specs = <<"EOF";
#Spec file created by makerpm 
#   
%define packagename $self->{'name'}
%define packageversion $self->{'version'}
%define release 1
EOF
	my $mo = $self->{'makeopts'} || '';
	$mo =~ s/\n\t/ /sg;
        $specs .= sprintf("%%define makeopts \"%s\"\n",
			  ($mo ? sprintf("--makeopts=%s",
					 quotemeta($mo)) : ""));
	foreach my $opttype ("makemakeropts", "makeperlopts") {
	  my @mmo=();
	CASE:{ 
	    ($#{$self->{"$opttype"}} > -1) and do {
	      foreach my $opt (@{$self->{"$opttype"}}) {
	      # $mmo =~ s/\n\t/ /sg; #allow through newlines???
		$opt=quotemeta(quotemeta $opt);
		$opt= "--$opttype=" . $opt ;
		push @mmo, $opt;
	      }
	      $specs .= "%define $opttype ".join (" ",@mmo). " \n";
	      last;
	    };
	    $specs .= "%define $opttype \"\"\n";
	  }
	}

	my $setup_dir = $self->{'setup-dir'} eq $self->{'default_setup_dir'} ?
	    "" : " --setup-dir=$self->{'setup-dir'}";

	my $makerpm_path = File::Spec->catdir('$RPM_SOURCE_DIR', 'makerpm.pl');
	$makerpm_path = File::Spec->canonpath($makerpm_path) . $setup_dir .
	    " --source=$self->{'source'}";

	$self->{"description"} = $self->{'summary'}
	  unless $self->{'description'};

	my $prefix='';
	$prefix="perl-" if ($self->{'name-prefix'});

	$specs .= <<"EOF";

Name:      $prefix%{packagename}
Version:   %{packageversion}
Release:   %{release}
Group:     $self->{'rpm-group'}
Source:    $self->{'source'}
Copyright: $self->{'copyright'}
BuildRoot: $self->{'build-root'}
Provides:  $prefix%{packagename}
Summary:   $self->{'summary'}
EOF

#this is something added to mirror the RedHat generated spec files..
#I think it makes sense, though maybe the version number is too
#strict?? - Michael

	$specs .= <<"EOF" if $self->{"rpm-version"} > 4;
BuildRequires: perl >= 5.6
Requires: perl >= 5.6
EOF


	if (my $req = $self->{'require'}) {
	    $specs .= "Requires: " . join(" ", @$req) . "\n";
	}

	my $runtests = $self->{'runtests'} ? " --runtests" : "";

	#Normally files should be owned by root.  If we are building as
	#non root then we can't do chowns (on any civilised operating
	#system ;-) so we have to fix the ownership with a command.
	my $defattr;
	if ($<==0) { 	$defattr="" }
	else {
	  warn "using Defattr to force all files to root ownership\n";
	  $defattr = "%defattr(-,root,root)";
	}

        use vars qw/$prep_script $build_script $install_script
                    $clean_script $pre_script $post_script
                    $preun_script $postun_script $verify_script/;
	my @scripts = ("prep", "build", "install", "clean", "pre",
		    "post","preun", "postun", "verify" );
	foreach my $script ( @scripts ) {
	  no strict "refs"; #makes for an easier life..
	  my $var = $script . "_script";
	  $$var = $self->ReadConfigFile($script . ".sh") ;
	}

	my $doclist = $self->ReadConfigFile("docfiles") ;
	$doclist = $self->AutoDocs() unless $doclist ;
	$doclist = "" unless $doclist;

	$specs .= <<"EOF";

%description
$self->{'description'}

EOF

	$specs .= <<"EOF" if $self->{'find-requires'};
# Provide perl-specific find-{provides,requires}.
%define __find_provides /usr/lib/rpm/find-provides.perl
%define __find_requires /usr/lib/rpm/find-requires.perl

EOF

	$specs .= <<"EOF";
%prep
EOF

	    $specs .= <<"EOF" ;
%setup -q -n $self->{'setup-dir'}
EOF
	    #FIXME we haven't actually checked that a file would be removed
	    #so this might give an error at prep time?
            $specs .= <<"EOF" if $self->{'rm-files'};
find $self->{'setup-dir'} -regex '$self->{'rm-files'} ' -print0 | xargs -0 rm
EOF
	$specs .= <<"EOF" ;

$prep_script

%build
EOF

#we put LANG=C becuase perl 5.8.0 on RH 9 doesn't create makefiles otherwise.  
#this should be made conditional in the case where perl starts working with 
#unicode languages..
	$specs .= "export LANG=C\n";
	$specs .= 'CFLAGS="$RPM_OPT_FLAGS" perl ';
	$specs .= '%{makeperlopts} ' if @{$self->{'makeperlopts'}};
	$specs .= ' Makefile.PL PREFIX=$RPM_BUILD_ROOT/usr ';
	$specs .= '%{makemakeropts}' if @{$self->{'makemakeropts'}};
	$specs .= "\nmake";
	$specs .= '%{makeopts}' if $self->{'makeopts'};
	$specs .= "\n";

	$specs .= <<"EOF" ;

$build_script

%install
rm -rf \$RPM_BUILD_ROOT

$install_script

#run install script first so we can pick up all of the files

eval `perl '-V:installarchlib'`
mkdir -p \$RPM_BUILD_ROOT/\$installarchlib
make install

[ -x /usr/lib/rpm/brp-compress ] && /usr/lib/rpm/brp-compress

#we don't include the packing list and perllocal.pod files since their
#functions are superceeded by rpm.  we have to actually delete them
#since if we don't rpm complains about unpackaged installed files.

find \$RPM_BUILD_ROOT/usr -type f -name 'perllocal.pod' \\\
	-o -name '.packlist' -print | xargs rm
find \$RPM_BUILD_ROOT/usr -type f -print | 
	sed "s\@^\$RPM_BUILD_ROOT\@\@g" > $filelist

if [ "\$(cat $filelist)X" = "X" ] ; then
    echo "ERROR: EMPTY FILE LIST"
    exit -1
fi
EOF

	my ($name,$passwd,$uid,$gid, $quota,$comment,$gcos,$dir,$shell,$expire)
	  = getpwent;
	#fixme: external calls not really needed
	#fixme more: date works in the local locale, but will RPM
	#then be able to hack it?!?!
	my $date=`date +'%a %b %d %Y %T'`; chomp $date;
	my $host=`hostname`; chomp $host;

	$specs .= <<"EOF" ;

%clean

$clean_script

rm -rf \$RPM_BUILD_ROOT

%pre

$pre_script

%post

$post_script

%preun

$preun_script

%postun

$postun_script

%verifyscript

$verify_script

%files -f $filelist
$defattr
$doclist

%changelog
* $date autogenerated
- by $comment <$name\@$host>
- using MakeRPM:
- $::VERSION
- $::ID
EOF

	my $specs_name = "$self->{'name'}-$self->{'version'}.spec";
	my $specs_file = File::Spec->catfile($self->{'rpm-specs-dir'},
					     $specs_name);
	$specs_file = File::Spec->canonpath($specs_file);
	print STDERR "Creating SPECS file $specs_file\n";
	print STDERR $specs if $self->{'verbose'};
	unless ($self->{'debug'}) {
	    my $fh = Symbol::gensym();
	    open($fh, ">$specs_file") or die "Failed to open $specs_file: $!";
	    (print $fh $specs) or die "Failed to write to $specs_file: $!";
	    close($fh) or die "Failed to close $specs_file: $!";
	}
    };
    my $status = $@;
    chdir $old_dir;
    die $status if $status;
}

sub PPM {
    die "Cannot build PPM files in RPM mode.\n";
}


package Distribution::PPM;

@Distribution::PPM::ISA = qw(Distribution);

sub new {
    my $proto = shift;
    my $self = $proto->SUPER::new(@_);
    $self->{'ppm-dir'} ||= Cwd::cwd();
    $self->{'ppm-ppdfile'} ||=
	$self->{'ppm-noversion'} ?
	    "$self->{'package-name'}.ppd" :
	    "$self->{'package-name'}-$self->{'package-version'}.ppd";
    if (!$self->{'ppm-ppmfile'}) {
	my($base, $dir, $suffix) =
	    File::Basename::fileparse($self->{'ppm-ppdfile'}, "\.ppd");
	die("Failed to create name PPM file name from PPD file name ",
	    $self->{'ppm-ppdfile'}) unless $suffix;
	$self->{'ppm-ppmfile'} =
	    $self->{'ppm-noversion'} ?
		"$base.tar.gz" :
		File::Spec->catfile($dir, "x86",
				    "$base.tar.gz");
    }
    $self;
}

sub Specs {
    die "Cannot build a SPECS file in PPM mode.\n";
}

sub MakePPD {
    my $self = shift;
    my $dir = File::Spec->catdir($self->{'build_dir'},
				 $self->{'setup-dir'});
    print STDERR "Changing directory to $dir\n" if $self->{'verbose'};
    chdir $dir || die "Failed to chdir to $dir: $!";
    my $command = "$self->{'make'} ppd " . ($self->{'makeopts'} || '');
    print STDERR "Running Make PPD: $command\n";
    exit 1 if system $command;
    my $fh = Symbol::gensym();
    my $ppd_name = "$self->{'package-name'}.ppd";
    open($fh, "<$ppd_name") ||
	die "Failed to open generated PPD file $ppd_name: $!";
    local $/ = undef;
    my $ppd_contents = <$fh>;
    die "Failed to read generated PPD file $ppd_name: $!"
	unless defined $ppd_contents;

    $ppd_contents =~ s/(\<codebase href=\").*(\")/$1$self->{'ppm-ppmfile'}$2/i; #"

    $ppd_name = $self->{'ppm-ppdfile'};
    $ppd_name = File::Spec->catdir($self->{'ppm-dir'}, $ppd_name)
	unless File::Spec->file_name_is_absolute($ppd_name);
    print STDERR "Creating PPD file $ppd_name.\n";
    $self->MakeDirFor($ppd_name);
    $fh = Symbol::gensym();
    (open($fh, ">$ppd_name") &&  (print $fh $ppd_contents)  &&  close($fh))  ||
	die "Failed to create PPD file $ppd_name: $!";
}

sub MakePPM {
    my $self = shift;
    my $ppm_file = $self->{'ppm-ppmfile'};
    $ppm_file = File::Spec->catdir($self->{'ppm-dir'}, $ppm_file)
	unless File::Spec->file_name_is_absolute($ppm_file);
    print STDERR "Creating PPM file $ppm_file.\n";
    $self->MakeDirFor($ppm_file);
    eval { require Archive::Tar; require Compress::Zlib; };
    if ($@) {
	# Archive::Tar is not available; fallback to tar and gzip
	my $command = $^O eq "MSWin32" ?
	    "tar czf $ppm_file blib" :
	    "tar czf - blib | gzip -c >$ppm_file 2>&1";
	print STDERR "Creating PPM file: $command\n" if $self->{'verbose'};
	$command .= " 2>&1" unless $^O eq "MSWin32";
	my $output = `$command 2>&1`;
	die "Archive::Tar and Compress::Zlib are not available\n"
	    . " and using tar failed.\n"
	    . " Command was: $command\n"
	    . " Output was: $output\n"
		if $output;
    } else {
	my @files;
        File::Find::find(sub { push(@files, $File::Find::name) if -f $_},
			 "blib");
	my $tar = Archive::Tar->new();
	my $result = $tar->add_files(@files);
	die "Failed to add files to archive: $!" unless $result;
	$result = $tar->write($ppm_file, 1);
	die "Failed to store archive $ppm_file: $!" if $result;
    }
}

sub PPM {
    my $self = shift;
    my $old_dir = Cwd::cwd();
    eval {
	$self->Prep();
	$self->Build();
	$self->MakePPD();
	$self->MakePPM();
    };
    my $status = $@;
    chdir $old_dir;
    die $status if $status;
}


package main;

sub Mode {
    return "RPM" if $0 =~ /rpm/i;
    return "PPM" if $0 =~ /ppm/i;
    undef;
}

sub Usage {
    my $mode = Mode() || "undef";
    my $build_root = File::Spec->catdir($Distribution::TMP_DIR,
					"<name>-<version>");
    my $start_perl = substr($Config::Config{'startperl'}, 2);

    my ($rpm_source_dir, $rpm_build_dir, $rpm_specs_dir) =
	Distribution::RPM->init_directories(1);

    print <<EOF;
Usage: $0 <action> [options]

Possible actions are:

  --prep	Prepare the source directory
  --build	Compile the sources
  --install	Install the compiled sources into the buildroot directory
  --specs	Create a SPECS file by performing the above steps in order
                to determine the list of installed files.
  --ppm		Create an ActivePerl package

Possible options are:

  --auto-desc                   Automatically derive the description of the
                                perl module from the contents of the package.
  --build-root=<dir>		Set build-root directory for installation;
				defaults to $build_root.
  --built-dir=<dir>             Directory where the package is already built.
  --copyright=<msg>		Set copyright message, defaults to
				"Probably the same terms as perl.  Check.".
  --data-dir                    Directory of data for defining package
                                information.
  --debug       		Turn on debugging mode
  --desc-file                   File containing description
  --help        		Print this message
  --make=<path>   		Set "make" path; defaults to $Config::Config{'make'}
  --makemakeropts=<opt>		Set an option for Makefile.PL when running
                                "perl Makefile.PL"; defaults to none.  Can be 
                                given multiple times.
  --makeperlopts=<opt>		Set an option for perl when running
                                "perl Makefile.PL"; defaults to none.  Can be 
                                given multiple times.
  --makeopts=<opts>		Set options for running "make" and "make
                                install"; defaults to none.
  --mode=<mode>			Set build mode, defaults to $mode.
      				Possible modes are "RPM" or "PPM".
  --nochown                     Don't try to chown files (for non root builds)
  --noname-prefix               Don't prefix package name with 'perl-' 
  --package-name=<name>		Set package name.
  --package-version=<name>	Set package version.
  --perl-path=<path>		Perl path to verify in generated scripts;
				defaults to $start_perl
  --require=<package>		Set prerequisite packages. May be used
				multiple times.
  --rmfiles=<regex>             Perl regular expression for files to be 
                                removed from the build directory and 
                                MANIFEST file at prep time.  DANGEROUS.
  --runtests			By default no "make test" is done. You
				can override this with --runtests.
  --setup-dir=<dir>		Name of setup directory; defaults to
				<name>-<version>
  --source=<file>		Source file name; used to determine defaults
                                for <name> and <version>.
  --summary=<msg>		One line desription of the package; defaults
				to "The Perl package <name>".
  --verbose			Turn on verbose mode.
  --version			Print version string and exit.

Options for RPM mode are:

  --rpm-base-dir=<dir>          Set RPM base directory
  --rpm-build-dir=<dir>         RPM build directory; defaults to
      				$rpm_build_dir.
  --rpm-group=<group>           RPM group, default Development/Languages/Perl.
  --rpm-source-dir=<dir>        RPM source directory; defaults to
                                $rpm_source_dir.
  --rpm-specs-dir=<dir>         RPM specs directory; defaults to
                                $rpm_specs_dir.
  --rpm-version=<integer>	Force building for a particular version of
                                RPM.

Options for PPM mode are:

  --ppm-ppdfile=<file>		Set the name of the PPD file; defaults to
				<package>-<version>.ppd in the directory
				given by ppd-dir.
  --ppm-ppmfile=<file>		Set the name of the PPM file; defaults to
      				x86/<package>-<version>.tar.gz in the
				directory given by ppd-dir.
  --ppm-dir=<dir>		Indicates the directory where to create
      				PPM and PPD file; defaults to the current
				directory.
  --ppm-noversion		Changes the default values of
				ppm-ppdfile and ppm-ppmfile to
				<package>.ppd and <package>.tar.gz,
				respectively.

$VERSTR
EOF
    exit 1;
}

{
    my %o = ( 'chown' => 1 , 'name-prefix' => 1, 
	      'makeperlopts' => [], 'makemakeropts' => []);
    Getopt::Long::GetOptions(\%o, 'auto-desc', 'build', 'build-root=s',
			     'built-dir=s',
			     'copyright=s', 'chown!', 'data-dir=s', 'debug',
			     'desc-file=s', 'find-requires!',
			     'help', 'install', 'make=s',
			     'makemakeropts=s@', 'makeopts=s', 
                             'makeperlopts=s@', 'mode=s',
			     'name-prefix!',
			     'package-name=s', 'package-version=s',
			     'ppm', 'ppm-ppdfile=s', 'ppm-ppmfile=s',
			     'ppm-dir=s', 'ppm-noversion', 'prep',
			     'require=s@', 'rpm-base-dir=s',
			     'rpm-build-dir=s', 'rpm-source-dir=s',
			     'rpm-specs-dir=s', 'rpm-group=s', 
			     'rm-files=s',
			     'runtests', 'setup-dir=s', 'source=s', 'specs',
			     'summary=s',
			     'verbose', 'version', 'rpm-version=s');
    Usage() if $o{'help'};
    if ($o{'version'}) { print "$VERSTR\n"; exit 1}
    $o{'verbose'} = 1 if $o{'debug'};

    #trap this now so it's the primary error
    die "You must give an action; --prep, --build, --install or --specs\n"
	unless $o{'specs'}||$o{'prep'}||$o{'build'}||$o{'install'};

    die "You must give the package filename in the --source option.\n"
	if ((exists $o{'specs'} || exists $o{'prep'}) and
	    not exists $o{'source'});

    my $class;
    $o{'mode'} ||= Mode();
    if ($o{'mode'} =~ /^rpm$/i) {
	$class = 'Distribution::RPM';
    } elsif ($o{'mode'} =~ /^ppm$/i) {
	$class = 'Distribution::PPM';
    } else {
	die "Unknown mode: $o{'mode'}, use either of 'RPM' or 'PPM'";
    }

    my $self;
    eval { #trap for nicer errors
	$self = $class->new(%o);
    } || do {
	$@ =~ m/Missing package name/ && do {
	    print STDERR "You must set the --package-name option\n";
	    exit 1;
	};
	$@ =~ m/Missing package version/ && do {
	    print STDERR "You must set the --package-version option\n";
	    exit 1;
	};
	die $@;
    };

    if ($o{'ppm'}) {
	$self->PPM();
    } elsif ($o{'prep'}) {
	$self->Prep();
    } elsif ($o{'build'}) {
	$self->Build();
    } elsif ($o{'install'}) {
	$self->Install();
    } elsif ($o{'specs'}) {
	$self->Specs();
    } else {
	die "Action Unknown.";
    }
}


__END__

=pod

=head1 INSTALLATION

Before using this script, you need to install the required packages:

  C<File::Spec>

If you are using Perl 5.00502 or later, then this package is already
part of your Perl installation. It is recommended to use the

  C<Archive::Tar>
  C<Compress::Zlib>

packages, if possible.

All of these packages are available on any CPAN mirror, for example

  ftp://ftp.funet.fi/pub/languages/perl/CPAN/modules/by-module

To install a package, fetch the corresponding distribution file, for
example

  Archive/Archive-Tar-0.21.tar.gz

extract it with

  gzip -cd Archive-Tar-0.21.tar.gz

and install it with

  cd Archive-Tar-0.21
  perl Makefile.PL
  make
  make test
  make install

Alternatively you might try automatic installation via the CPAN module:

  cpan		(until Perl 5.00503 you need: perl -MCPAN -e shell)
  install Archive::Tar
  install Compress::Zlib
  install File::Spec  (only with Perl 5.004 or lower)


=head1 AUTHOR AND COPYRIGHT

This script is Copyright (C) 1999

	Jochen Wiedmann
	Am Eisteich 9
	72555 Metzingen
        Germany

	E-Mail: joe@ispsoft.de

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README.

And  Copyright (C) 2001  Michael De La Rue with the same terms.


=head1 CPAN

This file is available as a CPAN script. The following subsections are
for CPAN's automatic link generation and not for humans. You can safely
ignore them.


=head2 SCRIPT CATEGORIES

UNIX/System_administration

=head2 README

This script can be used to build RPM or PPM packages automatically.

=head2 PREREQUISITES

This script requires the C<File::Spec> package.

=head1 TODO

=over 8

=item -

make a set of test cases

=item -

Add handling of configuration files: suggest anything in /etc/ is
automatically a config file.

=item -

When we use POD files to generate the description field of the RPM we
should process the POD directives.

=item -

Handling of prerequisites by reading PREREQ_PM from the Makefile

=item -

Make package relocatable

=item -

Research the best heuristic for generating descriptions from Perl
modules.

=head1 THE FUTURE

The current configuration system is designed by Michael.  Two
alternative mechanisms have been proposed.

=over

=item a

Using a single file containing configuration in a perl hash.

=item b

Using an XML file.

=back

Suggestion B<b> is currently ruled out since XML support is not
included in the default installation of perl.  As a build tool,
MakeRPM should rely on nothing which isn't available by default.

Suggestion B<a> seems to be quite resonable.  It has the advantage
that the mechanism for inheriting configuration from one package
format to another is obvious.

I currently prefer the implementation given with directories.

Anyway, the summary of attributes I think the system should have is as
follows.

=over

=item *

Nobody should have to use it.

=item *

It should be possible to set each of the parameters required by every
packaging system.

=item *

It should be easy for different packaging systems to share a common
configuration value.

=item *

It should be easy to recover any stored meta data and use it in other
programs.

=item *

It should be possible to have a different parameter value depending on
different packaging systems (e.g. the description field which is
normally shared might sometimes want to be altered for display by a
particular system).

=item *

It should be easy to override the configuration distributed with
packages during bulk building.

=item *

The configuration system should not interact with the files currently
in any CPAN module.

=item *

Versioning mechanisms should be available incase they are needed.

=back

I'd definitely consider any mechanism which fits this.  The easiest
way to get this change made is to send me the patch.

It seems to me that the name of the configuration directory must be
accepted by "the perl community" because it would then be impossible
to use a directory of the same name for other reasons.  Since this
hasn't yet been agreed with "the perl community" it is subject to
change.  If a future version does change this then at the very least a
warning will be issued when ignoring this directory.  More likely some
simple auto-detection will be used.

=head1 MAINTAINANCE STATUS

As a temporary measure, I, Michael, will attempt to maintain this
software for a short while.  My aim is to get a full build of all of
the RPMs I need for support of software I'm writing widely available.

If you have some change to make, please send it to me in an email at
the address <mikedlr@tardis.ed.ac.uk>.  This is a pretty public
address and so gets junkmail so doesn't get answered very well...

If I don't respond within two weeks, feel free to increment the
version number and release it onto CPAN.

=head1 CHANGES


2003-08-22 Michael De La Rue <mikedlr@tardis.ed.ac.uk>

      * removed --recursive option
      * built a proper test suite
      * fixes to get tests to complete

2003-07-09 Michael De La Rue <mikedlr@tardis.ed.ac.uk>

      * changes from Ed Avis added - protection against non working
        Archive::Tar, extra file checks

2003-06-12 Michael De La Rue <mikedlr@tardis.ed.ac.uk>

      * force LANG=C during build for RH9.. we will reconsider this in
        future, but it's likely that this is a safe way
      * fix (apparently old) bugs in various options 

2001-06-01 Michael De La Rue <mikedlr@tardis.ed.ac.uk>

      * add support for find_provides.perl and find_requires.perl
        since RedHat has started using them.
      * fix (apparently old) bugs in various options 

2001-02-11 Michael De La Rue <mikedlr@tardis.ed.ac.uk>

      * change to only adjust interpreter paths that contain 'perl'.
        This allows the user to create e.g. shell scripts.

2001-01-26 Michael De La Rue <mikedlr@tardis.ed.ac.uk>

       * ignore any perllocal.pod files (new version of Perl?)
       * updates to build on RPM 4.
	  - convert man page filenames to be gzip compressed.

2001-01-25  Michael De La Rue <mikedlr@tardis.ed.ac.uk>

       * Change of RPM version handling so that we can cope with
         RPM version 4 and up.

2001-01-20  Michael De La Rue <mikedlr@tardis.ed.ac.uk>

       * Changed defualt copyright to be a little clearer that
         the system doesn't actually check.
       * Added documentation collection.

2000-05-20  Michael De La Rue <mikedlr@tardis.ed.ac.uk>

       * Added support for descriptions
       * Added primitive support for automatically creating descriptions
       * Clearer help messages for bad options
       * made changelog formatting consistent with Jochen.
       * make messges come out of stderr so we see them before actions.
       * test that directory rmtrees take place (aim at non root use)

2000-01-02  Peter J. Braam <braam@redhat.com>

       * Added support for $ENV{RPM_SOURCE_DIR} and $ENV{RPM_BUILD_DIR}.
       * Added --nochown.

1999-12-16  Jochen Wiedmann <joe@ispsoft.de>

       * Added --ppm-noversion

1999-12-14  Jochen Wiedmann <joe@ispsoft.de>

       * Added PPM support

1999-12-10  Peter J. Braam <braam@redhat.com>

       * Fixed the $base_dir: correct naming is topdir and compute it
         from the rpm --showrc like the rest

1999-09-13  Jochen Wiedmann <joe@ispsoft.de>

      * Modes: Fixed the use of ||= instead of |=; thanks to Tim Potter,
        Tim Potter <Tim.Potter@anu.edu.au>
      * Now using %files -f <listfile>

1999-07-22  Jochen Wiedmann <joe@ispsoft.de>

      * Now falling back to use of "tar" and "gzip", if Archive::Tar and
        Compress::Zlib are not available.
      * Added --runtests, suggested by Seth Chaiklin <seth@pc126.psy.aau.dk>.

1999-07-09  Jochen Wiedmann <joe@ispsoft.de>

      * Now using 'rpm --showrc' to determine RPM's base dirs.

1999-07-01  Jochen Wiedmann  <joe@ispsoft.de>

      * /usr/src/redhat was used rather than $Distribution::RPM::BASE_DIR.
      * The AdjustPaths function is now handling files zero size files
        properly.
      * An INSTALLATION section was added to the docs that describes
        the installation of prerequisites.
      * A warning for <HANDLE> being possibly "0" is now suppressed with
        Perl 5.004.

1999-05-24  Jochen Wiedmann <joe@ispsoft.de>

      * Added --perl-path and support for fixing startperl in scripts.
        Some authors don't know how to fix it. :-(

=head1 SEE ALSO

L<ExtUtils::MakeMaker(3)>, L<rpm(1)>, L<ppm(1)>


=cut
#  LocalWords:  pl

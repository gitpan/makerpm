

=pod

we use the following modules.  I don't think any of them are non
standrd.  However, if you find that they aren't included in your perl,
but you can get them to work then mail me to add them as
prerequisites.

use Cwd ();
use File::Find ();
use File::Path ();
use File::Spec ();
use File::Basename ();
use Getopt::Long ();
use Config ();
use Symbol;

=cut


use ExtUtils::MakeMaker;
WriteMakefile( NAME => "makerpm",
	       VERSION_FROM => "makerpm.pl",
	       dist => {COMPRESS => "gzip",
			SUFFIX => "gz" },
#I want to stop makerpm being installed as a library, but this doesn't
#do it.. why?
	       PMLIBDIRS => [ 'lib' ],
	     );



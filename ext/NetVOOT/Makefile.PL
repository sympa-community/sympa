
use ExtUtils::MakeMaker;

WriteMakefile
  ( NAME        => 'Net::VOOT'
  , VERSION     => '0.11'
  , PREREQ_PM   =>
     { Test::More => 0
     , LWP::UserAgent => '0'

     }
  , AUTHOR      => 'Mark Overmeer'
  , ABSTRACT    => 'a VOOT client'
  , LICENSE     => 'perl'
  , EXE_FILES   => []
  );

#### the next lines are added for OODoc, which generates the
#### distribution.
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/net-voot/raw
DISTDIR         = ../public_html/net-voot/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2013
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net
__POSTAMBLE


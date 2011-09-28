use 5.012004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::SFTP::Foreign::Backend::Net_SSH_Perl',
    VERSION_FROM      => 'lib/Net/SFTP/Foreign/Backend/Net_SSH_Perl.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/SFTP/Foreign/Backend/Net_SSH_Perl.pm', # retrieve abstract from module
       AUTHOR         => 'Salvador Fandino <salva@>') : ()),
);

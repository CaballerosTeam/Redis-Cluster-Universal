use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Redis::Cluster::Universal',
    VERSION_FROM      => 'lib/Redis/Cluster/Universal.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Redis/Cluster/Universal.pm', # retrieve abstract from module
       AUTHOR         => 'Sergey Yurizin <jurzin.s@gmail.com>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
	MYEXTLIB     => 'src/libcrc$(LIB_EXT)',
	OPTIMIZE     => '-O3',
);

sub MY::postamble {
'
$(MYEXTLIB): src/Makefile
		cd src && $(MAKE) $(PASSTHRU)
';
}

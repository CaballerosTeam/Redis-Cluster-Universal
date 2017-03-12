use strict;
use warnings;
use ExtUtils::MakeMaker;

our $Verbose = 1;


WriteMakefile(
	NAME  => 'Redis::Cluster::Universal::crc',
	clean => {'FILES' => 'libcrc$(LIB_EXT)'},
);

sub MY::top_targets {
'
all :: static
pure_all :: static
static ::       libcrc$(LIB_EXT)
libcrc$(LIB_EXT): $(O_FILES)
		$(AR) cr libcrc$(LIB_EXT) $(O_FILES)
		$(RANLIB) libcrc$(LIB_EXT)
';
}

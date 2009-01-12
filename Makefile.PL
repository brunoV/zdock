use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME          => 'Zdock',
   AUTHOR        => 'Bruno Vecchi <vecchi.b.@gmail.com>',
   VERSION_FROM  => 'lib/Zdock.pm',
   ABSTRACT_FROM => 'lib/Zdock.pm',
   ( $ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ( 'LICENSE' => 'perl' )
      : () ),
   PL_FILES  => {},
   PREREQ_PM => {
      'Test::More'        => 0,
      'Moose'             => 0,
      'Text::CSV::Simple' => 0,
   },
   dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
   clean => { FILES    => 'Zdock-*' },
);

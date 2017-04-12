#!/usr/bin/env bash

make clean
perl Makefile.PL
make
cover -delete
HARNESS_PERL_SWITCHES=-MDevel::Cover make test
cover

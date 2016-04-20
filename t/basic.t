#! /usr/bin/env perl

use v5.10;
use strict;
use warnings;

use Test::More;

use Plack::Dispatch::Tiny qw<dispatcher>;

ok(defined &dispatcher, 'subroutine exists');

done_testing();

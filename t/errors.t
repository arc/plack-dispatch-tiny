#! /usr/bin/env perl

use v5.10;
use strict;
use warnings;

use Test::More;

use Plack::Dispatch::Tiny qw<dispatcher>;
use Test::Fatal;

like(exception { dispatcher('/') },
     qr/^dispatcher needs an even number of arguments\b/,
     'even number of arguments');

like(exception { dispatcher(undef, {}) },
     qr/^Undefined pattern\b/,
     'undefined pattern');

like(exception { dispatcher([], {}) },
     qr/^A route pattern may not be a reference to ARRAY\b/,
     'reference pattern');

like(exception { dispatcher(404, {}) },
     qr/^An error handler must be a CODE reference\b/,
     'non-CODE error handler');

like(exception { dispatcher('nope', {}) },
     qr{^Route pattern with no initial slash: nope\b},
     'punctuation in pattern');

like(exception { dispatcher('/!x', {}) },
     qr{^Special character in route pattern: /!x\b},
     'punctuation in pattern');

like(exception { dispatcher('/foo/**', {}) },
     qr{^Double asterisk in route pattern: /foo/\*\*(?!\S)},
     'punctuation in pattern');

like(exception { dispatcher('/', sub {}) },
     qr/^Verb dispatch table must be a HASH reference\b/,
     'non-HASH dispatch table');

like(exception { dispatcher('/', { GET => [] }) },
     qr/^A route handler must be a CODE reference\b/,
     'non-HASH dispatch table');

done_testing();

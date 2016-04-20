#! /usr/bin/env perl

use v5.10;
use strict;
use warnings;

use Test::More;

use HTTP::Request;
use Plack::Dispatch::Tiny qw<dispatcher>;
use Plack::Test;

my $app = dispatcher(
    '/'         => { GET  => sub { [200, [], ['index']] } },
    '/items'    => { GET  => sub { [200, [], ['item list']] },
                     POST => sub { [200, [], ['create item']] } },
    '/items/*'  => { GET  => sub { [200, [], ["single item $_[1]"]] },
                     PUT  => sub { [200, [], ["replace item $_[1]"]] } },
    qr{/misc/!} => { GET  => sub { [200, [], ['weird URL']] } },
    '/fail'     => { GET  => sub { die "always fails\n" } },
    404         => sub { [404, [], ['custom 404']] },
    405         => sub { [405, [], ['custom 405']] },
    500         => sub { [500, [], ["custom 500 $_[1]"]] },
);

my @cases = (
    ['front page', GET => '/', 200, 'index'],
    ['static path pattern with two HTTP methods: GET',
     GET => '/items', 200, 'item list'],
    ['static path pattern with two HTTP methods: POST',
     POST => '/items', 200, 'create item'],
    ['dynamic path pattern: GET, number',
     GET => '/items/17', 200, 'single item 17'],
    ['dynamic path pattern: GET, slug',
     GET => '/items/foo-bar_baz.yay', 200, 'single item foo-bar_baz.yay'],
    ['dynamic path pattern: PUT, number',
     PUT => '/items/foo', 200, 'replace item foo'],
    ['direct regex',
     GET => '/misc/!', 200, 'weird URL'],
    ['nonexistent URL',
     GET => '/nope', 404, 'custom 404'],
    ['invalid HTTP method',
     POST => '/', 405, 'custom 405'],
    ['exception in handler',
     GET => '/fail', 500, "custom 500 always fails\n"],
    ['invalid char in path element',
     GET => '/items/$', 404, 'custom 404'],
    ['double slash',
     GET => '/items//17', 404, 'custom 404'],
);

my $tester = Plack::Test->create($app);

for (@cases) {
    my ($desc, $verb, $path, $status, $content) = @$_;
    my $rq = HTTP::Request->new($verb => $path);
    my $res = $tester->request($rq);
    is($res->code, $status, "$desc (status)");
    is($res->content, $content, "$desc (content)");
}

done_testing();

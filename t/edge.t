#! /usr/bin/env perl

use v5.10;
use strict;
use warnings;

use Test::More;

use HTTP::Request;
use Plack::Dispatch::Tiny qw<dispatcher>;
use Plack::Test;

{
    my $tester = Plack::Test->create(dispatcher());
    my $rq = HTTP::Request->new(GET => '/');
    my $res = $tester->request($rq);
    is($res->code, 404, 'no dispatch targets');
}

{
    my $tester = Plack::Test->create(dispatcher(
        405 => sub { [405, [], ['method not allowed']] },
    ));
    my $rq = HTTP::Request->new(GET => '/');
    my $res = $tester->request($rq);
    is($res->code, 404, 'error handler but no dispatch targets');
}

{
    my $tester = Plack::Test->create(dispatcher(
        '/' => { GET => sub { [200, [], ['index']] } },
    ));
    my $rq = HTTP::Request->new(GET => '/');
    my $res = $tester->request($rq);
    is($res->code, 200, 'single dispatch target; no crash on 5.10.0');
}

{
    my $tester = Plack::Test->create(dispatcher(
        '/'        => { GET => sub { shift; [200, [], [scalar @_, @_]] } },
        '/items/*' => { GET => sub { shift; [200, [], [scalar @_, @_]] } },
    ));

    my $rq1 = HTTP::Request->new(GET => '/');
    my $res1 = $tester->request($rq1);
    is($res1->content, '0', 'correct arg count for index');

    my $rq2 = HTTP::Request->new(GET => '/items/foo');
    my $res2 = $tester->request($rq2);
    is($res2->content, '1foo', 'correct arg count for route with argument');
}

{
    my $tester = Plack::Test->create(dispatcher(
        '/'                   => { GET => sub { [200, [], ['index']] } },
        qr{/(?<capture>zomg)} => { GET => sub { [200, [], [$+{capture}]] } },
    ));
    my $rq = HTTP::Request->new(GET => '/zomg');
    my $res = $tester->request($rq);
    is($res->content, 'zomg', 'named capture');
}

done_testing();

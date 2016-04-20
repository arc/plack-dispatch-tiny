package Plack::Dispatch::Tiny;

use v5.10;
use strict;
use warnings;

use Exporter qw<import>;
our @EXPORT_OK = qw<dispatcher>;

use Carp qw<confess>;
use HTTP::Status qw<status_message>;
use Plack::Request;
use Try::Tiny qw<try catch>;

our $VERSION = '0.001_001';

sub trivial_error {
    my ($code) = @_;
    my $status = status_message($code);
    [$code, ['Content-type', 'text/plain'], ["$code $status\n"]];
}

sub dispatcher {
    confess("dispatcher needs an even number of arguments") if @_ % 2;

    my (@patterns, @subdispatchers);
    my %error_handler = map do { my $i = $_; $i => sub { trivial_error($i) } },
        404, 405, 500;

    while (@_) {
        my ($pat, $target) = splice @_, 0, 2;

        if (!defined $pat) {
            confess("Undefined pattern");
        }
        elsif (ref $pat && !re::is_regexp($pat)) {
            confess("A route pattern may not be a reference to ", ref $pat);
        }
        elsif (exists $error_handler{$pat}) {
            confess("An error handler must be a CODE reference")
                if ref $target ne 'CODE';
            $error_handler{$pat} = $target;
        }
        else {
            my $rx = re::is_regexp($pat) ? $pat : do {
                confess("Route pattern with no initial slash: $pat")
                    if $pat !~ m{\A/};
                confess("Special character in route pattern: $pat")
                    if $pat =~ m{[^-_./*a-zA-Z0-9]};
                confess("Double asterisk in route pattern: $pat")
                    if $pat =~ /\*\*/;
                $pat =~ s{\*}{([-_.a-zA-Z0-9]+)}g;
                qr/$pat/;
            };

            confess("Verb dispatch table must be a HASH reference")
                if ref $target ne 'HASH';
            confess("A route handler must be a CODE reference")
                if grep ref ne 'CODE', values %$target;

            push @patterns,       $rx;
            push @subdispatchers, { %$target };
        }
    }

    my $dispatch_rx = do {
        my $i = -1;
        my @p = map do { $i++; qr/$_(*MARK:$i)/ }, @patterns;
        local $" = '|';
        @p == 0 ? qr/(?!)/ : @p == 1 ? qr/\A@p\z/ : qr/\A(?|@p)\z/;
    };

    sub {
        my ($env) = @_;
        my $rq = Plack::Request->new($env);
        try {
            my @args = $rq->path =~ $dispatch_rx
                or return $error_handler{404}->($rq);
            splice @args, $#-;
            my $handler = $subdispatchers[our $REGMARK]{ $rq->method }
                // return $error_handler{405}->($rq);
            $handler->($rq, @args);
        } catch {
            try   { $error_handler{500}->($rq, my $exn = $_) }
            catch { trivial_error(500) };
        };
    };
}

1;
__END__

=head1 NAME

Plack::Dispatch::Tiny - REST-friendly minimal web dispatcher

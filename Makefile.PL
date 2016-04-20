use ExtUtils::MakeMaker;
use 5.010; # relies on post-5.10 regex features
my $module_file = 'lib/Plack/Dispatch/Tiny.pm';
WriteMakefile(
    NAME          => 'Plack::Dispatch::Tiny',
    AUTHOR        => 'Aaron Crane <arc@cpan.org>',
    ABSTRACT_FROM => $module_file,
    VERSION_FROM  => $module_file,
    PREREQ_PM     => {
        'Test::More'  => '0.88',
    },
);

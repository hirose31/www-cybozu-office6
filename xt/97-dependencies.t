# -*- mode: cperl; -*-
use Test::Dependencies
    exclude => [qw(Test::Dependencies Test::Base Test::Perl::Critic
                   WWW::Cybozu::Office6::Util
                   WWW::Cybozu::Office6::Timecard
                   WWW::Cybozu::Office6::Todo
                   WWW::Cybozu::Office6::Schedule
                 )],
    style   => 'light';
ok_dependencies();

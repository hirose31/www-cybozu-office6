# -*- mode: cperl; -*-
use Test::More;
use WWW::Cybozu::Office6;
use Config::Pit;
use utf8;

plan tests => 2;

my $cb = WWW::Cybozu::Office6->new(debug => $ENV{DEBUG}||0);
my $pit = pit_get("cybozu6");

is($cb->userid, $pit->{userid}, 'userid');

$cb->userid('test');
is($cb->userid, 'test', 'userid (set)');

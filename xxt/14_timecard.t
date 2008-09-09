# -*- mode: cperl; -*-
use Test::Base;
use WWW::Cybozu::Office6;
use Web::Scraper;
use utf8;

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Deparse = 1;
sub p(@) {
    my $d = Dumper(\@_);
    $d =~ s/\\x{([0-9a-z]+)}/chr(hex($1))/ge;
    print $d;
}

plan tests => 7 * blocks;

my @ATTRS = qw(date in out go_out come_back memo);

run {
    my $block = shift;
    my $cb  = WWW::Cybozu::Office6->new(debug => $ENV{DEBUG}||0);

    my %param;
    for my $attr (@ATTRS) {
        $param{$attr} = $block->$attr if $block->$attr;
    }

    my($ret, $timecard);
    ### retrieve
    $timecard = $cb->timecard->retrieve(date => $param{date});
    ok(!$timecard->[0]{in}, "retrieve#1");

    ### update
    $ret = $cb->timecard->update(%param);
    ok($ret, "update");

    ### retrieve after update
    $timecard = $cb->timecard->retrieve(date => $param{date});
    ok($timecard->[0]{in}, "retrieve#2");
    p $timecard if $ENV{DEBUG};

    for my $when (qw(in out)) {
        is($timecard->[0]{$when}, $block->$when, $when);
    }

    ### update (clear)
    my %param2 = map { $_ => "" } @ATTRS;
    $param2{date} = $param{date};
    $ret = $cb->timecard->update(%param2);
    ok($ret, "update (clear)");

    ### retrieve (clear)
    $timecard = $cb->timecard->retrieve(date => $param2{date});
    ok(!$timecard->[0]{in}, "retrieve (clear)");
};

__END__
=== YYYY-MM-DD
--- date: 2038-09-08
--- in:  10:00
--- out: 18:00

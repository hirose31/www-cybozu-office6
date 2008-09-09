# -*- mode: cperl; -*-
use Test::Base;
use WWW::Cybozu::Office6;
use Web::Scraper;
use utf8;

plan tests => 3 * blocks;

run {
    my $block = shift;
    my $title = $block->title."_$$";
    my $memo  = $block->memo."_$$";
    my $cb = WWW::Cybozu::Office6->new(debug => $ENV{DEBUG}||0);
    $cb->schedule->create('date'   => $block->date,
                          'title'  => $title,
                          'memo'   => $memo,
                         );

    my $schedules = $cb->schedule->retrieve('date' => $block->date);

    my $my_schedule = undef;
    for my $s (@{$schedules->{overday}}) {
        warn $s->{title} if $ENV{DEBUG};
        if ($s->{title} eq $title) {
            $my_schedule = $s;
            last;
        }
    }
    is(defined($my_schedule), 1, $block->name);

    my $r = $cb->schedule->delete(date => $my_schedule->{date},
                                  id   => $my_schedule->{id},
                                 );
    is($r, 1, 'delete one');

    $schedules = $cb->schedule->retrieve('date' => $block->date);
    $my_schedule = undef;
    for my $s (@{$schedules->{overday}}) {
        warn $s->{title} if $ENV{DEBUG};
        if ($s->{title} eq $title) {
            $my_schedule = $s;
            last;
        }
    }
    is(defined($my_schedule), '', $block->name);
};

__END__
=== normal
--- date: 2008-9-8
--- title: テスト1
--- memo: テスト1のメモ

=== zero padding
--- date: 2008-09-08
--- title: テスト2
--- memo: テスト2のメモ

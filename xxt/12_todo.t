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

plan tests => 6 * blocks;

my @ATTRS = (
    'todo_name',
    'category',
    'limit_date',
    'priority',
    'memo',
   );

sub find_by_id {
    my($todos, $id) = @_;
    return grep { $_->{id} eq $id } @{$todos};
}

run {
    my $block = shift;
    my $cb  = WWW::Cybozu::Office6->new(debug => $ENV{DEBUG}||0);

    my %param;
    for my $attr (@ATTRS) {
        $param{$attr} = $block->$attr if $block->$attr;
    }

    $param{name} = delete $param{todo_name};

    if ($param{limit_date}) {
        $param{limit_date} = ((localtime())[5]+1900).'-'.$param{limit_date};
    }

    my($ret, $id, $todo, $todos);
    ### create
    $ret = $cb->todo->create(%param);
    ok($ret, "create");
    $id = $ret;
    warn $id if $ENV{DEBUG};

    ### retrieve
    $todos = $cb->todo->retrieve();
    ok($todos, "retrieve");

    $todo = find_by_id($todos, $id);
    ok($todo, "retrieve found");

    ### delete
    $ret = $cb->todo->delete(id => $id);
    ok($ret, "delete");

    ### retrieve after delete
    $todos = $cb->todo->retrieve();
    ok($todos, "retrieve#2");
    p $todos if $ENV{DEBUG};

    $todo = find_by_id($todos, $id);
    ok(!$todo, "retrieve#2 not found");
}

__END__
=== only todo_name
--- todo_name: あれをやる

=== full attr
--- todo_name: 属性全部入り
--- category: test
--- limit_date: 10-01
--- priority: 3

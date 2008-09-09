#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Carp;

use open IO => ':locale';
use POSIX qw(strftime);
use YAML;
use FindBin;
use lib ("$FindBin::Bin/../lib");
use WWW::Cybozu::Office6;

sub p(@) {
    print YAML::Dump(\@_);
}
my $PROG     = substr($0, rindex($0, '/')+1);

my $cb  = WWW::Cybozu::Office6->new;

my $date = shift;
$date = strftime "%Y-%m-%d", localtime unless $date;
### $date
$date =~ m{^\d{4}[/.-]?\d{1,2}[/.-]?\d{1,2}$} or do {
    croak <<USAGE
[usage]
  $PROG [YYYY-MM-DD]
USAGE
};

my $res = $cb->schedule->retrieve(date=>$date);
p $res;

exit;

__END__

# for Emacsen
# Local Variables:
# indent-tabs-mode: nil
# coding: utf-8
# End:

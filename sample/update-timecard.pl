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
use Date::Parse;

sub p(@) {
    print YAML::Dump(\@_);
}
my $PROG   = substr($0, rindex($0, '/')+1);
my $MYNAME = getlogin() || getpwuid($<) || $ENV{USER} || croak "cannot determine your username";
### $MYNAME

my $cb  = WWW::Cybozu::Office6->new;

my $datasource = shift or do {
    croak <<USAGE
[usage]
  $PROG datasource
[example]
    $PROG /var/log/wtmp
USAGE
};
### $datasource

my @timecards = read_datasource($datasource);
#my @timecards = read_datasource_test($datasource);

for my $tc (@timecards) {
    printf "%s\n", $tc->{date};
    my $res = $cb->timecard->update(%{ $tc })
        or carp "failed to update: ".$tc->{date};
}

exit;

sub read_datasource {
    my($wtmp) = @_;

    croak "cannor read: $wtmp" unless -r $wtmp;
    my @last = grep {/^${MYNAME}\s+tty/} qx{last -f $wtmp};
    my $this_year = (localtime)[5]+1900;

    my @timecards;
    for (@last) {
        my($user, $tty, $wod, $mon, $day, $in, undef, $out) = split /\s+/;
        my $_date = "$day $mon $this_year 00:00";
        ### $_date
        my $date = strftime "%Y-%m-%d", (strptime($_date))[0..5];
        ### $date

        next unless ($in =~ /^\d\d:\d\d/ && $out =~ /^\d\d:\d\d/);

        push @timecards, { date => $date,
                           in => $in, out => $out,
                       };
    }
    ### @timecards

    return @timecards;
}

sub read_datasource_test {
    return (
        { date => '2008-9-1',
          in   => '10:00',
          out  => '23:33',
      },
        { date => '2008-9-2',
          in   => '11:00',
          out  => '22:33',
      },
       );
}

__END__

# for Emacsen
# Local Variables:
# indent-tabs-mode: nil
# coding: utf-8
# End:

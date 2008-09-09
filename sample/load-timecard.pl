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

if ($ARGV[0] && $ARGV[0] =~ /^--?h/) {
    croak <<USAGE
[usage]
  $PROG
[example]
    cat <<EOTIMECARD | $PROG
2008/9/1 10:00 18:00
9/2      10:05 18:10
2008-9-3 10:00 18:00
9-4      10:05 18:10
EOTIMECARD
USAGE
};

my $cb  = WWW::Cybozu::Office6->new;
my @timecards = read_datasource();

for my $tc (@timecards) {
    printf "%s %s %s\n", $tc->{date}, $tc->{in}, $tc->{out};
    my $res = $cb->timecard->update(%{ $tc })
        or carp "failed to update: ".$tc->{date};
}

exit;

sub read_datasource {

    my @data = <>;
    my $this_year = (localtime)[5]+1900;

    my @timecards;
    for (@data) {
        my($date, $in, $out) = split /\s+/;
        next unless $date;

        $date = $this_year.'-'.$date unless $date =~ /^20\d\d/; # 2100 problem :D
        ### $date
        my ($year,$mon,$day) = ($date =~ m{(\d{4})[./-]?(\d{1,2})[./-]?(\d{1,2})})
            or do {
                carp "invalid date format. so skip this: $date";
                next;
            };
        my $ymd = sprintf "%04d-%02d-%02d", $year, $mon, $day;
        ### $ymd

        unless ($in =~ /^\d\d:\d\d/ && $out =~ /^\d\d:\d\d/) {
            carp "invalid time format. so skip this: $in - $out";
            next;
        }

        push @timecards, { date => $ymd,
                           in => $in, out => $out,
                       };
    }
    ### @timecards

    return @timecards;
}

__END__

# for Emacsen
# Local Variables:
# indent-tabs-mode: nil
# coding: utf-8
# End:

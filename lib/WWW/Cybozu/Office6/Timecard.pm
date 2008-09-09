package WWW::Cybozu::Office6::Timecard;

use strict;
use warnings;
use utf8;
use Carp;

use UNIVERSAL::require;
BEGIN { WWW::Cybozu::Office6::Util->use && eval &WWW::Cybozu::Office6::Util::_load_smart_comments; }
use Web::Scraper;

our $VERSION = '0.01_1';

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    %{ $self } = @_;

    return $self;
}

sub update {
    my($self, %param) = @_;

    croak "missing param: date" unless $param{date};

    $param{date} = _normalize_ymd($param{date});
    my $date = _dotize_ymd($param{date});
    ### $date

    my $url = sprintf($self->{base_url}.'?page=TimeCardModify&Date=da.%s',
                      $date,
                     );
    ### $url

    my %form = (
        'PIn.Hour'    => '',
        'PIn.Minute'  => '',
        'POut.Hour'   => '',
        'POut.Minute' => '',
        #
        'Out.Hour'    => '',
        'Out.Minute'  => '',
        'In.Hour'     => '',
        'In.Minute'   => '',
        Memo          => '',
       );

    for my $field (qw(in out)) {
        next unless $param{$field};
        my $fname = 'P'.ucfirst $field.'.';
        @form{ $fname.'Hour', $fname.'Minute' } = map int, split /:/, $param{$field};
    }
    ### \%form

    my $res;
    $res = $self->{mech}->get($url);
    if (my $errmsg = _is_error($self->{mech})) {
        croak $errmsg;
    }

    $res = $self->{mech}->submit_form(form_number => 2,
                                      button => 'submit',
                                      fields => \%form,
                                     );
    if (my $errmsg = _is_error($self->{mech})) {
        croak $errmsg;
    }

    return 1;
}

sub retrieve {
    my($self, %param) = @_;

    $param{date} = _normalize_ymd($param{date});
    my $date = _dotize_ymd($param{date} =~ /\d+-\d+-\d+/ ? $param{date} : $param{date}.'-01');
    ### $date

    my $url = sprintf($self->{base_url}.'?page=TimeCardPrint&date=da.%s',
                      $date,
                     );
    ### $url

    my $scraper = scraper {
        process 'p b', 'ym' => sub {
            if ($_[0]->as_text =~ /^\s*(\d{4})\s*年\s*(\d+)\s*月/) {
                return sprintf "%04d-%02d", $1, $2;
            } else {
                return;
            }
        };
        process 'table tr', 'timecards[]' => scraper {
            process 'td:nth-child(1)', 'date'      => 'TEXT';
            process 'td:nth-child(2)', 'in'        => 'TEXT';
            process 'td:nth-child(3)', 'out'       => 'TEXT';
            process 'td:nth-child(4)', 'go_out'    => 'TEXT';
            process 'td:nth-child(5)', 'come_back' => 'TEXT';
            process 'td:nth-child(6)', 'memo'      => 'TEXT';
        };
    };
    $scraper->user_agent($self->{mech});
    my $r = $scraper->scrape(URI->new($url));
    shift @{ $r->{timecards} } unless exists $r->{timecards}[0]{date};
    ### $r

    my $timecards = [ map {
        if ($_->{date} =~ m{^(?:\d+/)?(\d+)}) {
            $_->{date} = sprintf $r->{ym}.'-%02d', $1;
        }
        $_;
    } @{ $r->{timecards} }];

    # ugly...
    if ($param{date} =~ /^\d{4}-\d+-\d+$/) {
        for my $tc (@{ $timecards }) {
            if ($tc->{date} eq $param{date}) {
                return [ $tc ];
            }
        }
        return;
    } elsif ($param{date} =~ /^\d{4}-\d+$/) {
        return $timecards;
    } else {
        return; # huh?
    }
}

__END__

=head1 NAME

WWW::Cybozu::Office6::Timecard - manipulating Cybozu Office 6 timecard

=head1 SYNOPSIS

    use WWW::Cybozu::Office6;

    my $cb          = WWW::Cybozu::Office6->new;
    my $cb_timecard = $cb->timecard;

    $cb_timecard->update(date => '2008-9-2',
                         in   => '9:58',
                         out  => '18:02');

=head1 DESCRIPTION

Perl module for manipulating Cybozu Office 6 Timecard.

=head1 METHODS

=head2 new

    my $cb          = WWW::Cybozu::Office6->new;
    my $cb_timecard = $cb->timecard;

WWW::Cybozu::Office6 ($cb->timecard) invokes this method so you don't have to call this method.

=head2 update

  $ret = $cb_timecard->update( %param );

insert or update timecard. return true if succeed.

%param is as follows.

=over 4

=item date => "YYYY-MM-DD"

  YYYY-MM-DD or YYYY-M-D

=item in => "HH:MM"

=item out => "HH:MM" (optional)

=back

=head2 retrieve

  $ret = $cb_timecard->retrieve( %param );

Retrieve timecards. Returns array ref of timecard hash.

  [ $tc_1, $tc_2, ... ]
  
  $tc_X = {
    date      => "YYYY-MM-DD",
    in        => "HH:MM",
    out       => "HH:MM",
    go_out    => "HH:MM",
    come_back => "HH:MM",
    memo      => "STRING",
  }

%param is as follows.

=over 4

=item date => "YYYY-MM-DD" or "YYYY-MM"

per day

  YYYY-MM-DD
  YYYY-M-D

per week

  YYYY-MM
  YYYY-M

=back

=head1 SEE ALSO

L<WWW::Cybozu::Office6>,
L<WWW::Cybozu::Office6::Schedule>,
L<WWW::Cybozu::Office6::Todo>,

=head1 AUTHOR

HIROSE Masaaki, C<< <hirose31@gmail.com> >>

=head1 NOTICE

THIS MODULE IS ALPHA STATUS AND DEVELOPER RELEASE.
SO WE MIGHT CHANGE OBJECT INTERFACE.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-cybozu-office6@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# for Emacsen
# Local Variables:
# indent-tabs-mode: nil
# coding: utf-8
# End:

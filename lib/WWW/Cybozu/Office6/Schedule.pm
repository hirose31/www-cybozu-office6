package WWW::Cybozu::Office6::Schedule;

use strict;
use warnings;
use utf8;
use Carp;

use UNIVERSAL::require;
BEGIN { WWW::Cybozu::Office6::Util->use && eval &WWW::Cybozu::Office6::Util::_load_smart_comments; }
use Web::Scraper;

our $VERSION = '0.01_01';

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    %{ $self } = @_;

    return $self;
}

sub create {
    my($self, %param) = @_;

    $param{date} = _normalize_ymd($param{date});
    my $date = _dotize_ymd($param{date});
    ### $date

    my $url = sprintf($self->{base_url}.'?page=ScheduleEntry&Date=da.%s',
                      $date,
                     );
    $self->{mech}->get($url);

    $param{member} ||= [ $self->{userid} ];
    my $form = $self->{'mech'}->form_name('ScheduleEntry');
    foreach my $uid (@{ $param{'member'} }) {
        HTML::Form::ListInput->new(type     => 'option',
                                   multiple => 'multiple',
                                   name     => 'sUID',
                                   value    => "$uid",
                                  )->add_to_form($form);
    }
    $form->param('sUID', $param{'member'});

    $self->{mech}->submit_form(form_name => 'ScheduleEntry',
                               button    => 'Entry',
                               fields    => {
                                   Detail => _ja($param{'title'}),
                                   Memo   => _ja($param{'memo'}),
                               },
                              );
    if (my $errmsg = _is_error($self->{mech})) {
        croak $errmsg;
    }

    return 1;
}

sub retrieve {
    my($self, %param) = @_;

    $param{date} = _normalize_ymd($param{date});
    my $date = _dotize_ymd($param{date});
    ### $date

    my $url = sprintf($self->{base_url}.'?page=ScheduleUserDay&date=da.%s',
                      $date,
                     );
    ### $url

    my $scraper = scraper {
        process 'div.overday ul li a', 'overday[]' => sub {
            my $node = shift;
            my $href = $node->attr('href');
            my($eid) = ($href =~ /sEID=([^&]+)/);
            return {
                id    => $eid,
                title => $node->as_text,
                date  => $date,
            };

        };
        process 'div.critical', 'timed[]' => sub {
            my $node = shift;
            my $href = $node->find('a')->attr('href');
            my($eid) = ($href =~ /sEID=([^&]+)/);
            return {
                id    => $eid,
                title => $node->as_text,
                date  => $date,
            };
        };
    };
    $scraper->user_agent($self->{mech});
    my $r = $scraper->scrape(URI->new($url));

    return $r;
}

sub delete {
    my($self, %param) = @_;

    unless ($param{date} && $param{id}) {
        croak "missing param: date and id";
    }

    $param{date} = _normalize_ymd($param{date});
    my $date = _dotize_ymd($param{date});
    ### $date

    my $url = sprintf($self->{base_url}.'?page=ScheduleDelete&Date=da.%s&sEID=%s',
                      $date,
                      $param{id},
                     );
    $self->{mech}->get($url);

    $self->{mech}->submit_form(form_name => 'ScheduleDelete',
                               button    => 'Yes',
                               fields    => {
                                   page      => 'ScheduleDelete',
                                   sEID      => $param{id},
                                   Date      => "da.${date}",
                                   UID       => $self->{userid},
                                   Member    => 'all', # fixme todo: to specify member id
                               },
                              );
    if (my $errmsg = _is_error($self->{mech})) {
        croak $errmsg;
    }

    return 1;
}

__END__

=head1 NAME

WWW::Cybozu::Office6::Schedule - manipulating Cybozu Office 6 schedule

=head1 SYNOPSIS

    use WWW::Cybozu::Office6;

    my $cb          = WWW::Cybozu::Office6->new;
    my $cb_schedule = $cb->schedule;

    my $schedules = $cb_schedule->retrieve(date => '2006-9-8');
    ...
    $cb_schedule->create(date  => '2006-9-8',
                         title => 'bake bread');

=head1 DESCRIPTION

Perl module for manipulating Cybozu Office 6 Schedule.

=head1 METHODS

=head2 new

    my $cb          = WWW::Cybozu::Office6->new;
    my $cb_schedule = $cb->schedule;

WWW::Cybozu::Office6 ($cb->schedule) invokes this method so you don't have to call this method.

=head2 create

  $ret = $cb_schedule->create( %param );

Add new schedule. return true if succeed.

Current version does not support adding timed schedule.

%param is as follows.

=over 4

=item date => "YYYY-MM-DD"

  YYYY-MM-DD or YYYY-M-D

=item title => "TITLE"

title of schedule.

=item memo => "MEMO" (optional)

memo

=item member => [ uid1, uid2, ... ] (optional)

UIDs of member whom share schedule with.

=back

=head2 retrieve

  $ret = $cb_schedule->retrieve( %param );

Retrieve schedules. Returns array ref of schedule hash.

  {
    overday => [ $sche_1, $sche_2, ... ],
    timed   => [ $sche_a, $sche_b, ... ],
  }
  
  $sche_X = {
    id    => "ID",
    title => "TITLE",
    date  => "YYYY-MM-DD",
  }


%param is as follows.

=over 4

=item date => "YYYY-MM-DD"

  YYYY-MM-DD or YYYY-M-D

=back

=head2 delete

  $ret = $cb_schedule->delete( %param );

Delete schedule.

%param is as follows.

=over 4

=item id => "ID"

ID of schedule.

=item date => "YYYY-MM-DD"

  YYYY-MM-DD or YYYY-M-D

=back

=head1 SEE ALSO

L<WWW::Cybozu::Office6>,
L<WWW::Cybozu::Office6::Timecard>,
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

package WWW::Cybozu::Office6;

use strict;
use warnings;
use utf8;
use Carp;

use URI;
use WWW::Mechanize;
use Config::Pit;
use UNIVERSAL::require;
BEGIN { WWW::Cybozu::Office6::Util->use && eval &WWW::Cybozu::Office6::Util::_load_smart_comments }
use WWW::Cybozu::Office6::Schedule;
use WWW::Cybozu::Office6::Todo;
use WWW::Cybozu::Office6::Timecard;

our $VERSION = '0.01_01';

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    %{ $self } = @_;

    my $pit = pit_get("cybozu6", require => {
        userid   => "user ID on Cybozu6 (digit)",
        password => "password on Cybozu6",
        base_url => "base URL of Cybozu6 (http://.../ag.cgi)",
    });
    for (keys %$pit) {
        $self->{$_} = $pit->{$_};
    }

    $self->{mech} = WWW::Mechanize->new;

    $self->login;

    return $self;
}

sub userid {
    my $self = shift;
    $self->{userid} = shift if @_;
    return $self->{userid};
}

sub login {
    my($self) = @_;

    ### login: $self->{userid}
    $self->{mech}->get( $self->{base_url} );

    my $form = $self->{mech}->form_name("LoginForm");
    HTML::Form::ListInput->new(type  => "option",
                               name  => "_ID",
                               value => $self->{userid},
                              )->add_to_form($form);

    $self->{mech}->submit_form(form_name => 'LoginForm',
                               fields => { '_ID'      => $self->{userid},
                                           'Password' => $self->{password},
                                       });
    if (my $errmsg = _is_error($self->{mech})) {
        croak $errmsg;
    }

    return 1;
}

sub schedule {
    my($self) = @_;
    return WWW::Cybozu::Office6::Schedule->new(%$self);
}

sub todo {
    my($self) = @_;
    return WWW::Cybozu::Office6::Todo->new(%$self);
}

sub timecard {
    my($self) = @_;
    return WWW::Cybozu::Office6::Timecard->new(%$self);
}

1;
__END__

=head1 NAME

WWW::Cybozu::Office6 - manipulating Cybozu Office 6

=head1 SYNOPSIS

    use WWW::Cybozu::Office6;

    my $cb = WWW::Cybozu::Office6->new;

    my $schedules = $cb->schedule->retrieve(date => '2006-9-8');
    $cb->schedule->create(date  => '2006-9-8',
                          title => 'bake bread');
    ...
    $cb->todo->create(limit_date => '2008-9-9',
                      name       => 'buy present',
                      category   => 'life');
    ...
    $cb->timecard->update(date => '2008-9-2',
                          in   => '9:58',
                          out  => '18:02');

=head1 DESCRIPTION

Perl module for manipulating Cybozu Office 6.

=head1 METHODS

=head2 new

  $cb = WWW::Cybozu::Office6->new();

constructs a new WWW::Cybozu::Office6 instance.

=head2 login

do login sequence.

=head2 userid

returns user id.

=head2 schedule

  $cb_schedule = $cb->schedule;

return WWW::Cybozu::Office6::Schedule instance.
see L<WWW::Cybozu::Office6::Schedule> for details.

=head2 todo

  $cb_todo = $cb->todo;

return WWW::Cybozu::Office6::Todo instance.
see L<WWW::Cybozu::Office6::Todo> for details.

=head2 timecard

  $cb_timecard = $cb->timecard;

return WWW::Cybozu::Office6::Timecard instance.
see L<WWW::Cybozu::Office6::Timecard> for details.

=head1 SEE ALSO

L<WWW::Cybozu::Office6::Schedule>,
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

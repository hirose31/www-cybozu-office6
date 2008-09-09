package WWW::Cybozu::Office6::Todo;

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

sub create {
    my($self, %param) = @_;

    my %limit;  # NoLimit LimitDate.Year LimitDate.Month LimitDate.Day
    if ($param{limit_date}) {
        @limit{'LimitDate.Year','LimitDate.Month','LimitDate.Day'} = map int($_), split /-/, $param{limit_date};
        $limit{NoLimit} = undef;
    } else {
        $limit{NoLimit} = 1;
    }

    my $url = $self->{base_url}.'?page=ToDoEntry&cp=dl';
    my $res;

    $res = $self->{mech}->get($url);
    if (my $errmsg = _is_error($self->{mech})) {
        croak $errmsg;
    }

    my $max_red = $self->{mech}->max_redirect(0);
    $res = $self->{mech}->submit_form(form_name => 'ToDoEntry',
                                      button => 'Entry',
                                      fields => {
                                          Category => $param{category} || '',
                                          Name     => _ja($param{name}),
                                          %limit,
                                          Priority => $param{priority} ? $param{priority}-1 : 0,
                                          Memo     => _ja($param{memo}||''),
                                      },
                                     );
    if (my $errmsg = _is_error($self->{mech})) {
        croak $errmsg;
    }
    $self->{mech}->max_redirect($max_red);

    if ($res->code == 301 || $res->code == 302) {
        if ($res->header('Location') =~ /TID=(\d+)/) {
            return $1;
        } else {
            return;
        }
    } else {
        return;
    }
}

sub retrieve {
    my($self) = @_;

    my $url = $self->{base_url}.'?page=ToDoIndex';

    my $scraper = scraper {
        process 'table.dataList tr', 'todos[]' => scraper {
            process 'input',           'id'         => '@value';
            process 'td a',            'name'       => 'TEXT';
            process 'td:nth-child(3)', 'category'   => 'TEXT',
            process 'td:nth-child(4)', 'limit_date' => sub {
                    my $node = shift;
                    my @dt   = split m{/}, $node->as_text;
                    my $ndt  = scalar @dt;
                    if ($ndt == 3) {
                        return sprintf "%04d-%02d-%02d", @dt;
                    } elsif ($ndt == 2) {
                        return sprintf "%04d-%02d-%02d", (localtime)[5]+1900,@dt;
                    } else {
                        return;
                    }
                };
            process 'td:nth-child(5)', 'priority'   => sub {
                return @{ [$_[0]->as_text =~ /★/g] }+0;
            };
        };
        result 'todos';
    };
    $scraper->user_agent($self->{mech});
    my $r = $scraper->scrape(URI->new($url));
    shift @{ $r } unless exists $r->[0]{id};

    return $r;
}

sub delete {
    my($self, %param) = @_;

    croak "missing param: id" unless $param{id};
    ### id: $param{id}

    my $url = sprintf($self->{base_url}.'?page=ToDoDelete&dTID=%s',
                      $param{id}
                     );
    ### $url
    my $res;

    $res = $self->{mech}->get($url) or croak $!;
    #### code: $res->code, $res->as_string
    if (my $errmsg = _is_error($self->{mech})) {
        croak $errmsg;
    }

    $res = $self->{mech}->submit_form(form_number => 2,
                                      button    => 'Yes',
                                      fields    => {
                                          Page => 'ToDoDelete',
                                          CP   => '',
                                          SP   => '',
                                          CID  => '',
                                          ID   => $param{id},
                                      },
                                     );
    #### code: $res->code, $res->as_string
    if (my $errmsg = _is_error($self->{mech})) {
        croak $errmsg;
    }

    return 1;
}

__END__

=head1 NAME

WWW::Cybozu::Office6::Todo - manipulating Cybozu Office 6 todo

=head1 SYNOPSIS

    use WWW::Cybozu::Office6;

    my $cb      = WWW::Cybozu::Office6->new;
    my $cb_todo = $cb->todo;

    $cb_todo->create(limit_date => '2008-9-9',
                     name       => 'buy present',
                     category   => 'life');

=head1 DESCRIPTION

Perl module for manipulating Cybozu Office 6 Todo.

=head1 METHODS

=head2 new

    my $cb      = WWW::Cybozu::Office6->new;
    my $cb_todo = $cb->todo;

WWW::Cybozu::Office6 ($cb->todo) invokes this method so you don't have to call this method.

=head2 create

  my $todo_id = $cb_todo->create( %param );

Add new todo. return id of todo if succeed.

%param is as follows.

=over 4

=item name => "TITLE",

short description of todo.

=item limit_date => "YYYY-MM-DD" (optional)

  YYYY-MM-DD or YYYY-M-D

due date.

=item category (optional)

name of category.

=item priority (optional)

number of priority between 1 and 3. 3 is highest priority.

=item memo (optional)

memo

=back

=head2 retrieve

  $ret = $cb_todo->retrieve( %param );

Retrieve todos. Returns array ref of todo hash.

  [ $todo_1, $todo_2, ... ]
  
  $todo_X = {
    id         => "ID",
    name       => "TITLE",
    category   => "name of category",
    limit_date => "YYYY-MM-DD",
    priority   => n, # 1 .. 3
  }

%param is as follows.

=over 4

=item no parameter

=back

=head2 delete

  $ret = $cb_todo->delete( %param );

Delete todo. return true if succeed.

%param is as follows.

=over 4

=item id => "ID"

ID of todo.

=item date => "YYYY-MM-DD"

  YYYY-MM-DD or YYYY-M-D

=back

=head1 SEE ALSO

L<WWW::Cybozu::Office6>,
L<WWW::Cybozu::Office6::Schedule>,
L<WWW::Cybozu::Office6::Timecard>,

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

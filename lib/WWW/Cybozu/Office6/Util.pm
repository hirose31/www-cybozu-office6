package WWW::Cybozu::Office6::Util;

use strict;
use warnings;
use utf8;
use Carp;

use Encode ();
use Exporter qw(import);
our @EXPORT = qw(_dotize_ymd _normalize_ymd _is_error _ja);

our $VERSION = '0.01_1';

sub _load_smart_comments {
    return <<'END_ENABLE';
my $debug_flag = $ENV{SMART_COMMENTS} || $ENV{SMART_COMMENT} || $ENV{SMART_DEBUG} || $ENV{SC};
if ($debug_flag) {
    my @p = map { '#'x$_ } ($debug_flag =~ /([345])\s*/g);
    use UNIVERSAL::require;
    Smart::Comments->use(@p);
}
END_ENABLE
}

# change YYYY-MM-DD or YYYY/MM/DD into YYYY.MM.DD
sub _dotize_ymd {
    my($ymd) = @_;

    if ($ymd =~ m{^(\d{4})[/-]?(\d{1,2})[/-]?(\d{1,2})$}) {
        return join '.', $1, $2, $3;
    } else {
        return $ymd;
    }
}

# YYYY-M-D -> YYYY-MM-DD
# YYYY-M   -> YYYY-MM
sub _normalize_ymd {
    my($ymd) = @_;

    if ($ymd =~ m{^(\d{4})[./-]?(\d{1,2})[./-]?(\d{1,2})?$}) {
        if ($3) {
            return sprintf "%04d-%02d-%02d", $1, $2, $3;
        } else {
            return sprintf "%04d-%02d", $1, $2;
        }
    } else {
        return;
    }
}

sub _is_error {
    my($mech) = @_;
    my $str = Encode::decode('shift_jis', $mech->title);
    return $str =~ /エラー\s*(\d+)/ ? $1 : ();
}

sub _ja {
    my($str) = @_;
    Encode::encode('shift_jis', $str);
}

__END__

=head1 NAME

WWW::Cybozu::Office6::Util - convenience functions

=head1 SYNOPSIS

    use WWW::Cybozu::Office6::Util;

=head1 DESCRIPTION

Convenience functions very DASAI.

=head1 METHODS

=head2 _load_smart_comments

Smart::Comments を実行時にロードするための小細工。

ロードする側では BEGIN ブロックでこの関数を呼ぶ。

  BEGIN {
    WWW::Cybozu::Office6::Util->use
      && eval &WWW::Cybozu::Office6::Util::_load_smart_comments;
  }

で、実行時に以下の環境変数のどれかがセットされていれば Smart::Comments
が有効になる。

  SMART_COMMENTS
  SMART_COMMENT
  SMART_DEBUG
  SC

もし、環境変数の値に 3か4か5が含まれている場合はレベルの指定となる。

  env SC='34' foo.pl

は

  use Smart::Comments '###', '####';

となる。

=head2 _normalize_ymd($date)

日付をゼロ詰めしたのを返す。例えば、"2008-1-2" を渡すと "2008-01-02" が返ってくる。

=head2 _dotize_ymd($date)

YYYY-MM-DDもしくはYYYY/MM/DD形式の日付文字列を受け取り、ドット区切りの
日付文字列に変換して返す。QUERY_STRINGのパラメータで使う用。

=head2 _is_error

Cybozu Office の世界のエラー判定をする。

具体的には、HTMLのtitleに「エラー」という文字列が含まれているかどうかで判定する。

=head2 _ja

Cybozu が受け付ける文字コードに変換する。ダサイ。

=head1 SEE ALSO

L<WWW::Cybozu::Office6>,
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

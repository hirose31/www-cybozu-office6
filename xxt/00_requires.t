use Test::More tests => 1+3;

diag( "You must set login account 'cybozu6' with Config::Pit" );

BEGIN {
    use_ok('Config::Pit');
}

my $pit = pit_get("cybozu6", require => {
    userid   => "user ID on Cybozu6",
    password => "password on Cybozu6",
    base_url => "base URL of Cybozu6",
});

for my $attr (qw(userid password base_url)) {
    ok($pit->{$attr}, $attr);
}

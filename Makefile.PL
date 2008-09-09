use inc::Module::Install;

name        'WWW-Cybozu-Office6';
all_from    'lib/WWW/Cybozu/Office6.pm';

requires 'UNIVERSAL::require' => 0;
requires 'WWW::Mechanize'     => 0;
requires 'Web::Scraper'       => 0;
requires 'Config::Pit'        => 0;
requires 'URI'                => 0;

test_requires 'Test::More' => 0;

use_test_base;
auto_install;
WriteAll;


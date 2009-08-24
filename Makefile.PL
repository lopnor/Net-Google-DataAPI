use inc::Module::Install;
name 'Net-Google-DataAPI';
all_from 'lib/Net/Google/DataAPI.pm';

requires 'Carp';
requires 'XML::Atom';
requires 'Net::Google::AuthSub';
requires 'Crypt::SSLeay';
requires 'LWP::UserAgent';
requires 'URI';
requires 'Moose' => 0.34;
requires 'Lingua::EN::Inflect::Number';

tests_recursive;
author_tests 'xt';

build_requires 'Test::More' => '0.88';
build_requires 'Test::MockObject';
build_requires 'Test::MockModule';
build_requires 'Test::Exception';

auto_include;
WriteAll;

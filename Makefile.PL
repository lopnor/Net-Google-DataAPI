use inc::Module::Install;
name 'Net-Google-DataAPI';
all_from 'lib/Net/Google/DataAPI.pm';

requires 'Carp';
requires 'XML::Atom';
requires 'Net::Google::AuthSub';
requires 'Crypt::SSLeay';
requires 'Digest::SHA1';
requires 'Net::OAuth';
requires 'LWP::UserAgent';
requires 'URI';
requires 'Lingua::EN::Inflect::Number';
requires 'namespace::autoclean';
requires_any_moose(
    moose => '0.56',
    mouse => '0.40',
);

tests_recursive;
author_tests 'xt';

build_requires 'Test::More' => '0.88';
build_requires 'Test::Warn';
build_requires 'UNIVERSAL::isa';
build_requires 'UNIVERSAL::can';
build_requires 'Test::MockObject';
build_requires 'Test::MockModule';
build_requires 'Test::Exception';

auto_set_repository;
auto_include;
WriteAll;

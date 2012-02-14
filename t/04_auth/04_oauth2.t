use strict;
use warnings;
use Test::More;
use Term::Prompt;
use Net::Google::Spreadsheets;

BEGIN {
    use_ok 'Net::Google::DataAPI::Auth::OAuth2';
}

done_testing;

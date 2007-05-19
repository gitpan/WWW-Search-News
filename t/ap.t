
# $Id: ap.t,v 1.10 2007/05/19 22:16:50 Daddy Exp $

use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::AP') };

&tm_new_engine('AP');
my $iDebug = 0;
my $iDump = 0;

# This test returns no results (but we should not get an HTTP error):
diag("Sending 0-page AP query to washingtonpost.com...");
&tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
# goto MULTI_RESULT;
TODO:
  {
  local $TODO = q{too hard to find a reliable one-page query};
  # This query sometimes (rarely) returns 1 page of results:
  diag("Sending 1-page AP query to washingtonpost.com...");
  $iDebug = 0;
  $iDump = 0;
  &tm_run_test('normal', 'turtle', 1, 9, $iDebug, $iDump);
  } # end of TODO block
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got any results');
foreach my $oResult (@ao)
  {
  like($oResult->url, qr{\Ahttp://},
       'result URL is http');
  cmp_ok($oResult->title, 'ne', '',
         'result Title is not empty');
  cmp_ok($oResult->description, 'ne', '',
         'result description is not empty');
  cmp_ok($oResult->change_date, 'ne', '',
         'result change_date is not empty');
  like($oResult->source, qr'AP', 'result source is AP');
  } # foreach
# goto MULTI_RESULT;

MULTI_RESULT:
;
TODO:
  {
  # local $TODO = q{www.washingtonpost.com's 'Next' button is broken};
  diag("Sending multi-page AP query to washingtonpost.com...");
  $iDebug = 0;
  $iDump = 0;
  # This query returns MANY pages of results:
  &tm_run_test('normal', 'Japan', 11, undef, $iDebug, $iDump);
  } # end of TODO block

exit 0;

__END__


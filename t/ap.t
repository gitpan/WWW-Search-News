
# $Id: ap.t,v 1.11 2007/12/06 02:11:08 Daddy Exp $

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
  $TODO = q{too hard to find a reliable one-page query};
  # This query sometimes (rarely) returns 1 page of results:
  diag("Sending 1-page AP query to washingtonpost.com...");
  $iDebug = 0;
  $iDump = 0;
  &tm_run_test('normal', 'turtle', 1, 9, $iDebug, $iDump);
  $TODO = '';
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
diag("Sending multi-page AP query to washingtonpost.com...");
$iDebug = 0;
$iDump = 0;
# This query returns MANY pages of results:
&tm_run_test('normal', 'Japan', 11, undef, $iDebug, $iDump);

exit 0;

__END__


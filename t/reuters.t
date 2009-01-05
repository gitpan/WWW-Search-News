
# $Id: reuters.t,v 1.9 2009/01/05 03:33:30 Martin Exp $

use blib;
use Test::More no_plan;

use WWW::Search::Test;
BEGIN
  {
  use_ok('WWW::Search::Reuters');
  }

tm_new_engine('Reuters');
my $iDebug = 0;
my $iDump = 0;
# goto TEST_NOW;

# This test returns no results (but we should not get an HTTP error):
diag("Sending 0-page Reuters query to washingtonpost.com...");
tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
# goto MULTI_RESULT;
TEST_NOW:
pass;
ONE_PAGE:
pass;
TODO:
  {
  $TODO = q{too hard to find a reliable one-page query};
  # This query sometimes (if we're really lucky) returns 1 page of
  # results:
  diag("Sending 1-page Reuters query to washingtonpost.com...");
  $iDebug = 0;
  $iDump = 0;
  tm_run_test('normal', 'frog', 1, 9, $iDebug, $iDump);
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
    is($oResult->source, 'Reuters', 'source is Reuters');
    } # foreach
  $TODO = '';
  } # end of TODO block
# goto SKIP_MULTI_RESULT;

MULTI_RESULT:
pass;
TODO:
  {
  # local $TODO = q{www.washingtonpost.com's 'Next' button is broken};
  diag("Sending multi-page Reuters query to washingtonpost.com...");
  $iDebug = 0;
  $iDump = 0;
  # This query returns MANY pages of results:
  tm_run_test('normal', 'Japan', 11, undef, $iDebug, $iDump);
  } # end of TODO block
SKIP_MULTI_RESULT:
pass;
exit 0;

__END__


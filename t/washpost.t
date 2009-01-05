
# $Id: washpost.t,v 1.15 2009/01/05 03:33:30 Martin Exp $

use blib;
use Data::Dumper;
use Test::More no_plan;
use WWW::Search::Test;

BEGIN
  {
  use_ok('WWW::Search::WashPost');
  }

tm_new_engine('WashPost');
my $iDebug = 0;
my $iDump = 0;
# goto DEBUG_NOW;
# goto DETAIL_RESULTS; # for debugging

# This test returns no results (but we should not get an HTTP error):
diag("Sending 0-page query to washingtonpost.com...");
tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
# goto MULTI_RESULT;
DEBUG_NOW:
pass;
DETAIL_RESULTS:
pass;
TODO:
  {
  $TODO = q{too hard to find a reliable one-page query};
  diag("Sending 1-page query to washingtonpost.com...");
  $iDump = 0;
  $iDebug = 0;
  # This query sometimes returns 1 page of results:
  tm_run_test('normal', 'delle', 1, 9, $iDebug, $iDump);
  $TODO = '';
  } # end of TODO block
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got any results');
foreach my $oResult (@ao)
  {
  # print STDERR Dumper($oResult);
  like($oResult->url, qr{\Ahttp://},
       'result URL is http');
  cmp_ok($oResult->title, 'ne', '',
         'result Title is not empty');
  cmp_ok($oResult->description, 'ne', '',
         'result description is not empty');
  cmp_ok($oResult->change_date, 'ne', '',
         'result change_date is not empty');
  if (0)
    {
    # Some articles do not have the writer's name in the search results:
    cmp_ok($oResult->seller, 'ne', '',
           'result seller is not empty');
    } # if
  cmp_ok($oResult->location, 'ne', '',
         'result location is not empty');
  like($oResult->source,
       qr{(?i:POST|EDITION)},
       'source is Post');
  } # foreach
# goto ALL_DONE;

MULTI_RESULT:
diag("Sending multi-page query to washingtonpost.com...");
$iDump = 0;
$iDebug = 0;
# This query usually returns many of pages of results:
tm_run_test('normal', 'Bush', 21, undef, $iDebug, $iDump);
SKIP_MULTI_RESULT:
pass;
ALL_DONE:
pass('all done');
exit 0;

__END__


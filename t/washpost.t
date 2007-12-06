use blib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::WashPost') };

&tm_new_engine('WashPost');
my $iDebug = 0;
my $iDump = 0;
# goto DETAIL_RESULTS; # for debugging

# This test returns no results (but we should not get an HTTP error):
diag("Sending 0-page query to washingtonpost.com...");
&tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
# goto MULTI_RESULT;
DETAIL_RESULTS:
;
TODO:
  {
  local $TODO = q{too hard to find a reliable one-page query};
  diag("Sending 1-page query to washingtonpost.com...");
  $iDebug = 0;
  # This query usually returns 1 page of results:
  &tm_run_test('normal', '"sea turtle"', 1, 9, $iDebug);
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
  like($oResult->source,
       qr{(?i:POST|EDITION)},
       'source is Post');
  } # foreach

MULTI_RESULT:
diag("Sending multi-page query to washingtonpost.com...");
$iDebug = 0;
# This query usually returns many of pages of results:
tm_run_test('normal', 'Bush', 21, undef, $iDebug);
SKIP_MULTI_RESULT:
;
exit 0;

__END__


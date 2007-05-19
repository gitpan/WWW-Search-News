use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Reuters') };

&my_engine('Reuters');
my $iDebug = 0;
my $iDump = 0;
# goto TEST_NOW;

# This test returns no results (but we should not get an HTTP error):
diag("Sending 0-page Reuters query to washingtonpost.com...");
&my_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
# goto MULTI_RESULT;
TEST_NOW:
;
TODO:
  {
  local $TODO = q{too hard to find a reliable one-page query};
  # This query sometimes (rarely) returns 1 page of results:
  diag("Sending 1-page Reuters query to washingtonpost.com...");
  $iDebug = 0;
  &my_test('normal', 'crane', 1, 9, $iDebug);
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
  is($oResult->source, 'Reuters', 'source is Reuters');
  } # foreach
# goto MULTI_RESULT;

MULTI_RESULT:
;
TODO:
  {
  # local $TODO = q{www.washingtonpost.com's 'Next' button is broken};
  diag("Sending multi-page Reuters query to washingtonpost.com...");
  $iDebug = 0;
  $iDump = 0;
  # This query returns MANY pages of results:
  &my_test('normal', 'Japan', 11, undef, $iDebug, $iDump);
  } # end of TODO block

exit 0;

sub my_engine
  {
  my $sEngine = shift;
  $WWW::Search::Test::oSearch = new WWW::Search($sEngine);
  ok(ref($WWW::Search::Test::oSearch), "instantiate WWW::Search::$sEngine object");
  $WWW::Search::Test::oSearch->env_proxy('yes');
  } # my_engine

sub my_test
  {
  # Same arguments as WWW::Search::Test::count_results()
  my ($sType, $sQuery, $iMin, $iMax, $iDebug, $iPrintResults) = @_;
  my $iCount = &WWW::Search::Test::count_results(@_);
  is($WWW::Search::Test::oSearch->response->code, 200, 'got valid HTTP response');
  cmp_ok($iMin, '<=', $iCount, qq{lower-bound num-hits for query=$sQuery}) if defined $iMin;
  cmp_ok($iCount, '<=', $iMax, qq{upper-bound num-hits for query=$sQuery}) if defined $iMax;
  cmp_ok($iMin, '<=', $WWW::Search::Test::oSearch->approximate_result_count,
         qq{lower-bound approximate_result_count}) if defined $iMin;
  cmp_ok($WWW::Search::Test::oSearch->approximate_result_count, '<=', $iMax,
         qq{upper-bound approximate_result_count}) if defined $iMax;
  } # my_test

__END__


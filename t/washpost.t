use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::WashPost') };

&my_engine('WashPost');
my $iDebug = 0;
my $iDump = 0;
goto DETAIL_RESULTS; # for debugging

# This test returns no results (but we should not get an HTTP error):
diag("Sending 0-page query to washingtonpost.com...");
&my_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
# goto MULTI_RESULT;
DETAIL_RESULTS:
;
TODO:
  {
  local $TODO = q{too hard to find a reliable one-page query};
  diag("Sending 1-page query to washingtonpost.com...");
  $iDebug = 0;
  # This query usually returns 1 page of results:
  &my_test('normal', 'Star Wars', 1, 9, $iDebug);
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
  is($oResult->source, '(The Washington Post)', 'source is WashPost');
  } # foreach

MULTI_RESULT:
diag("Sending multi-page query to washingtonpost.com...");
$iDebug = 0;
# This query usually returns many of pages of results:
&my_test('normal', 'Japan', 21, undef, $iDebug);

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
  cmp_ok($iMin, '<=', $iCount, "lower-bound num-hits for query=$sQuery") if defined $iMin;
  cmp_ok($iCount, '<=', $iMax, "upper-bound num-hits for query=$sQuery") if defined $iMax;
  cmp_ok($iMin, '<=', $WWW::Search::Test::oSearch->approximate_result_count,
         qq{lower-bound approximate_result_count}) if defined $iMin;
  cmp_ok($WWW::Search::Test::oSearch->approximate_result_count, '<=', $iMax,
         qq{upper-bound approximate_result_count}) if defined $iMax;
  } # my_test

__END__

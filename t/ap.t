use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::AP') };

&my_engine('AP');
my $iDebug = 0;
my $iDump = 0;

# This test returns no results (but we should not get an HTTP error):
&my_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
# goto MULTI_RESULT;
$iDebug = 0;
# This query sometimes (rarely) returns 1 page of results:
&my_test('normal', 'java', 1, 9, $iDebug);
# goto MULTI_RESULT;
$iDebug = 0;

MULTI_RESULT:
;
TODO:
  {
  local $TODO = q{www.washingtonpost.com's 'Next' button is broken};
  $iDebug = 0;
  $iDump = 0;
  # This query returns MANY pages of results:
  &my_test('normal', 'Japan', 11, undef, $iDebug, $iDump);
  } # end of TODO block

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
  cmp_ok($iMin, '<=', $iCount, qq{lower-bound num-hits for query=$sQuery}) if defined $iMin;
  cmp_ok($iCount, '<=', $iMax, qq{upper-bound num-hits for query=$sQuery}) if defined $iMax;
  } # my_test

__END__

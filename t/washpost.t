
# $Id: washpost.t,v 1.16 2009/05/02 19:26:58 Martin Exp $

use strict;
use warnings;

use blib;
use Bit::Vector;
use Data::Dumper;
use Test::More 'no_plan';
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
  tm_run_test('normal', 'belle', 1, 9, $iDebug, $iDump);
  $TODO = '';
  } # end of TODO block
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got any results');
# We perform this many tests on each result object:
my $iTests = 7;
my $iAnyFailed = 0;
my %hash;
my $oV = new Bit::Vector($iTests);
foreach my $oResult (@ao)
  {
  $oV->Fill;
  my $iVall = $oV->to_Dec;
  # print STDERR Dumper($oResult);
  $oV->Bit_Off(0) if ! like($oResult->url, qr{\Ahttp://}, 'result URL is http');
  $oV->Bit_Off(1) if ! isnt($oResult->title, q'',
                              'result Title is not empty');
  $oV->Bit_Off(2) if ! isnt($oResult->description, q'',
                              'result description is not empty');
  $oV->Bit_Off(3) if ! isnt($oResult->change_date, q'',
                              'result change_date is not empty');
  if (0)
    {
    # Some articles do not have the writer's name in the search results:
    $oV->Bit_Off(4) if ! isnt($oResult->seller, q'',
                                'result seller is not empty');
    } # if
  $oV->Bit_Off(5) if ! isnt($oResult->location || q{}, q'',
                              'result location is not empty');
  $oV->Bit_Off(6) if ! like($oResult->source, qr{(?i:POST|EDITION)},
                            'source is Post');
  my $iV = $oV->to_Dec;
  # diag(qq{ DDD iV=$iV, iVall=$iVall});
  if ($iV < $iVall)
    {
    $hash{$iV} = $oResult;
    $iAnyFailed++;
    } # if
  } # foreach
if ($iAnyFailed)
  {
  diag(" Here are results that exemplify the failures:");
  while (my ($sKey, $sVal) = each %hash)
    {
    diag(Dumper($sVal));
    } # while
  } # if
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


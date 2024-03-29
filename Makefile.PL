
# $Id: Makefile.PL,v 1.18 2009/05/02 19:26:38 Martin Exp $

use inc::Module::Install;

all_from('lib/WWW/Search/News.pm');

test_requires('Bit::Vector');
test_requires('Test::More');
requires('URI');
# We need the version of WWW::Search that has the agent_email()
# method:
build_requires('WWW::Search' => 2.534);
# We need the version of WWW::Search::Test that exports its tm_
# functions:
test_requires('WWW::Search::Test' => 2.265);

WriteAll;

print STDERR <<'ENDNOTE';

Note: it is very likely that some tests will fail.
The news changes so rapidly,
it is impossible to keep the test cases completely up-to-date.
As long as you get more than zero results,
it is safe to install the modules.

ENDNOTE

__END__


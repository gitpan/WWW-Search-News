
# $Id: Makefile.PL,v 1.17 2008/05/06 02:17:37 Martin Exp $

use inc::Module::Install;

all_from('lib/WWW/Search/News.pm');

build_requires('Test::More');
requires('URI');
# We need the version of WWW::Search that has the agent_email()
# method:
build_requires('WWW::Search' => 2.534);
# We need the version of WWW::Search::Test that exports its tm_
# functions:
build_requires('WWW::Search::Test' => 2.265);

&WriteAll;

print STDERR <<'ENDNOTE';

Note: it is very likely that some tests will fail.
The news changes so rapidly,
it is impossible to keep the test cases completely up-to-date.
As long as you get more than zero results,
it is safe to install the modules.

ENDNOTE

__END__


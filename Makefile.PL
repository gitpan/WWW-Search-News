use inc::Module::Install;

name('WWW-Search-News');
version_from('lib/WWW/Search/News.pm');
author('Martin Thurn <mthurn@cpan.org>');
license('perl');

requires(perl => 5.004);
requires('WWW::Search::Test' => 2.22);
requires('URI');
include_deps('Test::More', 5.004);
build_requires('Test::More');

check_nmake();      # check and download nmake.exe for Win32
&Makefile->write;

print STDERR <<'ENDNOTE';

Note: it is very likely that some tests will fail.
The news changes so rapidly,
it is impossible to keep the test cases completely up-to-date.
As long as you get more than zero results,
it is safe to install the modules.

ENDNOTE

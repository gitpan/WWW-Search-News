use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME' => 'WWW::Search::News',
              'VERSION' => 1.01,
              'PREREQ_PM' => {
                              'WWW::Search::Test' => 2.16,
                              'URI' => 0,
                             },
             );

print STDERR <<END;

Note: it is very likely that some tests will fail.
The news changes so rapidly,
it is impossible to keep the test cases completely up-to-date.
As long as you get more than zero results,
it is safe to install the modules.

END

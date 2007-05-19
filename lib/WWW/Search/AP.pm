
# $Id: AP.pm,v 2.105 2007/05/19 23:49:38 Daddy Exp $

=head1 NAME

WWW::Search::AP - backend for searching AP News at www.washingtonpost.com

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('AP');
  my $sQuery = WWW::Search::escape_query("japan prime minister");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    { print $oResult->url, "\n"; }

=head1 DESCRIPTION

This class is a specialization of WWW::Search.  It handles making and
interpreting searches on AP news stories, courtesy of The Washington
Post F<http://www.washingtonpost.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 NOTES

This backend only searches news stories from the last 60 days.

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

C<WWW::Search::AP> is maintained by Martin Thurn
(mthurn@cpan.org).

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

#####################################################################

package WWW::Search::AP;

use strict;

use base 'WWW::Search::WashPost';

use vars qw( $VERSION $MAINTAINER );

$VERSION = do { my @r = (q$Revision: 2.105 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
$MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

# private
sub native_setup_search
  {
  my ($self, $sQuery, $rhOptions) = @_;
  $rhOptions->{'fa_1_sourcenavigator'} = 'AP';
  # All further work is done by our superclass, WWW::Search::WashPost:
  $self->SUPER::native_setup_search($sQuery, $rhOptions);
  } # native_setup_search

1;

__END__

http://www.washingtonpost.com/ac2/wp-dyn/NewsSearch?sa=as&sd=&ed=&sb=-1&st=turtle&blt=&fa_1_pagenavigator=&fa_1_sourcenavigator=AP&daterange=0&specificMonth=5&specificDay=18&specificYear=2007&FromRangeMonth=3&FromRangeDay=19&FromRangeYear=2007&ToRangeMonth=5&ToRangeDay=18&ToRangeYear=2007&sb2=1&x=18&y=12

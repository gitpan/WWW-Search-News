# Newsbytes.pm
# by Martin Thurn
# Copyright (C) 1996-1998 by USC/ISI
# $Id: Newsbytes.pm,v 1.1 2002/03/12 21:05:04 mthurn Exp $

=head1 NAME

WWW::Search::Newsbytes - backend for searching www.washingtonpost.com

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Newsbytes');
  my $sQuery = WWW::Search::escape_query("japan prime minister");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    { print $oResult->url, "\n"; }

=head1 DESCRIPTION

This class is a specialization of WWW::Search.  It handles making and
interpreting searches on news at The Newsbytes section of The Washington Post
F<http://www.washtech.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 NOTES

The article URLs are returned in order of decreasing score.
(But we are at the mercy of washtech.com's definition of score!)

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

C<WWW::Search::Newsbytes> is maintained by Martin Thurn
(mthurn@cpan.org).

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 VERSION HISTORY

If it is not listed here, then it was not a meaningful nor released revision.

=head2 2.01, 2002-03-12

First public release.

=cut

#####################################################################

package WWW::Search::Newsbytes;

use WWW::Search::WashTech;

use strict;
use vars qw( @ISA $VERSION $MAINTAINER );

@ISA = qw( WWW::Search::WashTech );

$VERSION = '2.01';
$MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

# private
sub native_setup_search
  {
  my ($self, $sQuery, $rhOptions) = @_;
  my $DEFAULT_HITS_PER_PAGE = 100;
  $self->{'_hits_per_page'} = $DEFAULT_HITS_PER_PAGE;
  $self->{_options} = {
                       'search_url' => 'http://www.newsbytes.com/search',
                       'NS-search-page' => 'results',
                       'NS-search-type' => 'NS-boolean-query',
                       'NS-max-records' => $self->{'_hits_per_page'},
                       'NS-sort-by' => '-Score',
                       # 'NS-sort-by' => '-StoryDate',
                       'NS-collection' => 'newsbytes1',
                       'NS-query' => $sQuery,
                       'submit' => 'Search',
                      };
  return $self->SUPER::native_setup_search($sQuery, $rhOptions);
  } # native_setup_search

1;

__END__

# WashTech.pm
# by Martin Thurn
# Copyright (C) 1996-1998 by USC/ISI
# $Id: WashTech.pm,v 1.4 2002/03/12 21:06:20 mthurn Exp $

=head1 NAME

WWW::Search::WashTech - backend for searching www.washingtonpost.com

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('WashTech');
  my $sQuery = WWW::Search::escape_query("japan prime minister");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    { print $oResult->url, "\n"; }

=head1 DESCRIPTION

This class is a specialization of WWW::Search.  It handles making and
interpreting searches on news at The WashTech section of The Washington Post
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

C<WWW::Search::WashTech> is maintained by Martin Thurn
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

package WWW::Search::WashTech;

use WWW::Search;
use WWW::SearchResult;
use URI;

use strict;
use vars qw( @ISA $VERSION $MAINTAINER );

@ISA = qw( WWW::Search );

$VERSION = '2.01';
$MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

# private
sub native_setup_search
  {
  my ($self, $native_query, $native_options_ref) = @_;

  $self->{_debug} = $native_options_ref->{'search_debug'};
  $self->{_debug} = 2 if ($native_options_ref->{'search_parse_debug'});
  $self->{_debug} ||= 0;

  my $DEFAULT_HITS_PER_PAGE = 100;
  $self->{'_hits_per_page'} = $DEFAULT_HITS_PER_PAGE;
  # $self->timeout(120);  # use this if website is slow

  # Use this if website refuses robots:
  # $self->user_agent('non-robot');
  # Use this if website mucks up page format depending on browser:
  # $self->{'agent_name'} = 'Mozilla/4.76';

  $self->{_next_to_retrieve} = 0;
  $self->{'_num_hits'} = 0;

  if (!defined($self->{_options}))
    {
    $self->{_options} = {
                         'search_url' => 'http://www.washtech.com/search',
                         'NS-search-page' => 'results',
                         'NS-search-type' => 'NS-boolean-query',
                         'NS-max-records' => $self->{'_hits_per_page'},
                         'NS-sort-by' => '-Score',
                         # 'NS-sort-by' => '-StoryDate',
                         'NS-collection' => 'washtech',
                         'NS-query' => $native_query,
                        };
    } # if
  my $options_ref = $self->{_options};
  if (defined($native_options_ref))
    {
    # Copy in new options.
    foreach (keys %$native_options_ref)
      {
      $options_ref->{$_} = $native_options_ref->{$_};
      } # foreach
    } # if

  # Finally, figure out the url.
  $self->{_next_url} = $self->{_options}{'search_url'} .'?'. $self->hash_to_cgi_string($options_ref);
  } # native_setup_search


sub parse_tree
  {
  my $self = shift;
  my $oTree = shift;
  my $hits_found = 0;

  # Look for the total hit count:
  my @aoFONT = $oTree->look_down('_tag', 'font');
 FONT_TAG:
  foreach my $oFONT (@aoFONT)
    {
    if (ref $oFONT)
      {
      my $sFONT = $oFONT->as_text;
      print STDERR " +   FONT == $sFONT\n" if 2 <= $self->{_debug};
      if ($sFONT =~ m!Search\s+found\s+([0-9,]+)\s+documents!i)
        {
        my $sCount = $1;
        # print STDERR " +     raw    count == $sCount\n" if 2 <= $self->{_debug};
        $sCount =~ s!,!!g;
        # print STDERR " +     cooked count == $sCount\n" if 2 <= $self->{_debug};
        $self->approximate_result_count($sCount);
        last FONT_TAG;
        } # if
      } # if
    } # foreach $oFONT

  # Find all the results:
  my @aoTR = $oTree->look_down('_tag', 'tr',
                               sub { defined($_[0])
                                     && ref($_[0])
                                     && defined($_[0]->attr('valign'))
                                     && ($_[0]->attr('valign') eq 'top') },
                              );
 TR_TAG:
  foreach my $oTR (@aoTR)
    {
    next TR_TAG unless ref $oTR;
    print STDERR " +   try oTR ===", $oTR->as_text, "===\n" if 2 <= $self->{_debug};
    my $oA = $oTR->look_down('_tag', 'a',
                             sub { ref $_[0] && ($_[0]->attr('href') =~ m!/news/!) },
                            );
    # Make sure we have a clickable article ref:
    next TR_TAG unless ref $oA;
    my $sURL = $oA->attr('href');
    my $sTitle = $oA->as_text;
    my $oTableSib = $oTR->right;
    my $sDesc = '';
    my $sDate = '';
    if (ref $oTableSib)
      {
      $sDesc = $oTableSib->as_text;
      if ($sDesc =~ s!\(([-\d/]+)\)\s*\Z!!)
        {
        $sDate = $1;
        } # if
      } # if

    my $hit = new WWW::SearchResult;
    $hit->add_url($sURL);
    $hit->title(&strip($sTitle));
    $hit->description(&strip($sDesc));
    $hit->change_date($sDate);
    push(@{$self->{cache}}, $hit);
    $self->{'_num_hits'}++;
    $hits_found++;
    } # foreach $oTR

  # Find the next link, if any:
  my @aoA = $oTree->look_down('_tag', 'a');
 A_TAG:
  foreach my $oA (@aoA)
    {
    next A_TAG unless ref $oA;
    print STDERR " +   try oA ===", $oA->as_HTML, "===\n" if 2 <= $self->{_debug};
    if ($oA->as_text eq 'Next')
      {
      print STDERR " +   oAnext is ===", $oA->as_HTML, "===\n" if 2 <= $self->{_debug};
      my $sURL = $oA->attr('href');
      $self->{_next_url} = URI->new_abs($sURL, $self->{'_prev_url'});
      last A_TAG;
      } # if
    } # foreach $oA

 SKIP_NEXT_LINK:

  return $hits_found;
  } # parse_tree


sub strip
  {
  my $s = shift;
  $s =~ s!\A[\s\240]+!!x;
  $s =~ s![\s\240]+\Z!!x;
  return $s;
  } # strip


sub octalize
  {
  my $s = shift;
  return sprintf "\\%.3lo" x length($s), unpack("C*", $s);
  } # octalize


1;

__END__

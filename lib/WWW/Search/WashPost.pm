# WashPost.pm
# by Martin Thurn
# Copyright (C) 1996-1998 by USC/ISI
# $Id: WashPost.pm,v 2.75 2004/06/05 23:30:10 Daddy Exp $

=head1 NAME

WWW::Search::WashPost - backend for searching www.washingtonpost.com

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('WashPost');
  my $sQuery = WWW::Search::escape_query("japan prime minister");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    { print $oResult->url, "\n"; }

=head1 DESCRIPTION

This class is a specialization of WWW::Search.  It handles making and
interpreting searches on news at The Washington Post
F<http://www.washingtonpost.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 SEE ALSO

To make new backends, see L<WWW::Search>.

=head1 CAVEATS

This backend (and all its subclasses) only searches news stories from
the last 14 days.

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

C<WWW::Search::WashPost> is maintained by Martin Thurn
(mthurn@cpan.org).

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 VERSION HISTORY

see ChangeLog

=cut

#####################################################################

package WWW::Search::WashPost;

use strict;
use vars qw( @ISA $VERSION $MAINTAINER );

@ISA = qw( WWW::Search );

$VERSION = do { my @r = (q$Revision: 2.75 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
$MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

use WWW::Search;
use WWW::SearchResult;
use URI;

sub native_setup_search
  {
  my ($self, $sQuery, $native_options_ref) = @_;

  $self->{_debug} = $native_options_ref->{'search_debug'};
  $self->{_debug} = 2 if ($native_options_ref->{'search_parse_debug'});
  $self->{_debug} ||= 0;

  # washingtonpost.com does not let us change this:
  my $DEFAULT_HITS_PER_PAGE = 10;
  $self->{'_hits_per_page'} = $DEFAULT_HITS_PER_PAGE;
  # $self->timeout(120);  # use this if website is slow

  # Use this if website refuses robots:
  $self->user_agent('non-robot');
  # Use this if website mucks up page format depending on browser:
  $self->{'agent_name'} = 'Mozilla/4.76';

  $self->{_next_to_retrieve} = 0;
  $self->{'_num_hits'} = 0;

  if (!defined($self->{_options}))
    {
    # As of 2004-05-22, URL is http://www.washingtonpost.com/ac2/wp-dyn/Search?tab=article_tab&adv=a&keywords=japan&source=APOnline
    $self->{_options} = {
                         'search_url' => 'http://www.washingtonpost.com/ac2/wp-dyn/Search',
                         'tab' => 'article_tab',
                         'keywords' => $sQuery,
                         'adv' => 'a',
                         'source' => 'washingtonpost.com',
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

sub preprocess_results_page_OFF
  {
  my $self = shift;
  my $sPage = shift;
  print STDERR $sPage if (2 < $self->{_debug});
  return $sPage;
  } # preprocess_results_page

my $WS = q{[\t\r\n\240\ ]};

sub parse_tree
  {
  my $self = shift;
  my $oTree = shift;
  my $hits_found = 0;
  # Look for the total hit count:
  my @aoFONTcount = $oTree->look_down(
                                      '_tag' => 'font',
                                      'face' => 'arial,verdana,helvetica',
                                     );
 COUNT_FONT_TAG:
  foreach my $oFONT (@aoFONTcount)
    {
    if (ref $oFONT)
      {
      my $sFONT = $oFONT->as_text;
      print STDERR " +   try FONT == $sFONT\n" if 2 <= $self->{_debug};
      if ($sFONT =~ m!\bsearch$WS+returned$WS+([0-9,]+)$WS+results!i)
        {
        my $sCount = $1;
        # print STDERR " +     raw    count == $sCount\n" if 2 <= $self->{_debug};
        $sCount =~ s!,!!g;
        # print STDERR " +     cooked count == $sCount\n" if 2 <= $self->{_debug};
        $self->approximate_result_count($sCount);
        last COUNT_FONT_TAG;
        } # if
      } # if
    } # foreach COUNT_FONT_TAG
  $oTree->objectify_text;
  # Find all the results:
  my @aoFONT = $oTree->look_down(
                                 _tag => 'font',
                                 face => 'arial,verdana',
                                 size => '-1',
                                );
 FONT_TAG:
  foreach my $oFONT (@aoFONT)
    {
    next FONT_TAG unless ref $oFONT;
    print STDERR " +   try oFONT ===", $oFONT->as_HTML, "===\n" if (2 <= $self->{_debug});
    my $oA = $oFONT->look_down('_tag', 'a',
                               # Make sure we have a clickable article ref:
                               sub { $_[0]->attr('href') =~ m!/articles/! },
                              );
    next FONT_TAG unless ref $oA;
    my $sURL = $oA->attr('href');
    $oA->deobjectify_text;
    my $sTitle = &strip($oA->as_text);
    print STDERR " +     found <A>, url=$sURL=\n" if (2 <= $self->{_debug});
    print STDERR " +              title=$sTitle=\n" if (2 <= $self->{_debug});
    my $oByline = $oFONT->right->right;
    my $sSource = '';
    if (ref $oByline)
      {
      $oByline->deobjectify_text;
      $sSource = &strip($oByline->as_text);
      print STDERR " +     found byline=$sSource=\n" if (2 <= $self->{_debug});
      } # if
    else
      {
      next FONT_TAG;
      }
    my $oDate = $oByline->right->right;
    my $sDate = '';
    if (ref $oDate)
      {
      $oDate->deobjectify_text;
      $sDate = &strip($oDate->as_text);
      print STDERR " +     found date=$sDate=\n" if (2 <= $self->{_debug});
      } # if
    else
      {
      next FONT_TAG;
      }
    my $oDesc = $oDate->right->right;
    next FONT_TAG unless ref $oDesc;
    $oDesc->deobjectify_text;
    my $sDesc = &strip($oDesc->as_text);
    my $hit = new WWW::SearchResult;
    $hit->add_url($sURL);
    $hit->title($sTitle);
    $hit->description($sDesc);
    $hit->change_date($sDate);
    $hit->source($sSource);
    push(@{$self->{cache}}, $hit);
    $self->{'_num_hits'}++;
    $hits_found++;
    } # foreach FONT_TAG

  $oTree->deobjectify_text;
  # Find the next link, if any:
  my @aoFONTnext = $oTree->look_down('_tag', 'font',
                                     color => '#CC0000',
                                     face => 'Arial,Verdana',
                                    );
 NEXT_FONT_TAG:
  foreach my $oFONTnext (@aoFONTnext)
    {
    next NEXT_FONT_TAG unless ref $oFONTnext;
    print STDERR " +   try oFONTnext ===", $oFONTnext->as_HTML, "===\n" if 2 <= $self->{_debug};
    if ($oFONTnext->as_text eq 'Next>')
      {
      print STDERR " +   oFONTnext is ===", $oFONTnext->as_HTML, "===\n" if 2 <= $self->{_debug};
      my $sURL = $oFONTnext->attr('href');
      $self->{_next_url} = URI->new_abs($sURL, $self->{'_prev_url'});
      last NEXT_FONT_TAG;
      } # if
    } # foreach NEXT_FONT_TAG

 SKIP_NEXT_LINK:
  return $hits_found;
  } # parse_tree


sub strip
  {
  my $s = shift;
  $s =~ s!\A$WS+!!x;
  $s =~ s!$WS+\Z!!x;
  return $s;
  } # strip


sub octalize
  {
  my $s = shift;
  return sprintf "\\%.3lo" x length($s), unpack("C*", $s);
  } # octalize

1;

__END__


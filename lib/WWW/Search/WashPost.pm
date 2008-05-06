
# $Id: WashPost.pm,v 2.80 2008/05/06 02:55:24 Martin Exp $

=head1 NAME

WWW::Search::WashPost - WWW::Search backend for searching www.washingtonpost.com

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

=head1 NOTES

In the resulting WWW::SearchResult objects,
the following elements will be set (in addition to the usual title, description, etc.):

=over

=item source

Something like "Post" or a certain "Edition".

=item location

The page number of the print edition, e.g. "E05".

=item category

The type of item found, either "Article" or "Photo".

=item seller

The author or photographer.

=back

=head1 SEE ALSO

To make new backends, see L<WWW::Search>.

=head1 CAVEATS

This backend (and all its subclasses) only searches news stories from
the last 14 days.
(This is a restriction on the Washington Post website that we can not avoid.)

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

Martin Thurn <mthurn@cpan.org>

=head1 LICENSE

This software is released under the same license as Perl itself.

=cut

package WWW::Search::WashPost;

use strict;

use URI;
use base 'WWW::Search';
use WWW::SearchResult;

our
$VERSION = do { my @r = (q$Revision: 2.80 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
our $MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

sub _native_setup_search
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
  # This is the result page number:
  $self->{_washpost_cp} = 1;
  if (!defined($self->{_options}))
    {
    # As of 2004-05-22, URL is http://www.washingtonpost.com/ac2/wp-dyn/Search?tab=article_tab&adv=a&keywords=japan&source=APOnline
    # As of 2007-05, full URL is http://www.washingtonpost.com/ac2/wp-dyn/NewsSearch?sa=as&sd=&ed=&sb=-1&x=0&y=0&st=treasure&blt=&fa_1_pagenavigator=&fa_1_sourcenavigator="The+Washington+Post"&daterange=0&specificMonth=5&specificDay=18&specificYear=2007&FromRangeMonth=3&FromRangeDay=19&FromRangeYear=2007&ToRangeMonth=5&ToRangeDay=18&ToRangeYear=2007&sb2=1
    # As of 2007-05, simplest URL is http://www.washingtonpost.com/ac2/wp-dyn/NewsSearch?sa=as&st=treasure&fa_1_sourcenavigator="The+Washington+Post"
    $self->{_options} = {
                         'search_url' => 'http://www.washingtonpost.com/ac2/wp-dyn/NewsSearch',
                         'sa' => 'as',
                         'st' => $sQuery,
                         'fa_1_sourcenavigator' => q'"The+Washington+Post"',
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
  } # _native_setup_search

sub _preprocess_results_page_OFF
  {
  my $self = shift;
  my $sPage = shift;
  print STDERR $sPage if (2 < $self->{_debug});
  return $sPage;
  } # _preprocess_results_page

my $WS = q{[\t\r\n\240\ ]};

sub _parse_tree
  {
  my $self = shift;
  my $oTree = shift;
  my $hits_found = 0;
  # Look for the total hit count:
  my @aoSPANcount = $oTree->look_down(
                                      _tag => 'div',
                                      class => 'redBlock',
                                     );
 COUNT_SPAN_TAG:
  foreach my $oSPAN (@aoSPANcount)
    {
    if (ref $oSPAN)
      {
      my $sSPAN = $oSPAN->as_text;
      print STDERR " +   try SPANcount == $sSPAN\n" if 2 <= $self->{_debug};
      if ($sSPAN =~ m!([0-9,]+)$WS+results!i)
        {
        my $sCount = $1;
        print STDERR " +     raw    count == $sCount\n" if 2 <= $self->{_debug};
        $sCount =~ s!,!!g;
        # print STDERR " +     cooked count == $sCount\n" if 2 <= $self->{_debug};
        $self->approximate_result_count($sCount);
        last COUNT_SPAN_TAG;
        } # if
      } # if
    } # foreach COUNT_SPAN_TAG
  # $oTree->objectify_text;

  # Find all the results:
  my @aoSPAN = $oTree->look_down(
                                 _tag => 'div',
                                 class => 'resultBlock',
                                );
 SPAN_TAG:
  foreach my $oSPAN (@aoSPAN)
    {
    next SPAN_TAG unless ref $oSPAN;
    print STDERR " +   try oSPAN ===", $oSPAN->as_HTML, "===\n" if (2 <= $self->{_debug});
    my $oDIVheadline = $oSPAN->look_down('_tag' => 'h2',
                                        );
    next SPAN_TAG unless ref $oDIVheadline;
    my $oA = $oDIVheadline->look_down('_tag' => 'a');
    next SPAN_TAG unless ref $oA;
    my $sURL = $oA->attr('href');
    my $sTitle = _strip($oA->as_text);
    print STDERR " +     found <A>, url=$sURL=\n" if (2 <= $self->{_debug});
    print STDERR " +              title=$sTitle=\n" if (2 <= $self->{_debug});
    my $hit = new WWW::SearchResult;
    $hit->add_url($sURL);
    $hit->title($sTitle);
    my $oDIVdate = $oSPAN->look_down('_tag' => 'p',
                                     class => 'kicker');
    if (ref($oDIVdate))
      {
      my $s = $oDIVdate->as_text;
      print STDERR " DDD   raw date (kicker) =$s=\n" if 2 <= $self->{_debug};
      if ($s =~ m/(.+)\ \|\ (.+)/x)
        {
        my $sType = $1;
        $hit->category($sType);
        my $sDate = $2;
        $hit->change_date($sDate);
        } # if
      } # if
    my $oDIVdesc = $oSPAN->look_down('_tag' => 'p',
                                     class => 'teaser');
    if (ref($oDIVdesc))
      {
      $hit->description($oDIVdesc->as_text);
      } # if
    my $oDIVbyline = $oSPAN->look_down('_tag' => 'p',
                                       class => 'stamp',
                                      );
    if (ref($oDIVbyline))
      {
      my $s = $oDIVbyline->as_text;
      if ($s =~ m!\((.+)\)!)
        {
        $hit->source($1);
        } # if
      if ($s =~ m/\A(.+), (\S+)/)
        {
        $hit->seller($1);
        $hit->location($2);
        }
      } # if
    push(@{$self->{cache}}, $hit);
    $self->{'_num_hits'}++;
    $hits_found++;
    } # foreach SPAN_TAG

  # The next-page link uses JavaScript to fill-in and submit the form.
  # In order to do it mechanically, we need to keep track of what page
  # we're on and put that number in cp, along with sa=np

  # Find the next link, if any:
  my $oDiv = $oTree->look_down('_tag', 'div',
                               class => 'pagination',
                              );
  goto SKIP_NEXT_LINK if (! ref $oDiv);
  my @aoAnext = $oDiv->look_down(_tag => 'a');
  my $oAnext = pop @aoAnext;
  goto SKIP_NEXT_LINK if (! ref($oAnext));
  goto SKIP_NEXT_LINK if ($oAnext->as_text ne 'Next>');
  $self->{_options}->{sa} = 'np';
  $self->{_options}->{cp} = ++$self->{_washpost_cp};
  $self->{_next_url} = $self->{_options}{'search_url'} .'?'. $self->hash_to_cgi_string($self->{_options});
 SKIP_NEXT_LINK:
  return $hits_found;
  } # _parse_tree


sub _strip
  {
  my $s = shift;
  $s =~ s!\A$WS+!!x;
  $s =~ s!$WS+\Z!!x;
  return $s;
  } # _strip


sub _octalize
  {
  my $s = shift;
  return sprintf "\\%.3lo" x length($s), unpack("C*", $s);
  } # _octalize

1;

__END__


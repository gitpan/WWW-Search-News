###############################################################
# News.pm                                       
# by Jim Smyser                                       
# Copyright (c) 1999 by Jim Smyser & USC/ISI          
# $Id: News.pm,v 2.05 2000/07/09 03:12:19 jims Exp $
# Complete copyright notice follows below.            
###############################################################

package WWW::Search::Excite::News;

=head1 NAME

WWW::Search::Excite::News - class for searching ExciteNews

=head1 SYNOPSIS

use WWW::Search;
$query = "Bob Hope"; 
$search = new WWW::Search('Excite::News');
$search->native_query(WWW::Search::escape_query($query));
$search->maximum_to_retrieve(100);
while (my $result = $search->next_result()) {

$url = $result->url;
$title = $result->title;
$desc = $result->description;
$source = $result->source;
$date = $result->index_date;

print "<a href=$url>$title</a> $source<br>$date<br>$desc<p>\n"; 
} 

or,

use WWW::Search;
$query = "Bob Hope"; 
$search = new WWW::Search('Excite::News');
$search->native_query(WWW::Search::escape_query($query));
$search->maximum_to_retrieve(100);
while (my $result = $search->next_result()) {

$raw = $result->raw;

print "$raw\n"; 
} 

=head1 DESCRIPTION

Class for searching Excite News F<http://www.excite.com>.
Excite has one of the best news bot on the web. 

Following results returned for printing are:
$result->url  url for the news article
$result->title title of the article
$result->description  will return description if any
$result->source articles news source
$result->index_date articles date
or $result->raw for all the html

This class exports no public interface; all interaction should
be done through WWW::Search objects.

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 HOW DOES IT WORK?

C<native_setup_search> is called before we do anything.
It initializes our private variables (which all begin with underscores)
and sets up a URL to the first results page in C<{_next_url}>.
 
C<native_retrieve_some> is called (from C<WWW::Search::retrieve_some>)
whenever more hits are needed.  It calls the LWP library
to fetch the page specified by C<{_next_url}>.
It parses this page, appending any search hits it finds to
C<{cache}>.  If it finds a ``next'' button in the text,
it sets C<{_next_url}> to point to the page for the next
set of results, otherwise it sets it to undef to indicate we are done.

=head1 AUTHOR

Maintained by Jim Smyser <jsmyser@bigfoot.com>

=head1 TESTING

This module adheres to the C<WWW::Search> test suite mechanism. 
See $TEST_CASES below.

=head1 CHANGES

=head2 2.04, 2000-06-25

New format changes

=head2 2.03, 2000-03-21

New format changes

=head2 2.02, 1999-10-5

Misc. formatting changes

=head2 2.01, 1999-07-13

New test mechanism

=head1 COPYRIGHT

The original parts from John Heidemann are subject to
following copyright notice:

Copyright (c) 1996-1998 University of Southern California.
All rights reserved.
                                                                
THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

#####################################################################


require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw();
@ISA = qw(WWW::Search Exporter);
$VERSION = '2.05';

$MAINTAINER = 'Jim Smyser <jsmyser@bigfoot.com>';
$TEST_CASES = <<"ENDTESTCASES";
&test('Excite::News', '$MAINTAINER', 'zero', \$bogus_query, \$TEST_EXACTLY);
&test('Excite::News', '$MAINTAINER', 'one', 'Haw'.'aii AND Alask'.'a', \$TEST_RANGE, 1,49);
&test('Excite::News', '$MAINTAINER', 'multi', 'Alaska', \$TEST_GREATER_THAN, 51);
ENDTESTCASES

use Carp ();
use WWW::Search(generic_option);
require WWW::SearchResult;

# private
sub native_setup_search
  {
  my ($self, $native_query, $native_options_ref) = @_;
  
  # Set some private variables:
  $self->{_debug} = $native_options_ref->{'search_debug'};
  $self->{_debug} = 2 if ($native_options_ref->{'search_parse_debug'});
  $self->{_debug} ||= 0;
  $self->{'_hits_per_page'} = '50';
  $self->{agent_e_mail} = 'jsmyser@bigfoot.com.com';
  $self->user_agent(0);
  $self->{'_next_to_retrieve'} = 0;
  $self->{'_num_hits'} = 0;
  if (!defined($self->{_options})) {
    $self->{_options} = {
                         'search_url' => 'http://search.excite.com/search.gw',
                         'c' => 'timely&showSummary=true',
                         'search' => $native_query,
                         'perPage' => $self->{'_hits_per_page'},
                         'start' => $self->{'_next_to_retrieve'},
                        };
    }
  my $options_ref = $self->{_options};
  if (defined($native_options_ref))
    {
    # Copy in new options.
    foreach (keys %$native_options_ref)
      {
      $options_ref->{$_} = $native_options_ref->{$_};
      } 
    } 
  # Process the options.
  my $options = '';
  foreach (keys %$options_ref)
    {
    # printf STDERR "option: $_ is " . $options_ref->{$_} . "\n";
    next if (generic_option($_));
    $options .= $_ . '=' . $options_ref->{$_} . '&';
    }
  chop $options;
  # Finally, figure out the url.
  $self->{_next_url} = $self->{_options}{'search_url'} .'?'. $options;
  } 
  
sub begin_new_hit
  {
  my($self) = shift;
  my($old_hit) = shift;
  my($old_raw) = shift;
  # Save it
  if (defined($old_hit)) {
    $old_hit->raw($old_raw) if (defined($old_raw));
    push(@{$self->{cache}}, $old_hit);
    }
  # Make a new hit.
  return (new WWW::SearchResult, '');
  }

# private
sub native_retrieve_some
  {
  my ($self) = @_;
  # Fast exit if already done:
  return undef unless defined($self->{_next_url});
  # Sleep so as to not overload the server for next page(s)
  print STDERR "***Sending request (",$self->{_next_url},")\n" if $self->{'_debug'};
  my $response = $self->http_request('GET', $self->{_next_url});
  $self->{response} = $response;
  unless ($response->is_success)
    {
    return undef;
    }
  print STDERR "***Picked up a response..\n" if $self->{'_debug'};
  $self->{'_next_url'} = undef;
  # Parse the output
  my ($HEADER, $HITS, $TITLE, $SOURCE, $DESC, $DATE, $TRAILER) = qw(HE HH TL SO DE DA TR);
  my ($raw) = '';
  my $hits_found = 0;
  my $state = $HEADER;
  my $hit;
  foreach ($self->split_lines($response->content()))
    {
    next if m/^$/;              # short circuit for blank lines
    print STDERR " *** $state ===$_===" if 2 <= $self->{'_debug'};
    
    if ($state eq $HEADER && m|web news|i) 
      {
      $state = $HITS;
      }
    elsif ($state eq $HITS && m@\<A HREF=.*?;([^"]+)\">(.*)</A>&nbsp;@i) 
      {
      ($hit, $raw) = $self->begin_new_hit($hit, $raw);
      $hit->add_url($1);
      $hit->title($2);
      $raw .= $_;
      $raw =~ s/<ul>|<li>//g;
      $raw =~ s/http:\/\/search\.excite\.com.*?;//g;
      $raw = $raw . "<br>";
      $self->{'_num_hits'}++;
      $hits_found++;
      $state = $DATE;
      }
    elsif ($state eq $DATE && m@^\<b>(First found:.*?)&nbsp;$@) 
      {
      $hit->index_date($1);
      $raw .= $_;
      $raw =  $raw . "<b>From:</b> ";
      $state = $SOURCE;
      } 
    if ($state eq $SOURCE && m@\<b>Source:</b>@i) 
      {
      $state = $SOURCE;
      } 
    if ($state eq $SOURCE && m@^(\w.+)@i) 
      {
      $hit->source($1);
      $raw .= $_;
      $raw =  $raw . "<br>";
      $state = $DESC;
      } 
    elsif ($state eq $DESC && m@^<font size=-2>(.+)</font><p>@i) 
      {
      my ($desc) = $1;
      $desc =~ s/\s+|&nbsp;/ /g if ($desc);
      $hit->description($desc) if (defined($hit));
      $raw .= $_;
      $raw =~ s/<font.*?>|&nbsp;//ig;
      $state = $HITS;
      } 
    elsif ($state eq $HITS && m|<INPUT TYPE=submit NAME=next VALUE="Next Results">|i)
      {
      print STDERR "**Going to Next Page**\n" if 2 <= $self->{'_debug'};
      ($hit, $raw) = $self->begin_new_hit($hit, $raw);
      $self->{'_next_to_retrieve'} += $self->{'_hits_per_page'};
      $self->{'_options'}{'start'} = $self->{'_next_to_retrieve'};
      my($options) = '';
      foreach (keys %{$self->{_options}})
        {
        next if (generic_option($_));
        $options .= $_ . '=' . $self->{_options}{$_} . '&';
        } # foreach
      chop $options;
      # Finally, figure out the url.
      $self->{_next_url} = $self->{_options}{'search_url'} .'?'. $options;
      $state = $TRAILER;
      }
    else 
      {
      print STDERR "**Nothing Matched**\n" if 2 <= $self->{'_debug'};
      }
      } # foreach
  if ($state ne $TRAILER)
      {
    # no other pages missed
    $self->{_next_url} = undef;
      }
      return $hits_found;
      } # native_retrieve_some
      
1;

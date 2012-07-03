package mobedac::WebPage::Analyze;

use base qw( WebPage );

use strict;
use warnings;

use FIG_Config;

1;

=pod

=head1 NAME

Home - an instance of WebPage which shows welcome information

=head1 DESCRIPTION

Display an contact page

=head1 METHODS

=over 4

=item * B<init> ()

Called when the web page is instanciated.

=cut

sub init {
  my ($self) = @_;

  $self->title('Analyze');

  return 1;
}


=pod

=item * B<output> ()

Returns the html output of the Home page.

=cut

sub output {
  my ($self) = @_;

  my $application = $self->application;
 
  my $content = "<h2>Analysis is not yet available</h2>";

  $content .= "<div style='height: 400px;'></div>";

  return $content;
}

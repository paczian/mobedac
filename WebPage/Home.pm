package mobedac::WebPage::Home;

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

  $self->title('Home');

  return 1;
}


=pod

=item * B<output> ()

Returns the html output of the Home page.

=cut

sub output {
  my ($self) = @_;

  my $application = $self->application;
 
  my $content = "";

  if ($application->session->user) {
    $content .= "<p>Having trouble? <a href='mailto:help\@mobedac.org?subject=[MoBEDAC]'>contact us</a></p>";
  }

  $content .= "<img src='./Html/outdoor.jpg' style='float: left; height: 150px;'><h2>Welcome to the MoBEDAC Home Page</h2><p style='width: 600px;'>MoBEDAC is a cooperative project funded by the Sloan Foundation bringing together the combined capabilities of Argonne, MBL, Boulder, UCRiverside <a href='?page=About'>(learn more)</a>.</p><p style='width: 600px;'>The MoBEDAC provides a data repository and bioinformatics tools for analyzing molecular sequence data and for visualizing ecological and functional similarities between microbial communities in the indoor environment and other field sites.</p>";

  $content .= "<div style='height: 50px;'></div>";

  $content .= "<h2>Browse all indoor related Metagenomes </h2><p style='width: 600px;'>You can browse the public indoor related metagenomes by following the <a href='?page=Browse'>Browse link</a> in the menubar. To search within the available metagenome metadata, you can use the <a href='?page=Search'>Search</a> option in the menubar, or enter your search into the Quicksearch box.</p>

<p style='width: 600px;'>Note that in order to upload your own metagenomes, you will need to register. To do so, click on the <a href='?page=Register'>Register</a> link on the top right of the page. The registration will be reviewed by our administrators and you will be granted access.</p>";

  $content .= "<h2>Collaborating Sites</h2><p style='width: 600px;'>
<a href='http://vamps.mbl.edu/' target=_blank>VAMPS - The Visualization and Analysis of Microbial Structures</a><br><br>
<a href='http://qiime.org' target=_blank>QIIME - Quantative Insights Into Microbial Ecology</a><br><br>
<a href='http://FungiDB.org' target=_blank>FungiDB - Fungal genomics resources</a><br><br>
<a href='http://metagenomics.anl.gov' target=_blank>MG-RAST - Metagenome Analysis Server</a><br><br></p>";

  $content .= "<h2>BE Sloan Centers</h2><p style='width: 600px;'><a href='http://www.microbe.net/' target=_blank>microBEnet 'Microbiology of the Built Environment Network'</a><br><br>

<a href='http://biobe.uoregon.edu/' target=_blank>BioBE - Biology of the Built Environment</a><br><br>

<a href='http://www.microbe.net/berkeley-indoor-microbial-ecology-research-consortium-bimerc/' target=_blank>BIMERC - Berkeley Indoor Microbial Ecology Research Consortium</a>
</p>";

  return $content;
}

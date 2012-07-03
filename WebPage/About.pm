package mobedac::WebPage::About;

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

  $self->title('About');

  return 1;
}


=pod

=item * B<output> ()

Returns the html output of the Home page.

=cut

sub output {
  my ($self) = @_;

  my $application = $self->application;
 
  my $content = "<img src='./Html/sloan_logo.png' style='float: left; margin-right: -15px; height: 100px;'><h2>About MoBEDAC</h2><p style='width: 600px; margin-bottom: 65px;'>Funded by the Alfred P. Sloan Foundation we are developing a user-friendly, open-access, web-based community resource for deposition, analysis, and comparison of community targeted gene and shotgun metagenomic sequence surveys. 
The goal is to provide users with alternative methods and graphical tools for analyzing very large data sets subjected to comparable quality control and filtering methods. 
In addition we will provide rich metadata query capabilities that enable researchers to access or download specific data sets created by molecular microbial ecologists
</p>";

  $content .= "<h2>Members</h2>
<p style='width: 600px; margin-bottom: 45px;'><img src='./Html/folker_meyer.jpg' style='float: left; margin-right: 15px; width: 100px;'><b>Folker Meyer, University of Chicago</b><br>Folker Meyer, Ph.D., is a computational biologist at Argonne National Laboratory and a senior fellow at the Computation Institute at the University of Chicago. He is also associate division director of the Institute of Genomics and Systems Biology.
<br>
He trained as a computer scientists and started to work with biologists early on in his career. It was that exposure to interesting biological problems that sparked his interest in building software systems to tackle biological problems, mostly in the field of genomics or post-genomics. In the past he has been best known for his leadership role in the development of the GenDB genome annotation system, he has also played an active role in the design and implementation of several high-performance computing platforms.
<br>
His current work focuses on the analysis of shotgun metagenomics data sets and on the MG-RAST community resource for metagenomics. Shotgun metagenomics is benefitting directly from the current advances in sequencing technology, leading to dramatic growth in the number scientists using this approach and the number and size of the data sets being produced. He also has an interest in microbial genomics and the analysis of complete microbial genomes and is a member of the RAST project.
<br>
He is a founding member of the Earthmicrobiome project (EMP). He is a member of the Genomics Standards Consortium (GSC).
<br>
<a href='http://metagenomics.anl.gov' target=_blank>MG-RAST - Metagenome Analysis Server</a>
</p>
<p style='width: 600px; margin-bottom: 45px;'><img src='./Html/mitchell_sogin.jpg' style='float: left; margin-right: 15px; width: 100px;'><b>Mitch Sogin, Marine Biological Laboratory</b><br>Mitchell Sogin, Ph.D., is an evolutionary biologist and director of the Josephine Bay Paul Center in Comparative Molecular Biology and Evolution and senior scientist with the Marine Biological Laboratory in Woods Hole, Massachusetts. His areas of expertise include chemistry, microbiology, industrial microbiology and biochemisty. He is a member of the American Society of Microbiology, Society of Protozoologists, International Society of Evolutionary Protozologists, Society for Molecular Biology and Evolution, American Association for the Advancement of Science, and American Society for Cell Biology. He has published many scholarly articles on his research.
<br>
<a href='http://vamps.mbl.edu/' target=_blank>VAMPS - The Visualization and Analysis of Microbial Structures</a>
</p>

<p style='width: 600px; margin-bottom: 45px;'><img src='./Html/robert_knight.jpg' style='float: left; margin-right: 15px; width: 100px;'><b>Rob Knight, University of Colorado Boulder</b><br>Rob Knight, Ph.D., is an evolutionary biologist and Associate Professor at the University of Colorado, Boulder. His research combines computational and experimental techniques to ask questions about the evolution of the composition of biomolecules, genomes, and communities. Dr. Knight was selected among thirteen interdisciplinary research projects on synthetic biology that were awarded by the National Academies Keck Futures Initiative. Dr. Knight was also awarded a prestigious Howard Hughes Medical Institute Early Career Scientist.
<br>
<a href='http://qiime.org' target=_blank>QIIME - Quantative Insights Into Microbial Ecology</a>
</p>
<p style='width: 600px; margin-bottom: 25px;'><img src='./Html/jason_stajich.jpg' style='float: left; margin-right: 15px; width: 100px;'><b>Jason Stajich, University of California Riverside</b><br>Jason Stajich, Ph.D., is an Assistant Professor in Biological Sciences from the University of California at Riverside, California, interested in Fungal evolutionary genomics, including the evolution of the fungal cell wall and mechanisms of gene regulation that control development in fungi. His research uses bioinformatics, computational, and comparative genomics approaches to study the evolution of fungal gene and genomes.  He also utilizes high throughput next generation sequencing approaches to study transcriptional and genome-wide differences in strains or developmental stages.
<br>
<a href='http://FungiDB.org' target=_blank>FungiDB - Fungal genomics resources</a>
</p><div style='height: 100px;'></div>";

  return $content;
}

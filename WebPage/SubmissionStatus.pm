package mobedac::WebPage::SubmissionStatus;

use strict;
use warnings;
no warnings('once');

use JSON;

use base qw( WebPage );

1;

=pod

=head1 NAME

Upload - upload files and display uploaded files to user for creation of jobs

=head1 DESCRIPTION

Page used by user to upload files and create jobs from uploaded files

=head1 METHODS

=over 4

=item * B<init> ()

Called when the web page is instanciated.

=cut

sub init {
  my $self = shift;

  $self->title("Submission status");
}

=item * B<output> ()

Returns the html output of the page.

=cut

sub output {
  my ($self) = @_;
  
  my $application = $self->application;
  my $cgi         = $application->cgi;
  my $user        = $application->session->user;
  
  unless ($user) {
    return "<p>You must be logged in to view the status of your submissions.</p><p>Please use the login box in the top right corner or return to the <a href='mobedac.cgi'>start page</a>.</p>";
  }
  
  my $vamps_status = $self->vamps_status();

  my $html = qq~<style>h3 {margin-top: 0px;}</style>
    <div style="width: 710px; margin-left: -55px;">
      <h2>Current Status of MoBeDAC Submissions</h2>
      <div class="well">
	<h3>status of VAMPS submissions</h3>
        <br>
	<p>$vamps_status</p>
      </div>
      <div class="well">
	<h3>status of MG-RAST submissions</h3>
	<p>you currently have no submissions</p>
      </div>
      <div class="well">
	<h3>status of QIIME submissions</h3>
	<p>you currently have no submissions</p>
      </div>

    </div>~;
}

sub require_javascript {
  return [ "$FIG_Config::cgi_url/Html/jquery.js",
	   "$FIG_Config::cgi_url/Html/bootstrap.min.js",
	   "$FIG_Config::cgi_url/Html/SubmissionStatus.js",
	   "$FIG_Config::cgi_url/Html/DataHandler.js" ];
}

sub require_css {
  return [ "$FIG_Config::cgi_url/Html/bootstrap-responsive.min.css",
	   "$FIG_Config::cgi_url/Html/bootstrap.min.css",
	   "$FIG_Config::cgi_url/Html/SubmissionStatus.css" ];
}

sub vamps_status {
  my ($self, $ids) = @_;

  my $upload_dir = '/homes/paczian/public/mobedac_remote/';

  my $json = new JSON;
  $json = $json->utf8();

  my $ua = LWP::UserAgent->new;
  my $response = $ua->get('http://vamps.mbl.edu/mobedac_ws/submission/')->content;
  
  my $stati = $json->decode("{".$response."}");
  
  my $status_array = [];
  foreach my $key (keys(%$stati)) {
    push(@$status_array, [ $key, "sample", $stati->{$key}->{current_status} ]);
    foreach my $sid (@{$stati->{$key}->{library_ids}}) {
      my $status_message = $stati->{$key}->{library_statuses}->{$sid}->{current_status};
      my $fn =  $upload_dir."VAMPS_".$sid;
      if ($stati->{$key}->{library_statuses}->{$sid}->{current_status} eq 'Processing is complete and data has been returned to MoBEDAC.' && -f $fn) {
	if (open(FH, "<$fn")) {
	  my $file = "";
	  while (<FH>) {
	    chomp;
	    $file .= $_;
	  }
	  close FH;
	  my $VAR1;
	  eval($file);
	  my $data = $VAR1;
	  if ($data->{analysis_links} && $data->{analysis_links}->{$sid}) {
	    $status_message = "<a href='#' onclick='document.forms.vampsform.submit();' title='VAMPS analysis page'>".$status_message."</a>";
	    my ($faction, $stuff) = $data->{analysis_links}->{$sid}->{Visualization} =~ /^(.*)\?(.*)$/;
	    my $prms = [];
	    @$prms = split /\&/, $stuff;
	    $status_message .= "&nbsp;<form action='$faction' target=_blank method='POST' name='vampsform'>";
	    foreach my $p (@$prms) {
	      my ($xx, $yy) = split /=/, $p;
	      $status_message .= "<input type='hidden' name='".$xx."' value='".$yy."'>";
	    }
	    $status_message .= "</form>";
	  } else {
	    print STDERR Dumper($data)."\n";
	  }
	} else {
	  print STDERR "Error opening file: $@ $!\n";
	}
      }
      push(@$status_array, [ $key, "library ".$sid, $status_message ]);
    }
  }

  my $status_table = "<table><tr><th>submission</th><th>partial</th><th style='padding-left: 10px;'>status</th></tr>";
  foreach my $row (@$status_array) {
    $status_table .= "<tr><td>".$row->[0]."</td><td>".$row->[1]."</td><td style='padding-left: 10px;'>".$row->[2]."</td></tr>";
  }
  $status_table .= "</table>";

  return $status_table;
}

sub TO_JSON { return { %{ shift() } }; }

package mobedac::WebPage::JobStatus;

use base qw( WebPage );

use strict;
use warnings;

use FIG_Config;

use LWP::Simple;
use LWP::UserAgent;
use HTTP::Request;
use Encode;
use URI::Escape;
use JSON;

1;

=pod

=head1 NAME

Home - an instance of WebPage which shows status of a users jobs

=head1 DESCRIPTION

Display the job stati of a user

=head1 METHODS

=over 4

=item * B<init> ()

Called when the web page is instanciated.

=cut

sub init {
  my ($self) = @_;

  $self->title('Job Status');

  $self->application->register_component('Table', 'job_table');

  return 1;
}


=pod

=item * B<output> ()

Returns the html output of the Home page.

=cut

sub output {
  my ($self) = @_;

  my $application = $self->application;
  my $user = $application->session->user;

  unless ($user) {
    return "<p style='width: 600px;'>The job status page is only available after login. Please use the login box on the top right of the screen to log in.</p>";
  }
 
  my $jobmaster  = $application->data_handle('MGRAST');
  my $all_jobs = $jobmaster->Job->get_jobs_for_user_fast($user, 'edit');
  my $sloan = $jobmaster->Jobgroup->get_objects( { name => 'Sloan' } )->[0];
  my $all_sloan_jobs = $jobmaster->JobgroupJob->get_objects( { jobgroup => $sloan });
  my $jobs = [];
  my $sloan_jobs_hash = {};
  %$sloan_jobs_hash = map { $_->{job} => 1 } @$all_sloan_jobs;
  @$jobs = map { $sloan_jobs_hash->{$_->{_id}} ? $_ : () } @$all_jobs;

  my $job_data = {};
  foreach my $job (@$jobs) {
    $job_data->{$job->{metagenome_id}} = $job->data;
  }

  my $qiime_stati = $self->get_qiime_stati($job_data);
  my $vamps_stati = $self->get_vamps_stati($job_data);

  my $data = [];
  foreach my $job (@$jobs) {
    my $jdata = $job_data->{$job->{metagenome_id};
    push(@$data, [ $job->{project_name}, $job->{name}, $job->{size}, $job->{metagenome_id}, $jdata->{submitted_to_mgrast} ? $job->{metagenome_id} : "not submitted", $jdata->{submitted_to_mgrast} ? $job->{timed_stati}->[scalar(@{$job->{timed_stati}})-1]->[1] : "not submitted"], $jdata->{submitted_to_vamps} ? $vamps_stati->{$job->{metagenome_id}}->{id} : "not submitted", $jdata->{submitted_to_vamps} ? $vamps_stati->{$job->{metagenome_id}}->{status} : "not submitted", $jdata->{submitted_to_qiime} ? $qiime_stati->{$job->{metagenome_id}}->{id} : "not submitted", $jdata->{submitted_to_qiime} ? $qiime_stati->{$job->{metagenome_id}}->{status} : "not submitted" );
  }

  my $content = "<h2>your jobs submitted to mobedac</h2>";

  if (scalar(@$data)) {
    
    my $t = $application->component('job_table');
    $t->columns([ { name => 'project' }, { name => 'job' }, { name => 'size' }, { name => 'MG-RAST ID' }, { name => 'MG-RAST status' }, { name => 'VAMPS ID' }, { name => 'VAMPS status' }, { name => 'QIIME ID' }, { name => 'QIIME status' } ]);
    $t->data($data);
    
    $content .= "<p style='width: 600px;'>The following list shows the jobs you have submitted to mobedac, along with the ids and stati in the different pipelines.</p>";
    
    $content .= $t->output;
  } else {
    $content .= "<p>You currently have no jobs submitted to mobedac.</p>";
  }

  return $content;
}

sub get_vamps_stati {
  my ($self, $jobs) = @_;

  my $job_ids = [];
  @$job_ids = map { $jobs->{$_}->{submitted_to_vamps} ? [ $jobs->{$_}->{submitted_to_vamps}, $_ ] : () } keys(%$jobs);
  
  my $content = '{"auth":"ZiBte8bV2r5Gehzi385Mzqrdb","data":['.join(",", map { $_->[0] } @$job_ids).']}';
  my $len = length($content);
  
  my $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new( 'POST', 'http://vamps.org/api.cgi/job_status', [ "Content-Type", "text/plain", "Content-Length", $len ], encode("iso-8859-1", $content) );
  
  my $response = $ua->request($req)->as_string;
  my $json = new JSON;
  my $stati = $json->decode($response);
  my $retval = {};
  for (my $i=0; $i<scalar(@$stati); $i++) {
    $retval->{$job_ids->[$i]->[1]} = $stati->[$i];
  }

  return $retval;
}

sub get_qiime_stati {
  my ($self, $jobs) = @_;

  my $job_ids = [];
  @$job_ids = map { $jobs->{$_}->{submitted_to_qiime} ? [ $jobs->{$_}->{submitted_to_qiime}, $_ ] : () } keys(%$jobs);
  
  my $content = '{"auth":"ZiBte8bV2r5Gehzi385Mzqrdb","data":['.join(",", map { $_->[0] } @$job_ids).']}';
  my $len = length($content);
  
  my $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new( 'POST', 'http://qiime.org/api.cgi/job_status', [ "Content-Type", "text/plain", "Content-Length", $len ], encode("iso-8859-1", $content) );
  
  my $response = $ua->request($req)->as_string;
  my $json = new JSON;
  my $stati = $json->decode($response);
  my $retval = {};
  for (my $i=0; $i<scalar(@$stati); $i++) {
    $retval->{$job_ids->[$i]->[1]} = $stati->[$i];
  }

  return $retval;
}

sub TO_JSON { return { %{ shift() } }; }

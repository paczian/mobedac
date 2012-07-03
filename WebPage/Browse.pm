package mobedac::WebPage::Browse;

use base qw( WebPage );

use strict;
use warnings;

use WebConfig;
use WebComponent::WebGD;
use GD;
use Data::Dumper;

use MGRAST::MGRAST qw( :DEFAULT );
use MGRAST::MetagenomeAnalysis2;
use MGRAST::Metadata;

1;

=pod

=head1 NAME

MetagenomeSelect - an instance of WebPage which lets the user select a metagenome

=head1 DESCRIPTION

Display an metagenome select box

=head1 METHODS

=over 4

=item * B<init> ()

Called when the web page is instanciated.

=cut

sub init {
  my ($self) = @_;

  $self->title("Browse Metagenomes");
  $self->{icon} = "<img src='./Html/mgrast_globe.png' style='width: 20px; height: 20px; padding-right: 5px; position: relative; top: -3px;'>";

  # register components
  $self->application->register_component('Ajax', 'ajax');
  $self->application->register_component('Hover', 'help');
  $self->application->register_component('Table', 'all_metagenomes');
  $self->application->register_component('Table', 'user_complete');
  $self->application->register_component('Table', 'user_in_progess');
  $self->application->register_component('Table', 'user_shared');
  $self->application->register_component('Table', 'collection_table');
  $self->application->register_component('Table', 'collection_table_detail');
  $self->application->register_component('Table', 'private_projects_table');
  return 1;
}


=pod

=item * B<output> ()

Returns the html output of the MetagenomeSelect page.

=cut

sub output {
  my ($self) = @_;
  
  my $application = $self->application;
  my $dbmaster = $application->dbmaster;
  my $user = $application->session->user;
  my $cgi  = $application->cgi;
  
  # check for MGRAST
  my $html = "";
  my $mgrast = $self->application->data_handle('MGRAST');
  unless ($mgrast) {
    $html .= "<h2>The mobedac is currently offline. We apologize for the inconvenience. Please try again later.</h2>";
    return $html;
  }
  $self->{mgrast} = $mgrast;
  
  my $projects = $mgrast->Project->get_objects();
  my $project_hash = {};
  %$project_hash = map { $_->{name} => $_ } @$projects;
  
  my $all_data_table = $mgrast->Job->fetch_browsepage_viewable($user);
  my $genome_id2job_id = {};
  my $genome_id2jobname = {};
  my $genome_id2project = {};
  my $genome_id2env = {};

  my $data = {};
  my $envs = {};
  my $pis = {};

  my $sloan_group = $mgrast->Jobgroup->get_objects( { name => 'Sloan' } )->[0];
  my $sloan_jgjobs = $mgrast->JobgroupJob->get_objects({ jobgroup => $sloan_group });
  my $sloan_jobs = {};
  %$sloan_jobs = map { $_->job->{metagenome_id} => 1 } @$sloan_jgjobs;
  
  my $data_table = [];
  foreach my $row (@$all_data_table) {
    next unless ($sloan_jobs->{$row->{'metagenome_id'}});
    push(@$data_table, $row);
    $genome_id2job_id->{$row->{'metagenome_id'}} = $row->{'job_id'};
    $genome_id2jobname->{$row->{'metagenome_id'}} = $row->{'name'};
    $genome_id2project->{$row->{'metagenome_id'}} = $row->{'project'};
    if (exists($row->{'env_package'}) && $row->{'env_package'}) {
      $genome_id2env->{$row->{'metagenome_id'}} = $row->{'env_package'};
      $envs->{$row->{'env_package'}} = 1;
    }
    if (exists $row->{'pi'}) {
      $pis->{$row->{'pi'}} = 1;
    }
    $data->{$row->{'job_id'}} = {};
    $data->{$row->{'job_id'}}->{jobname} = [ $row->{'metagenome_id'} ];
  }
  $self->{'num_envs'} = scalar(keys(%$envs));
  $self->{'num_pis'} = scalar(keys(%$pis));
  
  my $collection_prefs = $dbmaster->Preferences->get_objects( { application => $application->backend,
								user => $user,
								name => 'mgrast_collection' } );
  my $cdata_hash = {};
  foreach my $collection_pref (@$collection_prefs) {
    my ($name, $val) = split(/\|/, $collection_pref->{value});
    if (! exists($cdata_hash->{$name})) {
      $cdata_hash->{$name} = [ $val ];
    } else {
      push(@{$cdata_hash->{$name}}, $val);
    }
  }

  $html .= $self->application->component('ajax')->output();
  
  my $private_data = "";
  my $in_progress_table = "";  
  my $pub_sidebar = "";
  
  # space for ajax status
  $html .= "<div id='ajax_return'></div>";
  
  $html .= "<table><tr><td>";
  $html .= "<div style='font: 12px sans-serif;margin-right:10px;'>$private_data<br>$pub_sidebar</div>";
  $html .= "</td><td>";
  $html .= "<div style='position: relative; right: 90px;'>";

  # grouping buttons
  $html .= "<div id='group_link_div'><a id='grouping_link' style='cursor: pointer;'>group by project</a><a id='ungrouping_link' style='cursor: pointer; display: none;'>clear grouping</a></div>";
  
  # all metagenomes
  my $all_metagenomes_table = $self->application->component('all_metagenomes');
  $all_metagenomes_table->{sequential_init} = 1;
  $all_metagenomes_table->items_per_page(10);
  $all_metagenomes_table->show_top_browse(1);
  $all_metagenomes_table->show_bottom_browse(1);
  $all_metagenomes_table->show_select_items_per_page(1); 
  $all_metagenomes_table->width(800);
  $all_metagenomes_table->show_column_select(1); 
  my $all_metagenomes_cols = [ { name => 'job&nbsp;&#35;', filter => 1, visible => 0, sortable => 1, width => 52 },
			       { name => 'id', filter => 1, visible => 0, sortable => 1, width => 60 },
			       { name => 'project', filter => 1, sortable => 1 },
			       { name => 'name', filter => 1, sortable => 1 },
			       { name => 'bps', filter => 1, sortable => 1, operators => ['less','more'] },
			       { name => 'sequences', filter => 1, sortable => 1, operators => ['less','more'] },
			       { name => 'biome', filter => 1, operator => 'combobox', sortable => 0 },
			       { name => 'feature', filter => 1, operator => 'combobox', sortable => 0 },
			       { name => 'material', filter => 1, operator => 'combobox', sortable => 0 },
			       { name => 'enviroment&nbsp;package', filter => 1, operator => 'combobox', sortable => 1, visible => 0 },
			       { name => 'sequencing&nbsp;type', filter => 1, operator => 'combobox', sortable => 1 },
			       { name => 'altitude', filter => 1, operator => 'combobox', visible => 0 },
			       { name => 'depth', filter => 1, operator => 'combobox', visible => 0 },
			       { name => 'location', filter => 1, operator => 'combobox', visible => 0 },
			       { name => 'ph', filter => 1, operator => 'combobox', visible => 0 },
			       { name => 'country', filter => 1, operator => 'combobox', visible => 0 },
			       { name => 'temperature', filter => 1, operator => 'combobox', visible => 0 },
			       { name => 'sequencing&nbsp;method', filter => 1, operator => 'combobox', visible => 0 },
			       { name => 'pi', filter => 1, operator => 'combobox', visible => 0 },
			       { name => 'avg&nbsp;seq&nbsp;length', filter => 1, sortable => 1, operators => ['less','more'], visible => 0 },
			       { name => 'drisee', filter => 1, sortable => 1, operators => ['less','more'], visible => 0 },
			       { name => '&alpha;-diversity', filter => 1, sortable => 1, operators => ['less','more'], visible => 0 }
			     ];
  if ($user) {
    push @$all_metagenomes_cols, { name => '', filter => 1, operator => 'combobox', visible => 1, width => 40};
    push @$all_metagenomes_cols, { name => 'select<div style="margin-top:4px; margin-left: 2px;"><input type="checkbox" onclick="table_select_all_checkboxes(\''.$all_metagenomes_table->id.'\', \''.scalar(@$all_metagenomes_cols).'\', this.checked, 1)">&nbsp;all</div>', visible => 1, width => 36, input_type => 'checkbox', unaddable => 1 };
  }
  $all_metagenomes_table->columns($all_metagenomes_cols);
  my @all_metagenome_data = ();
  my $private_color = "#8FBC3F";
  my $shared_color = "#FF9933";
  # goofiness to sort on shared to get private, shared, public
  my %sort_order = ( 0 => 1, 1 => 2, '' => 3 );
  
  foreach my $row (@$data_table) {
    my $id_link = "<a href='?page=MetagenomeOverview&metagenome=".$row->{'metagenome_id'}."' target='_blank'>".$row->{'metagenome_id'}."</a>";
    my $name_link = "<a href='?page=MetagenomeOverview&metagenome=".$row->{'metagenome_id'}."' target='_blank'>".($row->{'name'} ? $row->{'name'} : "-")."</a>";
    my $project_link = ($row->{'project'}) ? "<a href='?page=MetagenomeProject&project=".$row->{'project_id'}."' target='_blank'>".$row->{'project'}."</a>" : "unknown";

    my $table_row = [ $row->{'job_id'},
		      $id_link,
		      $project_link,
		      $name_link,
		      $row->{'bp_count'},
		      $row->{'sequence_count'},
		      sanitize($row->{'biome'}),
		      sanitize($row->{'feature'}),
		      sanitize($row->{'material'}),
		      sanitize($row->{'env_package'}),
		      sanitize($row->{'sequence_type'}),
		      $row->{'altitude'},
		      $row->{'depth'},
		      sanitize($row->{'location'}),
		      $row->{'ph'},
		      sanitize($row->{'country'}),
		      $row->{'temperature'},
		      sanitize($row->{'sequencing method'}),
		      sanitize($row->{'pi'}),
		      $row->{'average_length'} ? sprintf("%.3f",$row->{'average_length'}) : '',
		      $row->{'drisee'} ? sprintf("%.3f",$row->{'drisee'}) : '',
		      $row->{'alpha_diversity'} ? sprintf("%.3f",$row->{'alpha_diversity'}) : ''
		    ];
    if ($user) {
      push @$table_row, ($row->{'public'}) ? { 'data'=> 'public' } : ($row->{'shared'}) ? { 'data'=> '<span style=\'color: white;\'>shared</span>', highlight=> $shared_color } : { 'data'=> '<span style=\'color: white;\'>private</span>', highlight=> $private_color};
      push @$table_row, "<div style='margin-top:2px; margin-left: 10px;'><input type='checkbox' name='table_selection' value='".$row->{'metagenome_id'}."'>";
    }
    push @all_metagenome_data, $table_row;
  }
  
  $all_metagenomes_table->data(\@all_metagenome_data);

  $html .= $all_metagenomes_table->output();
    
  return $html;
}

sub sanitize {
  my ($input) = @_;
  return $input if ($input and $input ne '' and $input ne ' ' and $input ne '0' and $input ne ' - ' and $input ne "unknown");
  return 'unknown';
}

sub get_in_progress_table {
  my ($self) = @_;	
  my $user = $self->application->session->user;
  my $mgrast = $self->application->data_handle('MGRAST');
  my @stages = ('upload', 'preprocess', 'dereplication', 'screen', 'genecalling', 'cluster_aa90', 'loadAWE', 'sims', 'loadDB', 'done');
  my %stage_info = ( 'upload'        => ['Upload', 3], 
		     'preprocess'    => ['Sequence Filtering', 4],
		     'dereplication' => ['Dereplication', 5],
		     'screen'        => ['Sequence Screening', 6],
		     'genecalling'   => ['Gene Calling', 7],
		     'cluster_aa90'  => ['Gene Clustering', 8],
		     'loadAWE'       => ['Calculating Sims', 9],
		     'sims'          => ['Processing Sims', 10],
		     'loadDB'        => ['Loading Database', 11],
		     'done'          => ['Finalizing Data', 12] );
  my $html = "";
  my $data_table = $mgrast->Job->fetch_browsepage_in_progress($user);
  
  # populate in progress table
  my $in_progress = $self->application->component('user_in_progess');
  $in_progress->{sequential_init} = 1;
  $in_progress->items_per_page(25);
  $in_progress->show_bottom_browse(1);
  $in_progress->show_select_items_per_page(1); 
  $in_progress->width(700);
  $in_progress->show_column_select(1); 
  $in_progress->columns([ { name => 'job #', filter => 1, visible => 1, sortable => 1, width => 55 },
			  { name => 'id', filter => 1, visible => 1, sortable => 1, width => 60 },
			  { name => 'name', filter => 1, visible => 1, sortable => 1 },
			  { name => 'progress', width => 135 },
			  { name => 'status', filter => 1, sortable => 1 } ]);
  
  my $data = [];
  foreach my $row (sort {$b->[0] <=> $a->[0]} @$data_table){
	my @in_progress = ();
	my $last_stage = '';
	foreach my $s (@stages){
	  if ($s eq 'upload'){
		push @in_progress, $self->color_box_for_state('completed', $s);
		$last_stage = $s;
	  } else {
		push @in_progress, $self->color_box_for_state($row->[$stage_info{$s}->[1]], $s);
	  }
	  $last_stage = $s if $row->[$stage_info{$s}->[1]];
	}
	if ($last_stage eq 'loadAWE'){
	  $row->[$stage_info{$last_stage}->[1]] = 'running';
	  $in_progress[6] = $self->color_box_for_state('running', 'loadAWE');
	}
	push @$data, [$row->[0], $row->[2], $row->[1], "<div>".join("", @in_progress)."</div>", ($last_stage) ? $stage_info{$last_stage}->[0]." : ".(($row->[$stage_info{$last_stage}->[1]]) ? $row->[$stage_info{$last_stage}->[1]] : "completed") : "" ];
  }
  $in_progress->data($data);
  
  $html .= $in_progress->output();  
  return $html;	
}

sub color_box_for_state {
  my ($self, $state, $stage) = @_;
  my %state_to_color = ( 'running' => "#FFBE1E",
			 'completed' => "#3CA53C",
			 'unknown' => "#B9B9B9",
			 'error' => "red" );
  
  if ($state and exists $state_to_color{$state}){
    return "<div title='".$stage."' style='float:left; height: 14px; width: 12px; margin: 2 0 2 1; background-color:".$state_to_color{$state}.";'></div>";
  } else {
    return "<div title='".$stage."' style='float:left; height: 14px; width: 12px; margin: 2 0 2 1; background-color:".$state_to_color{'unknown'}.";'></div>";
  }
}

sub format_number {
  my ($val) = @_;
  
  while ($val =~ s/(\d+)(\d{3})+/$1,$2/) {}
  
  return $val;
}

sub require_css {
  return [ "$FIG_Config::cgi_url/Html/MetagenomeSelect.css" ];
}

sub require_javascript {
  return [ "$FIG_Config::cgi_url/Html/MetagenomeSelect.js" ];
}

sub processing_info {
  my ($self) = @_;
  
  my $id  = $self->application->cgi->param('metagenome');
  my $jobdbm = $self->app->data_handle('MGRAST');
  my $job = $jobdbm->Job->init({ metagenome_id => $id });

  my $content = "<div style='text-align: left;'><h3>Jobs Details #".$job->job_id."</h3>";

  # general info
  $content .= "<div class='metagenome_info' style='width: 600px; margin-bottom: 30px; float: none;'><ul style='margin: 0; padding: 0;'>";
  $content .= "<li class='first'><label style='text-align: left; width: 220px;'>Metagenome ID - Name</label><span style='width: 360px'>".$job->metagenome_id." - ".$job->name."</span></li>";
  $content .= "<li class='odd'><label style='text-align: left; width: 220px;'>Job</label><span style='width: 360px'>".$job->job_id."</span></li>";
  $content .= "<li class='even'><label style='text-align: left; width: 220px;'>User</label><span style='width: 360px'>".$job->owner->login."</span></li>";
  $content .= "<li class='odd'><label style='text-align: left; width: 220px;'>Date</label><span style='width: 360px'>".$job->created_on."</span></li>";

  my $seqs_num = $jobdbm->JobStatistics->get_objects({ job => $job, tag => 'sequence_count_raw'});
  if (scalar($seqs_num)) {
    $seqs_num = $seqs_num->[0]->{value} || 0;
  } else {
    $seqs_num = 0;
  }
  my $bp_num = $jobdbm->JobStatistics->get_objects({ job => $job, tag => 'bp_count_raw'});
  if (scalar($bp_num)) {
    $bp_num = $bp_num->[0]->{value} || 0;
  } else {
    $bp_num = 0;
  }

  $content .= "<li class='even'><label style='text-align: left; width: 220px;'>Number of uploaded sequences</label><span style='width: 360px'>".$seqs_num."</span></li>";
  $content .= "<li class='odd'><label style='text-align: left; width: 220px;'>Total uploaded sequence length</label><span style='width: 360px'>".$bp_num."</span></li>";
  $content .= "</ul></div>";

  # check for downloads
  my $downloads = $job->downloads();
  if (scalar(@$downloads)) {
    my @values = map { $_->[0] } @$downloads;
    my %labels = map { $_->[0] => $_->[1] || $_->[0] } @$downloads;
    $content .= $self->start_form('download', { page => 'DownloadFile', job => $job->job_id });
    $content .= '<p> &raquo; Available downloads for this job: ';
    $content .= $self->app->cgi->popup_menu( -name => 'file',
					     -values => \@values,
					     -labels => \%labels, );
    $content .= "<input type='submit' value=' Download '>";
    $content .= $self->end_form;
  }
  else {
    if ($job->viewable) {
      $content .= '<p> &raquo; No downloads available for this metagenome yet.</p>';
    }
  }

  $content .= "</div><br><br><br><br>";

  return $content;
}

sub get_colors {
  my ($self, $image) = @_;
  return { 'white' => $image->colorResolve(255,255,255),
		   'black' => $image->colorResolve(0,0,0),
		   'not_started' => $image->colorResolve(185,185,185),
		   'queued' => $image->colorResolve(30,120,220),
		   'in_progress' => $image->colorResolve(255,190,30),
		   'running' => $image->colorResolve(255,190,30),
		   'load_in_progress' => $image->colorResolve(255,190,30),
		   'requires_intervention' => $image->colorResolve(255,30,30),
		   'error' => $image->colorResolve(175,45,45),
		   'complete' => $image->colorResolve(60,165,60),
		   'completed' => $image->colorResolve(60,165,60),
  };
}


sub change_collection {
  my ($self) = @_;

  my $application = $self->application;
  my $cgi = $application->cgi;
  my $dbmaster = $application->dbmaster;
  my $mgrast = $application->data_handle('MGRAST');
  my $user = $application->session->user;
  my $cdtable = $application->component('collection_table_detail');

  my $return_msg = "";

  # check for mass deletion
  if ($cgi->param('remove_entries')) {
    my @vals = split /\|/, $cgi->param('ids');
    foreach my $val (@vals) {
      my ($set, $v) = split /\^/, $val;
      if (! defined($v)) {
	my $existing = $dbmaster->Preferences->get_objects( { application => $application->backend,
							      user => $user,
							      name => 'mgrast_collection' } );
	foreach my $e (@$existing) {
	  if ($e->{value} =~ /^$set\|/) {
	    $e->delete;
	  }
	}

      } else {
	my $existing = $dbmaster->Preferences->get_objects( { application => $application->backend,
							      user => $user,
							      name => 'mgrast_collection',
							      value => $set."|".$v } );
	if (scalar(@$existing)) {
	  $existing->[0]->delete;
	}
      }
    }
    $return_msg = "The selected collection entries have been removed.";
  }


  # check for mass addition to a set
  if ($cgi->param('newcollection')) {
    my $set = $cgi->param('newcollection');
    my @vals = split /\|/, $cgi->param('ids');
    foreach my $val (@vals) {
      my $existing = $dbmaster->Preferences->get_objects( { application => $application->backend,
							    user => $user,
							    name => 'mgrast_collection',
							    value => $set."|".$val } );
      unless (scalar(@$existing)) {
	$dbmaster->Preferences->create( { application => $application->backend,
					  user => $user,
					  name => 'mgrast_collection',
					  value => $set."|".$val } );
      }
    }
    $return_msg = "The selected metagenomes have been added to collection $set";
  }

  # check for renaming
  if ($cgi->param('newname') && $cgi->param('oldname')) {
    my $coll_to_change = $dbmaster->Preferences->get_objects( { application => $application->backend,
								user => $user,
								name => 'mgrast_collection',
								value => [ $cgi->param('oldname').'|%', 'like' ] } );
    foreach my $ctc (@$coll_to_change) {
      my ($c, $v) = split(/\|/, $ctc->{value});
      $ctc->value($cgi->param('newname')."|".$v);
    }
  }

  # return updated collection info
  my $collection_prefs = $dbmaster->Preferences->get_objects( { application => $application->backend,
 								user => $user,
 								name => 'mgrast_collection' } );
  
  my $projects = $mgrast->Project->get_objects();
  my $project_hash = {};
  %$project_hash = map { $_->{name} => $_ } @$projects;

  my $data_table = $mgrast->Job->fetch_browsepage_viewable($user);
  my $genome_id2job_id = {};
  my $genome_id2jobname = {};  
  my $genome_id2project = {};
  my $genome_id2env = {};

  my $data = {};
  my $envs = {};
  my $pis = {};
  
  foreach my $row (@$data_table){
    $genome_id2job_id->{$row->{'metagenome_id'}} = $row->{'job_id'};
    $genome_id2jobname->{$row->{'metagenome_id'}} = $row->{'name'};
    $genome_id2project->{$row->{'metagenome_id'}} = $row->{'project'};
    if (exists($row->{'env_package'}) and ($row->{'env_package'} =~ /\S/)) {
      $genome_id2env->{$row->{'metagenome_id'}} = $row->{'env_package'};
      $envs->{$row->{'env_package'}} = 1;
    }
    if (exists $row->{'pi'}) {
      $pis->{$row->{'pi'}} = 1;
    }
    $data->{$row->{'job_id'}} = {};
    $data->{$row->{'job_id'}}->{jobname} = [ $row->{'metagenome_id'} ];
  }

  my $cdata_hash = {};
  foreach my $collection_pref (@$collection_prefs) {
    my ($name, $val) = split(/\|/, $collection_pref->{value});
    if (! exists($cdata_hash->{$name})) {
      $cdata_hash->{$name} = [ $val ];
    } else {
      push(@{$cdata_hash->{$name}}, $val);
    }
  }

  my $cdata = [];
  my $cddata_string = "";
  my $row_ind = 0;
  foreach my $k (keys(%$cdata_hash)) {
    my $cddata = [];
    my $ind = 0;
    foreach my $v (@{$cdata_hash->{$k}}) {
      my $name_link = "<a href='?page=MetagenomeOverview&metagenome=".$data->{$v}{jobname}[0]."' target='_blank'>".$genome_id2jobname->{$data->{$v}{jobname}[0]}." (".$data->{$v}{jobname}[0].")</a>";
      my $pid = $genome_id2project->{$data->{$v}{jobname}[0]} ? $project_hash->{$genome_id2project->{$data->{$v}{jobname}[0]}}->{id} : "";
      my $project_link = $genome_id2project->{$data->{$v}{jobname}[0]} ? "<a href='?page=MetagenomeProject&project=$pid' target=_blank>".$genome_id2project->{$data->{$v}{jobname}[0]}."</a>" : "-";
      my $project_type = $genome_id2project->{$data->{$v}{jobname}[0]} ? $project_hash->{$genome_id2project->{$data->{$v}{jobname}[0]}}->{type} : "-";
      my $cds = $name_link."~~".$project_link."~~".$project_type."~~".($genome_id2env->{$data->{$v}{jobname}[0]} || "-")."~~<input type='checkbox'>~~".$ind;
      $cds =~ s/"/\@1/g;
      $cds =~ s/'/\@2/g;
      push(@$cddata, $cds);
      $ind++;
    }
    $cddata_string .= "<input type='hidden' id='collection_detail_data_$row_ind' value='".join("^^", @$cddata)."'>";
    push(@$cdata, [ $k, scalar(keys(@{$cdata_hash->{$k}})), 0, '<input type="button" value="delete" onclick="remove_single(@1'.$k.'@1);>', '<input type="button" value="share" onclick="share_collection('.$row_ind.', @1'.$k.'@1);">', '<input type="button" value="edit" onclick="show_collection_detail('.$row_ind.', '.$cdtable->id.', @1'.$k.'@1);">' ]);
    $row_ind++;
  }
  my $collections_data = join('|', map { join('^', @$_) } @$cdata);
  my $num_collections = scalar(keys(%$cdata_hash));

  return "<input type='hidden' id='return_message' value='$return_msg'><input type='hidden' id='new_collection_num' value='$num_collections'><input type='hidden' id='new_collection_data' value='$collections_data'>$cddata_string<img src='./Html/clear.gif' onload='update_collection_data(\"".$application->component('collection_table')->id."\");'>";
}

sub commafy {
  my ($val) = @_;
  while ($val =~ s/(\d+)(\d{3})+/$1,$2/) {}
  return $val;
}

package nilsobergContigFilter::nilsobergContigFilterImpl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = '0.0.1';
our $GIT_URL = '';
our $GIT_COMMIT_HASH = '';

=head1 NAME

nilsobergContigFilter

=head1 DESCRIPTION

A KBase module: nilsobergContigFilter
This sample module contains one small method that filters contigs.

=cut

#BEGIN_HEADER
use Bio::KBase::AuthToken;
use installed_clients::AssemblyUtilClient;
use installed_clients::KBaseReportClient;
use Config::IniFiles;
use Bio::SeqIO;
use Data::Dumper;
#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR
    
    my $config_file = $ENV{ KB_DEPLOYMENT_CONFIG };
    my $cfg = Config::IniFiles->new(-file=>$config_file);
    my $scratch = $cfg->val('nilsobergContigFilter', 'scratch');
    my $callbackURL = $ENV{ SDK_CALLBACK_URL };
    
    $self->{scratch} = $scratch;
    $self->{callbackURL} = $callbackURL;
    
    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 run_nilsobergContigFilter

  $output = $obj->run_nilsobergContigFilter($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a reference to a hash where the key is a string and the value is an UnspecifiedObject, which can hold any non-null object
$output is a nilsobergContigFilter.ReportResults
ReportResults is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string

</pre>

=end html

=begin text

$params is a reference to a hash where the key is a string and the value is an UnspecifiedObject, which can hold any non-null object
$output is a nilsobergContigFilter.ReportResults
ReportResults is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string


=end text



=item Description

This example function accepts any number of parameters and returns results in a KBaseReport

=back

=cut

sub run_nilsobergContigFilter
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to run_nilsobergContigFilter:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'run_nilsobergContigFilter');
    }

    my $ctx = $nilsobergContigFilter::nilsobergContigFilterServer::CallContext;
    my($output);
    #BEGIN run_nilsobergContigFilter
    
    # Print statements to stdout/stderr are captured and available as the App log
    print("Starting run_nilsobergContigFilter method. Parameters:\n");
    print(Dumper($params) . "\n");
    
    # Step 1 - Parse/examine the parameters and catch any errors
    # It is important to check that parameters exist and are defined, and that nice error
    # messages are returned to users.  Parameter values go through basic validation when
    # defined in a Narrative App, but advanced users or other SDK developers can call
    # this function directly, so validation is still important.
    
    if (!exists $params->{'workspace_name'}) {
        die "Parameter workspace_name is not set in input arguments";
    }
    my $workspace_name=$params->{'workspace_name'};
    
    if (!exists $params->{'assembly_input_ref'}) {
        die "Parameter assembly_input_ref is not set in input arguments";
    }
    my $assy_ref=$params->{'assembly_input_ref'};
    
    if (!exists $params->{'min_length'}) {
        die "Parameter min_length is not set in input arguments";
    }
    my $min_length = $params->{'min_length'};
    if ($min_length < 0) {
        die "min_length parameter cannot be negative (".$min_length.")";
    }
    
    # Step 2 - Download the input data as a Fasta file
    # We can use the AssemblyUtils module to download a FASTA file from our Assembly data
    # object. The return object gives us the path to the file that was created.
    
    print("Downloading assembly data as FASTA file.\n");
    my $assycli = installed_clients::AssemblyUtilClient->new($self->{callbackURL});
    my $fileobj = $assycli->get_assembly_as_fasta({ref => $assy_ref});
    
    # Step 3 - Actually perform the filter operation, saving the good contigs to a new
    # fasta file.
    
    my $sio_in = Bio::SeqIO->new(-file => $fileobj->{path});
    my $outfile = $self->{scratch} . "/" . "filtered.fasta";
    my $sio_out = Bio::SeqIO->new(-file => ">$outfile", -format=> "fasta");
    my $total = 0;
    my $remaining = 0;
    while (my $seq = $sio_in->next_seq) {
        $total++;
        if ($seq->length >= $min_length) {
            $remaining++;
            $sio_out->write_seq($seq);
        }
    }
    my $result_text = "Filtered assembly to " . $remaining . " contigs out of " . $total;
    print($result_text . "\n");
    
    # Step 4 - Save the new Assembly back to the system
    my $newref = $assycli->save_assembly_from_fasta({assembly_name => $fileobj->{assembly_name},
                                                     workspace_name => $workspace_name,
                                                     file => {path => $outfile}});

    # Step 5 - Build a report and return
    my $repcli = installed_clients::KBaseReportClient->new($self->{callbackURL});
    my $report = $repcli->create(
        {workspace_name => $workspace_name,
         report => {text_message => $result_text,
                    objects_created => [{description => "Filtered contigs",
                                         ref => $newref}
                                        ]
                    }
         });
    
    # Step 6 - construct the output to send back
    
    my $output = {assembly_output => $newref,
                  n_initial_contigs => $total,
                  n_contigs_remaining => $remaining,
                  n_contigs_removed => $total - $remaining,
                  report_name => $report->{name},
                  report_ref => $report->{ref}};

    print("returning: ".Dumper($output)."\n");
    
    #END run_nilsobergContigFilter
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to run_nilsobergContigFilter:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'run_nilsobergContigFilter');
    }
    return($output);
}




=head2 run_nilsobergContigFilter_max

  $output = $obj->run_nilsobergContigFilter_max($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a reference to a hash where the key is a string and the value is an UnspecifiedObject, which can hold any non-null object
$output is a nilsobergContigFilter.ReportResults
ReportResults is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string

</pre>

=end html

=begin text

$params is a reference to a hash where the key is a string and the value is an UnspecifiedObject, which can hold any non-null object
$output is a nilsobergContigFilter.ReportResults
ReportResults is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string


=end text



=item Description



=back

=cut

sub run_nilsobergContigFilter_max
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to run_nilsobergContigFilter_max:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'run_nilsobergContigFilter_max');
    }

    my $ctx = $nilsobergContigFilter::nilsobergContigFilterServer::CallContext;
    my($output);
    #BEGIN run_nilsobergContigFilter_max
    ############################################################################################################

    if (!exists $params->{'workspace_name'}) {
        die "Parameter workspace_name is not set in input arguments";
    }
    my $workspace_name=$params->{'workspace_name'};
    if (!exists $params->{'assembly_input_ref'}) {
        die "Parameter assembly_input_ref is not set in input arguments";
    }
    my $assy_ref=$params->{'assembly_input_ref'};

    if (not exists $params->{max_length}) {
        die "Parameter max_length is not set in input arguments";
    }
    if (not exists $params->{min_length}) {
        die "Parameter min_length is not set in input arguments";
    }
    if ($params->{max_length} < 1) {
        die "max_length parameter must be greater than zero";
    }
    if ($params->{min_length} < 0) {
        die "min_length parameter cannot be negative";
    }
    if ($params->{min_length} and $params->{min_length} > $params->{max_length}) {
        die "max_length parameter cannot be less than or equal to min_length parameter";
    }
    my $max_length = $params->{max_length};
    
    print("Downloading assembly data as FASTA file.\n");
    my $assycli = installed_clients::AssemblyUtilClient->new($self->{callbackURL});
    my $fileobj = $assycli->get_assembly_as_fasta({ref => $assy_ref});
    
    # Step 3 - Actually perform the filter operation, saving the good contigs to a new
    # fasta file.
    my $sio_in = Bio::SeqIO->new(-file => $fileobj->{path});
    my $outfile = $self->{scratch} . "/" . "filtered.fasta";
    my $sio_out = Bio::SeqIO->new(-file => ">$outfile", -format=> "fasta");
    my $total = 0;
    my $remaining = 0;
    while (my $seq = $sio_in->next_seq) {
        $total++;
        if ($seq->length <= $max_length) {
            $remaining++;
            $sio_out->write_seq($seq);
        }
    }
    my $result_text = "Filtered assembly to " . $remaining . " contigs out of " . $total;
    print($result_text . "\n");
    
    # Step 4 - Save the new Assembly back to the system
    my $newref = $assycli->save_assembly_from_fasta({assembly_name => $fileobj->{assembly_name},
                                                     workspace_name => $workspace_name,
                                                     file => {path => $outfile}});

    # Step 5 - Build a report and return
    my $repcli = installed_clients::KBaseReportClient->new($self->{callbackURL});
    
    my $report = $repcli->create(
        {workspace_name => $workspace_name,
         report => {text_message => $result_text,
                    objects_created => [{description => "Filtered contigs",
                                         ref => $newref}
                                        ]
                    }
         });
    
    # Step 6 - construct the output to send back
    
    $output = {assembly_output => $newref,
                  n_initial_contigs => $total,
                  n_contigs_remaining => $remaining,
                  n_contigs_removed => $total - $remaining,
                  report_name => $report->{name},
                  report_ref => $report->{ref}};

    print("returning: ".Dumper($output)."\n");

    ############################################################################################################
    #END run_nilsobergContigFilter_max
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to run_nilsobergContigFilter_max:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'run_nilsobergContigFilter_max');
    }
    return($output);
}




=head2 status 

  $return = $obj->status()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a string
</pre>

=end html

=begin text

$return is a string

=end text

=item Description

Return the module status. This is a structure including Semantic Versioning number, state and git info.

=back

=cut

sub status {
    my($return);
    #BEGIN_STATUS
    $return = {"state" => "OK", "message" => "", "version" => $VERSION,
               "git_url" => $GIT_URL, "git_commit_hash" => $GIT_COMMIT_HASH};
    #END_STATUS
    return($return);
}

=head1 TYPES



=head2 ReportResults

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
report_name has a value which is a string
report_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
report_name has a value which is a string
report_ref has a value which is a string


=end text

=back



=cut

1;

use strict;
use Data::Dumper;
use Test::More;
use Config::Simple;
use Time::HiRes qw(time);
use Bio::KBase::AuthToken;
use installed_clients::WorkspaceClient;
use installed_clients::AssemblyUtilClient;
use nilsobergContigFilter::nilsobergContigFilterImpl;

local $| = 1;
my $token = $ENV{'KB_AUTH_TOKEN'};
my $config_file = $ENV{'KB_DEPLOYMENT_CONFIG'};
my $config = new Config::Simple($config_file)->get_block('nilsobergContigFilter');
my $ws_url = $config->{"workspace-url"};
my $ws_name = undef;
my $ws_client = new installed_clients::WorkspaceClient($ws_url,token => $token);
my $scratch = $config->{scratch};
my $callback_url = $ENV{'SDK_CALLBACK_URL'};
my $auth_token = Bio::KBase::AuthToken->new(token => $token, ignore_authrc => 1, auth_svc=>$config->{'auth-service-url'});
my $ctx = LocalCallContext->new($token, $auth_token->user_id);
$nilsobergContigFilter::nilsobergContigFilterServer::CallContext = $ctx;
my $impl = new nilsobergContigFilter::nilsobergContigFilterImpl();

sub get_ws_name {
    if (!defined($ws_name)) {
        my $suffix = int(time * 1000);
        $ws_name = 'test_nilsobergContigFilter_' . $suffix;
        $ws_client->create_workspace({workspace => $ws_name});
    }
    return $ws_name;
}

sub load_fasta {
    my $filename = shift;
    my $object_name = shift;
    my $filecontents = shift;
    open (my $fh, '>', $filename) or die "Could not open file '$filename' $!";
    print $fh $filecontents;
    close $fh;
    my $assycli = installed_clients::AssemblyUtilClient->new($callback_url);
    return $assycli->save_assembly_from_fasta({assembly_name => $object_name,
                                               workspace_name => get_ws_name(),
                                               file => {path => $filename}});
}

eval {

    # First load a test FASTA file as an KBase Assembly
    my $fastaContent = ">seq1 something something asdf\n" .
                       "agcttttcat\n" .
                       ">seq2\n" .
                       "agctt\n" .
                       ">seq3\n" .
                       "agcttttcatgg";
         
    my $ref = load_fasta($scratch . "/test1.fasta", "TestAssembly", $fastaContent);

    # Second, call the implementation
    my $ret = $impl->run_nilsobergContigFilter({workspace_name => get_ws_name(),
                                     assembly_input_ref => $ref,
                                     min_length => 10});

    # validate the returned data
    ok($ret->{n_initial_contigs} eq 3, "number of initial contigs");
    ok($ret->{n_contigs_removed} eq 1, "number of removed contigs");
    ok($ret->{n_contigs_remaining} eq 2, "number of remaining contigs");

    $@ = '';
    eval { 
        $impl->run_nilsobergContigFilter({workspace_name => get_ws_name(),
                               assembly_input_ref=>"fake",
                               min_length => 10});
    };
    like($@, qr#separators / in object reference fake#);
    
    eval { 
        $impl->run_nilsobergContigFilter({workspace_name => get_ws_name(),
                               assembly_input_ref => "fake",
                               min_length => -10});
    };
    like($@, qr/min_length parameter cannot be negative/);
    
    eval {
        $impl->run_nilsobergContigFilter({workspace_name => get_ws_name(),
                               assembly_input_ref => "fake"});
    };
    like($@, qr/Parameter min_length is not set in input arguments/);




    
    eval { 
        $impl->run_nilsobergContigFilter_max({workspace_name => get_ws_name(),
                               assembly_input_ref=>"fake"});
    };
    like($@, qr/Parameter max_length is not set in input arguments/);
    
    eval { 
        $impl->run_nilsobergContigFilter_max({workspace_name => get_ws_name(),
                               assembly_input_ref => "fake",
                               max_length => 1});
    };
    like($@, qr/Parameter min_length is not set in input arguments/);
    
    eval { 
        $impl->run_nilsobergContigFilter_max({workspace_name => get_ws_name(),
                               assembly_input_ref => "fake",
                               min_length => 0,
                               max_length => 0});
    };
    like($@, qr/max_length parameter must be greater than zero/);
    
    eval { 
        $impl->run_nilsobergContigFilter_max({workspace_name => get_ws_name(),
                               assembly_input_ref => "fake",
                               min_length => -1,
                               max_length => 10});
    };
    like($@, qr/min_length parameter cannot be negative/);
    
    eval { 
        $impl->run_nilsobergContigFilter_max({workspace_name => get_ws_name(),
                               assembly_input_ref => "fake",
                               min_length => 10,
                               max_length => 1});
    };
    like($@, qr/max_length parameter cannot be less than or equal to min_length parameter/);
    
    eval { 
        my $out = $impl->run_nilsobergContigFilter_max({workspace_name => get_ws_name(),
                               assembly_input_ref => "fake",
                               min_length => 10,
                               max_length => 1});
        ok($out->{'report_name'}, "missing report name");
        ok($out->{'report_ref'}, "missing report ref");
    };
    like($@, qr/max_length parameter cannot be less than or equal to min_length parameter/);
    
    done_testing(12);

};
my $err = undef;
if ($@) {
    $err = $@;
}
eval {
    if (defined($ws_name)) {
        $ws_client->delete_workspace({workspace => $ws_name});
        print("Test workspace was deleted\n");
    }
};
if (defined($err)) {
    use Scalar::Util 'blessed';
    if(blessed $err && $err->isa("Bio::KBase::Exceptions::KBaseException")) {
        die "Error while running tests. Remote error:\n" . $err->{data} .
            "Client-side error:\n" . $err;
    } else {
        die $err;
    }
}

{
    package LocalCallContext;
    use strict;
    sub new {
        my($class,$token,$user) = @_;
        my $self = {
            token => $token,
            user_id => $user
        };
        return bless $self, $class;
    }
    sub user_id {
        my($self) = @_;
        return $self->{user_id};
    }
    sub token {
        my($self) = @_;
        return $self->{token};
    }
    sub provenance {
        my($self) = @_;
        return [{'service' => 'nilsobergContigFilter', 'method' => 'please_never_use_it_in_production', 'method_params' => []}];
    }
    sub authenticated {
        return 1;
    }
    sub log_debug {
        my($self,$msg) = @_;
        print STDERR $msg."\n";
    }
    sub log_info {
        my($self,$msg) = @_;
        print STDERR $msg."\n";
    }
}

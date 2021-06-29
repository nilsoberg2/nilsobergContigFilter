use nilsobergContigFilter::nilsobergContigFilterImpl;

use nilsobergContigFilter::nilsobergContigFilterServer;
use Plack::Middleware::CrossOrigin;



my @dispatch;

{
    my $obj = nilsobergContigFilter::nilsobergContigFilterImpl->new;
    push(@dispatch, 'nilsobergContigFilter' => $obj);
}


my $server = nilsobergContigFilter::nilsobergContigFilterServer->new(instance_dispatch => { @dispatch },
				allow_get => 0,
			       );

my $handler = sub { $server->handle_input(@_) };

$handler = Plack::Middleware::CrossOrigin->wrap( $handler, origins => "*", headers => "*");

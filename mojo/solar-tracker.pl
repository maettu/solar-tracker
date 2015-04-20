use Mojolicious::Lite;
use Mojo::JSON qw (decode_json);
use RRDs;

get '/' => sub { my $c = shift;
    for my $num_days (1, 5, 30, 365){
        RRDs::graph(
            '--start', "end-${num_days}d",
            '-w', 1000, '-h', 200,
            '-u', 7000,       # specify max to keep scale always the same
            "public/${num_days}d.png",
            'DEF:solar=../rrd/solar.rrd:watt:AVERAGE',
            'AREA:solar#03bde9'
        );
    }
    $c->render(
        template       => 'main',
        current_energy => RRDs::info('../rrd/solar.rrd')->{'ds[watt].last_ds'}
    );
};

post '/infeed' => sub { my $c = shift;
    my ($watts) = decode_json($c->req->body)->{Body}{PAC}{Values}{1} =~ /(\d+)/;
    say time."\t$watts";
    RRDs::update('../rrd/solar.rrd', time.":$watts");
	$c->render(json => {reply=>'ok'});
};

app->start;

__DATA__
@@ main.html.ep
<h1>My Own Sunshine</h1>
<p>Current Energy: <%= $current_energy %> Watts</p>
<h2>1 Day</h2>
<img src="1d.png" alt="graph 1 day" >
<h2>5 Days</h2>
<img src="5d.png" alt="graph 5 days" >
<h2>30 Days</h2>
<img src="30d.png" alt="graph 30 days" >
<h2>365 Days</h2>
<img src="365d.png" alt="graph 365 days" >

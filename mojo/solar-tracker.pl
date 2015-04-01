use Mojolicious::Lite;
use Mojo::JSON qw (decode_json);
use DateTime;
use RRDs;

# write to wherever specified
sub output ($){
        my $data = shift;

        # determine file to write to
        my $dt = DateTime->now;
        my $file_name = "../raw_data/".$dt->ymd;
        open my $fh, '>>', $file_name or die $!;
        say $fh $data;
}


get '/' => sub {
    my $c = shift;
    # render images

    for my $since (1, 5, 30, 365){
        say "rendering $since";
        RRDs::graph(
            "-N", "--start", "end-${since}d",
            "-w", 1000, "-h", 200,
            "public/${since}d.png",
            "DEF:solar=../rrd/solar.rrd:watt:AVERAGE",
            "AREA:solar#03bde9"
        );
    }

     $c->render(template=>'main');
};

post '/infeed' => sub {
	my $c = shift;

    my $body = decode_json $c->req->body;
    $body->{Body}{PAC}{Values}{1} =~ /(\d+)/;
    my $watts = $1;
    my $timestamp = time;
    say "$timestamp\t$watts";
    RRDs::update('../rrd/solar.rrd', "$timestamp:$watts");
    output time."\t$watts";

	$c->res->headers->content_type('application/json; charset=utf-8');
	$c->render(text => '{"reply":"ok"}');
};

app->start;

__DATA__

@@ main.html.ep

<h1>My Own Sunshine</h1>
<h2>1 Day</h2>
<img src="1d.png" alt="Bild 1 Tag" >
<h2>5 Days</h2>
<img src="5d.png" alt="Bild 5 Tage" >
<h2>30 Days</h2>
<img src="30d.png" alt="Bild 5 Tage" >
<h2>365 Days</h2>
<img src="365d.png" alt="Bild 5 Tage" >

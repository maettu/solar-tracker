use Mojolicious::Lite;
use Mojo::JSON qw (decode_json);
use DateTime;
use RRDs;

# write to wherever specified
sub output ($){
        my $data = shift;

        # determine file to write to
        my $dt = DateTime->now;
        my $file_name = "../raw_data/current_energy_log/".$dt->ymd;
        open my $fh, '>>', $file_name or die $!;
        say $fh $data;
}

sub write_totals (%){
    my %energies = @_;

    my $dt = DateTime->now;
    my $file_name = "../raw_data/totals_log/".$dt->ymd;

    # make sure only increasing values get written..
    open my $fh, '<', $file_name;
    my @totals = split  /\t/ , <$fh> // (0,0,0); # first time a day we get here..
    close $fh;
    if ($energies{DAY_ENERGY} > $totals[0]){
        open $fh, '>', $file_name or die $!;
        print $fh "$energies{DAY_ENERGY}\t$energies{YEAR_ENERGY}\t$energies{TOTAL_ENERGY}";
    }

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

    my $result = RRDs::info('../rrd/solar.rrd');
    my $current_energy = $result->{'ds[watt].last_ds'};

    my $dt = DateTime->now;
    my $file_name = "../raw_data/totals_log/".$dt->ymd;

    open my $fh, '<', $file_name;

    my @energies = split /\t/ , <$fh>;

    $c->render(
        template            => 'main',
        current_energy      => $current_energy, # $energies[1],
        day_energy          => $energies[0]/1000,
        year_energy         => $energies[1]/1_000_000,
        installation_energy => $energies[2]/1_000_000

    );
};

post '/infeed' => sub {
	my $c = shift;

    my $body = decode_json $c->req->body;
    $body->{Body}{PAC}{Values}{1} =~ /(\d+)/;
    my $watts = $1;

    my %energies;
    for my $energy ('DAY_ENERGY', 'YEAR_ENERGY', 'TOTAL_ENERGY'){
        $body->{Body}{$energy}{Values}{1} =~ /(\d+)/;
        $energies{$energy} = $1;
    }

    say "day total: $energies{DAY_ENERGY} WH";
    say "year total: $energies{YEAR_ENERGY} WH";
    say "installation total: $energies{TOTAL_ENERGY} WH";


    my $timestamp = time;
    say "$timestamp\t$watts";
    RRDs::update('../rrd/solar.rrd', "$timestamp:$watts");
    output time."\t$watts";

    write_totals %energies;

	$c->res->headers->content_type('application/json; charset=utf-8');
	$c->render(text => '{"reply":"ok"}');
};

app->start;

__DATA__

@@ main.html.ep

<h1>My Own Sunshine</h1>
<h2>Statistics</h2>
<p>Current Energy: <%= $current_energy %> W</p>
<p>Day Energy: <%= $day_energy %> KWH</p>
<p>Year Energy: <%= $year_energy %> MWH</p>
<p>Total Energy: <%= $installation_energy %> MWH</p>

<h2>1 Day</h2>
<img src="1d.png" alt="graph 1 day" >
<h2>5 Days</h2>
<img src="5d.png" alt="graph 5 days" >
<h2>30 Days</h2>
<img src="30d.png" alt="graph 30 days" >
<h2>365 Days</h2>
<img src="365d.png" alt="graph 365 days" >

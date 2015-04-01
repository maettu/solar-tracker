#!/usr/bin/perl
use Modern::Perl;


# initialise the rrd
my $rrd_create_stm =
'rrdtool create solar.rrd '.
'--start 1427443580 --step 60 '.
'DS:watt:GAUGE:10:0:7500 '.
'RRA:AVERAGE:0.5:6:10512000 '       # 20 years of 1 min points
;

`$rrd_create_stm`;

# if any, read in stored raw data

opendir my $dh, '../raw_data/' or die $!;
my @data_files = readdir($dh);

my $counter = 0;
my $insert_string = "";
for my $data_file (sort @data_files){
    say $data_file;
    open my $fh, '<', "../raw_data/$data_file" or die $!;
    while (<$fh>){
        $counter++;
        chomp;
        my ($timestamp, $watts) = split /\t/;
        $insert_string .= "$timestamp:$watts ";
        if ($counter % 100 == 0){
            say "$timestamp\t$watts";
            `rrdtool update test.rrd $insert_string`;
            $insert_string = "";
        }
    }
}

`rrdtool update test.rrd $insert_string` unless $insert_string eq "";


#!/usr/bin/env perl 

use warnings;

srand(10);
$| = 1;

sub numerically { $a <=> $b; }

sub print_header {
    my ($filehandle) = @_;
    print $filehandle "\n";
    print $filehandle "#----------------------------------#\n";
    print $filehandle "# mk_sc_data.pl # v0.10 # 01.09.18 #\n";
    print $filehandle "#----------------------------------#\n";
    print $filehandle "#      (c) Benjamin F. Voight      #\n";
    print $filehandle "#----------------------------------#\n";
    print $filehandle "\n";
}

sub print_string {
    my ($string, $out_fh, $log_fh) = @_;
    print $out_fh "$string";
    print $log_fh "$string";
}

sub check_file_exists {
    my ($file, $out_fh, $log_fh) = @_;
    my $myprint;

    stat($file);
    if ( !(-e _) ) {
        my $myprint = "ERROR: Can't locate " . $file . ".\n";
        print_string($myprint, $out_fh, $log_fh);
        exit();
    }
}

sub read_probtable {
    my ($ref_peakfile, $ref_peakdata, $out_fh, $log_fh) = @_;
    my ($readline, $peakid, $myprint, $npeaks);
    my @entry;

    open CHUNK, "<$ref_peakfile" or die "Can't open $ref_peakfile!\n";

    #get the header
    $readline = <CHUNK>; #header;
    chomp($readline);
    @entry = split '\s+', $readline;
    if (scalar(@entry) != 4) {
	$myprint = "Unexpected number of entries in " . $ref_peakfile . ".\n";
        print_string($myprint, $out_fh, $log_fh);
        exit();
    }

    #read the peaks and store as an array
    $npeaks = 0;
    while ($readline = <CHUNK>) {
        chomp($readline);
        @entry = split '\s+', $readline;
	if (scalar(@entry) != 4) {
	    $myprint = "Unexpected number of entries in " . $ref_peakfile . " at line $npeaks.\n";
	    print_string($myprint, $out_fh, $log_fh);
	    exit();
	}
	@{$$ref_peakdata{$entry[0]}} = ($entry[1], $entry[2], $entry[3]);	
	
	if ( ($entry[1]+$entry[2]+$entry[3]) != 1 ) {
	    $myprint = "Probabilities do not sum to one in " . $ref_peakfile . " at line $npeaks.\n";
            print_string($myprint, $out_fh, $log_fh);
            exit();
	}

	#print "$ref_peakdata{$entry[0]}[0] $ref_peakdata{$entry[0]}[1] $ref_peakdata{$entry[0]}[2]\n";

	$npeaks++;
    }
    close(CHUNK);
   
    $myprint = $npeaks . " peaks read from [ " . $ref_peakfile . " ]\n"; 
    print_string($myprint, $out_fh, $log_fh);
}

sub mk_mapfile {
    my ($ref_peakdata, $outfix, $out_fh, $log_fh) = @_;
    my ($peakid, $a, $b);
    my $pos = 1;

    open MAP, ">@{[$outfix]}.map" or die "Can't open @{[$outfix]}.map!\n";
    $myprint = "Outputting generic map file to [ " . $outfix . ".map ]\n";
    print_string($myprint, $out_fh, $log_fh);

    foreach $peakid (sort numerically keys %$ref_peakdata) {
        print MAP "1 $peakid 0 $pos\n";
        $pos += 1;
    }
    close(MAP);
}

sub print_to_pedfile {
    my ($ref_peakdata, $ped_fh, $outfix, $id, $out_fh, $log_fh) = @_;
    my ($peak, $this_acc_type);
    my $this_acc_type_prob = 0; 
    my $totalprob = 0;

    #print the initial string.
    print $ped_fh "$id $id 0 0 0 0";

    foreach $peak (sort {$a <=> $b} keys %$ref_peakdata) {
	$this_acc_type = 0;
	$total_prob = 0;
	$this_acc_type_prob = rand(); #determine the type.

	for (my $i=0; $i<scalar(@{$$ref_peakdata{$peak}}); $i++) {	    
	    $total_prob += $$ref_peakdata{$peak}[$i];
	    if ($this_acc_type_prob <= $total_prob) {
		$this_acc_type = $i;
		last;
	    }
	}

	#print "$this_acc_type_prob | $$ref_peakdata{$peak}[0] $$ref_peakdata{$peak}[1] $$ref_peakdata{$peak}[2] | $this_acc_type\n";

	if ($this_acc_type == 0) {
	    print $ped_fh " 1 1";
	} elsif ($this_acc_type == 1) {
	    print $ped_fh " 1 2";
	} elsif ($this_acc_type == 2) {
	    print $ped_fh " 2 2";
	} else {
	    $myprint = "Ack! Improper index for probabilities. $peak | $i\n";
	    print_string($myprint, $out_fh, $log_fh);
	    exit();
	}


    } #end all peaks

    print $ped_fh "\n";
}

sub print_to_famfile {
    my ($ref_peakdata, $fam_fh, $outfix, $id, $out_fh, $log_fh) = @_;
    print $fam_fh "$id $id 0 0 0 0\n";
}

if (scalar(@ARGV) == 3) {
    $num_cells = shift(@ARGV);
    $probtable = shift(@ARGV);
    $outfix = shift(@ARGV); 
} else {
    print "usage: %>mk_sc_data.pl n_cells probtable outfile\n";
    exit();
}

#open the log file and set output handles.
$mylog = LOG;
$myout = STDOUT;
$myfam = FAM;
$myped = PED;
open $mylog, ">@{[$outfix]}_sc-sim.log" or die "Error: Can't write logfile to @{[$outfix]}_sc-sim.log. Exiting!\n";

#print the header splash.
print_header($myout);
print_header($mylog);

$myprint = "Writing this text to log file [ " . $outfix . "_sc-sim.log ]\n";
print_string($myprint, $myout, $mylog);

#print start time.
$myprint = "Analysis started:\t" . scalar(localtime) . "\n\n";
print_string($myprint, $myout, $mylog);

#Read in prob table
check_file_exists($probtable);
read_probtable($probtable, \%peakdata, $myout, $mylog);

#create generic bim file
mk_mapfile(\%peakdata, $outfix, $myout, $mylog);

####################
#perform simulation

#First, create fam file
open $myfam, ">@{[$outfix]}.fam" or die "Can't open @{[$outfix]}.fam!\n";
$myprint = "Outputting generic fam file to [ " . $outfix . ".fam ]\n";
print_string($myprint, $myout, $mylog);

#Next, create the ped file
open $myped, ">@{[$outfix]}.ped" or die "Can't open @{[$outfix]}.ped!\n";
$myprint = "Outputting single cells to ped file [ " . $outfix . ".ped ]\n";
print_string($myprint, $myout, $mylog);

for ($i=0; $i<$num_cells; $i++) {
    #output fam data for this
    print_to_famfile(\%peakdata, $myfam, $outfix, $i, $myout, $mylog);

    #output ped file data
    print_to_pedfile(\%peakdata, $myped, $outfix, $i, $myout, $mylog);
}

#close file outputs.
close($myfam);
close($myped);

$myprint = "$i single cells outputted to [ " . $outfix . ".ped ]\n";
print_string($myprint, $myout, $mylog);

#convert ped to bed file.
$myprint = "Converting .ped, .map, .fam -> .bed, .bim, .fam via plink!\n";
print_string($myprint, $myout, $mylog);
system "plink --silent --noweb --ped @{[$outfix]}.ped --fam @{[$outfix]}.fam --map @{[$outfix]}.map --make-bed --out @{[$outfix]}";

#print output
$myprint = "\nSimulation finished:\t" . scalar(localtime). "\n";
print_string($myprint, $myout, $mylog);

#!/usr/bin/env perl 

use warnings;

srand(10);
$| = 1;

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
        $myprint = "ERROR: Can't locate " . $file . ".\n";
        print_string($myprint, $out_fh, $log_fh);
        exit();
    }
}

sub read_probtable {
    my ($peakfile, $ref_peakdata, $ref_peaklist, $out_fh, $log_fh) = @_;
    my ($readline, $peakid, $myprint, $npeaks);
    my @entry;

    open CHUNK, "<$peakfile" or die "Can't open $peakfile!\n";

    #get the header
    $readline = <CHUNK>; #header;
    chomp($readline);
    @entry = split '\s+', $readline;
    if (scalar(@entry) != 4) {
	$myprint = "Unexpected number of entries in " . $peakfile . ".\n";
        print_string($myprint, $out_fh, $log_fh);
        exit();
    }

    #read the peaks and store as an array
    $npeaks = 0;
    while ($readline = <CHUNK>) {
        chomp($readline);
        @entry = split '\s+', $readline;
	if (scalar(@entry) != 4) {
	    $myprint = "Unexpected number of entries in " . $peakfile . " at line $npeaks.\n";
	    print_string($myprint, $out_fh, $log_fh);
	    exit();
	}
	
	#store the list of peaks in the order listed in the file. 
	push @$ref_peaklist, $entry[0];

	@{$$ref_peakdata{$entry[0]}} = ($entry[1], $entry[2], $entry[3]);	
	
	### should have a better check for summing to 1
#	if ( ($entry[1]+$entry[2]+$entry[3]) != 1 ) {
#	    $myprint = "Probabilities do not sum to one in " . $peakfile . " at line $npeaks.\n";
#            print_string($myprint, $out_fh, $log_fh);
#            exit();
#	}

	#print "$ref_peakdata{$entry[0]}[0] $ref_peakdata{$entry[0]}[1] $ref_peakdata{$entry[0]}[2]\n";

	$npeaks++;
    }
    close(CHUNK);
   
    $myprint = $npeaks . " peaks read from [ " . $peakfile . " ]\n"; 
    print_string($myprint, $out_fh, $log_fh);
}

sub read_admixtable {
    my ($admixfile, $ref_admixdata, $num_pops, $out_fh, $log_fh) = @_;
    my $ind = 0;
    my @entry;
    my $totalprob;
    my $line;

    open CHUNK, "<$admixfile" or die "Can't open $admixfile!\n";

    while ($readline = <CHUNK>) {
	chomp($readline);
	@entry = split '\s+', $readline;
	if (scalar(@entry) != $num_pops) {
	    $myprint = "Unexpected number of entries in " . $admixfile . ", expecting $num_pops.\n";
	    print_string($myprint, $out_fh, $log_fh);
	    exit();
	}

	#probably worth a check here if admix proportions sum to one
	$totalprob = 0;
	for (my $i=0; $i<scalar(@entry); $i++) {
	    $totalprob += $entry[$i];
	}

	if ($totalprob != 1) {
	    $line += $ind+1;
	    $myprint = "Total ancestry proportions do not =1 (=$totalprob) in line $line from [ " . $admixfile . " ]\n"; 
	    print_string($myprint, $out_fh, $log_fh);
	    exit();
	}

	@{$$ref_admixdata{$ind}} = @entry;
	$ind++;
    }
    close(CHUNK);

    $myprint = $ind . " individuals read from [ " . $admixfile . " ]\n"; 
    print_string($myprint, $out_fh, $log_fh);
}

sub mk_mapfile {
    my ($ref_peaklist, $outfix, $out_fh, $log_fh) = @_;
    my ($peakid, $a, $b);
    my $pos = 1;

    open MAP, ">@{[$outfix]}.map" or die "Can't open @{[$outfix]}.map!\n";
    $myprint = "Outputting generic map file to [ " . $outfix . ".map ]\n";
    print_string($myprint, $out_fh, $log_fh);

    foreach $peakid (@$ref_peaklist) {
        print MAP "1 $peakid 0 $pos\n";
        $pos += 1;
    }
    close(MAP);
}

sub print_to_pedfile {
    my ($ref_peakdata, $ref_peaklist, $ped_fh, $outfix, $id, $out_fh, $log_fh) = @_;
    my ($peak, $this_acc_type);
    my $this_acc_type_prob = 0; 
    my $totalprob = 0;

    #print the initial string.
    print $ped_fh "$id $id 0 0 0 0";

    foreach $peak (@$ref_peaklist) {
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

sub print_admix_to_pedfile {
    my ($ref_peakdata_list, $ref_peaklist, $ref_admixdata, $ped_fh, $outfix, $id, $out_fh, $log_fh) = @_;
    my ($peak, $this_acc_type);
    my $this_acc_type_prob = 0; 
    my $this_pop = 0;
    my $this_pop_prob;
    my $total_prob = 0;
    my $ref_peakdata;

    #print the initial string.
    print $ped_fh "$id $id 0 0 0 0";

    foreach $peak (@$ref_peaklist) {
	$total_prob = 0;
	$this_acc_type = 0;
	$this_pop = 0;
	$this_acc_type_prob = rand(); #determine the type.
	$this_pop_prob = rand(); #determine pop for mixture.

	for (my $i=0; $i<scalar(@{$$ref_admixdata{$id}}); $i++) {
	    $total_prob += $$ref_admixdata{$id}[$i];
	    if ($this_pop_prob <= $total_prob) {
		$this_pop = $i;
		last;
	    }
	}

	#assign this reference to the population selected
	$ref_peakdata = \%{$$ref_peakdata_list[$this_pop]};

	#print "Pop: $this_pop_prob | $$ref_admixdata{$id}[0] $$ref_admixdata{$id}[1] | $this_pop\n";
	#print "$$ref_peakdata_list[$this_pop]{chr10_100486810_100487687_MACS_peak_4138}[0]\n";
	
	$total_prob = 0; #re-initialize.
	for (my $i=0; $i<scalar(@{$$ref_peakdata{$peak}}); $i++) {
	    $total_prob += $$ref_peakdata{$peak}[$i];
	    if ($this_acc_type_prob <= $total_prob) {
		$this_acc_type = $i;
		last;
	    }
	}

	#print "Peak $peak: $this_acc_type_prob | $$ref_peakdata{$peak}[0] $$ref_peakdata{$peak}[1] $$ref_peakdata{$peak}[2] | $this_acc_type\n";

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

if (scalar(@ARGV) >= 4) {
    $num_cells = shift(@ARGV);
    $outfix = shift(@ARGV); 
    
    $flag = shift(@ARGV);
    if ($flag =~ /-n/) {
        push @probtables, shift(@ARGV);
    } else {
	$admixtable = shift(@ARGV);
    }

} else {
    print "usage: %>mk_sc_data.pl n_cells outfile [-a admix_tbl probtbl1 ... probtbln | -n probtbl]\n";
    exit();
}

#open the log file and set output handles.
$mylog = LOG;
$myout = STDOUT;
$myfam = FAM;
$myped = PED;

@mypeaklist = ();

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
if ($flag =~ m/-n/) {
    $myprint = "Single population (non-admixed) mode engaged.\n";
    print_string($myprint, $myout, $mylog);

    check_file_exists($probtables[0], $myout, $mylog);
    read_probtable($probtables[0], \%peakdata, \@mypeaklist, $myout, $mylog);
        
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
	print_to_pedfile(\%peakdata, \@mypeaklist, $myped, $outfix, $i, $myout, $mylog);
    }
    
    #close file outputs.
    close($myfam);
    close($myped);
    
    $myprint = "$i single cells outputted to [ " . $outfix . ".ped ]\n";
    print_string($myprint, $myout, $mylog);
} elsif ($flag =~ /-a/) {
    $myprint = "Admixed population mode engaged.\n";
    print_string($myprint, $myout, $mylog);
    
    #get a list of prob files and associated mixtures.
    $npops = 0;
    while (scalar(@ARGV) != 0) {
	$this_probfile = shift(@ARGV);	
	push @probtables, $this_probfile;
	push @peakdata_list, {};
	$npops++;
    }
    
    $myprint = "$npops with various admixture proportions selected.\n";
    print_string($myprint, $myout, $mylog);

    #read admixture file
    check_file_exists($admixtable, $myout, $mylog);
    read_admixtable($admixtable, \%admixdata, $npops, $myout, $mylog);
    
    #read probabilities
    for ($i=0; $i<scalar(@probtables); $i++) {
	check_file_exists($probtables[$i], $myout, $mylog);
	read_probtable($probtables[$i], \%{$peakdata_list[$i]}, \@mypeaklist, $myout, $mylog);
    }

    #print "$peakdata_list[1]{chr10_100486810_100487687_MACS_peak_4138}[0]\n";

    #Probably worth checks: # of peaks, the peak names are the same (cross reference)
    #for now, I'm going to ignore this part.

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

    for ($i=0; $i<scalar(keys %admixdata); $i++) {
	#output fam data for this
	print_to_famfile(\%{$peakdata_list[0]}, $myfam, $outfix, $i, $myout, $mylog);
	#output admixed sample to ped file
	print_admix_to_pedfile(\@peakdata_list, \@mypeaklist, \%admixdata, $myped, $outfix, $i, $myout, $mylog);
    }
    
    #close file outputs.
    close($myfam);
    close($myped);
    
    $myprint = "$i single cells outputted to [ " . $outfix . ".ped ]\n";
    print_string($myprint, $myout, $mylog);
}
 
#Finally, create generic map file
mk_mapfile(\@mypeaklist, $outfix, $myout, $mylog);

#convert ped to bed file.
$myprint = "Converting .ped, .map, .fam -> .bed, .bim, .fam via plink!\n";
print_string($myprint, $myout, $mylog);
system "plink --silent --noweb --ped @{[$outfix]}.ped --fam @{[$outfix]}.fam --map @{[$outfix]}.map --make-bed --out @{[$outfix]}";

#print output
$myprint = "\nSimulation finished:\t" . scalar(localtime). "\n";
print_string($myprint, $myout, $mylog);

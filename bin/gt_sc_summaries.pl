#!/usr/bin/perl

use warnings;

use constant THRESHOLD => 0.99;

if (scalar(@ARGV) == 3) {
    $nsims = shift(@ARGV);
    $num_nonadmixed = shift(@ARGV);
    $admix_table = shift(@ARGV);
} else {
    print "usage: %>./get_sc_summaries.pl nsims num_nonadmixed admix_table\n";
    exit();
}

for ($i=1; $i<=$nsims; $i++) {
    $irrel = 0;
    @K = ();
    @assignment = ();

    #get frequency K=2 is selected
    open IN, "<sim_@{[$i]}/sim_@{[$i]}_out_K" or die;
    $rl= <IN>;
    chomp($rl);
    $rl =~ m/Model complexity that maximizes marginal likelihood = (\d+)/;
    $irrel = $1;
    push @K, $irrel;
    close(IN);

    #get assignment probs
    open IN, "<sim_@{[$i]}/sim_@{[$i]}_out.2.meanQ" or die;
    open ADMIX, "<$admix_table" or die;

    #read in non-admixed first.
    for($j=0; $j<$num_nonadmixed; $j++) {
	$rl = <IN>;
	chomp($rl);
	$irrel = <ADMIX>;
	@e = split '\s+', $rl;

	#get the population label sorted
	if ($j == 0) {
	    if ($e[0] >= 0.9) {
		$pop_a = 0;
	    } else {
		$pop_a = 1;
	    }

	    #print ":: $pop_a ::\n";
	}

	#doesn't worry about order
	if ($e[0] >= THRESHOLD) {
	    $nadmix_correct = 1;	    
	} elsif ($e[1] >= THRESHOLD) {
	    $nadmix_correct = 1;
	} else {
	    $nadmix_correct = 0;
	}

	push @assignment, $nadmix_correct;
    }

    
    #read in admixed next
    @diff = ();
    while ($rl = <ADMIX>) {
	chomp($rl);
	$q = <IN>;
	chomp($q);
	@act_q = split '\s+', $q;
	@inf_q = split '\s+', $rl;
	#print ":: $act_q[1] :: $inf_q[$pop_a]\n";
	push @diff, ($act_q[1] - $inf_q[$pop_a])**2;	
    }
    close(ADMIX);
    close(IN);
    
    #summaries
    $total = 0;
    foreach $k (@K) {
	if ($k == 2) {
	    $total++;
	}
    }

    $freq = $total/scalar(@K);

    $total = 0;
    foreach $val (@assignment) {
	$total += $val;
    }
    $mean_assign = sprintf("%1.3g", $total/scalar(@assignment));

    if (scalar(@diff) > 0) {
	$total = 0;
	foreach $val (@diff) {
	    $total += $val;
	}
	$mean_admix = sprintf("%1.4g", $total/scalar(@diff));
    } else {
	$mean_admix = ".";
    }

    print "$i $freq $mean_assign $mean_admix\n";
}

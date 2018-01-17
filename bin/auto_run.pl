#!/usr/bin/perl -w

$| = 1;

if (scalar(@ARGV) == 3) {
    $nsims = shift(@ARGV);
    $ncells = shift(@ARGV);
    $admixtable = shift(@ARGV);
} else {
    print "Usage: %>./auto_run.pl nsims ncells admix_table\n";
    exit();
}

for ($i=1; $i<$nsims; $i++) {
    print "Running simulation $i\n";

    print "mkdir sim_@{[$i]}\n";
    system "mkdir sim_@{[$i]}";

    #run make samples
    print "./mk_sc_data.pl $ncells sim_@{[$i]}/sim_@{[$i]} -a $admixtable data/DP_T_probs_sorted_forsim.txt data/EML_T_probs_sorted_forsim.txt\n";
    system "./mk_sc_data.pl $ncells sim_@{[$i]}/sim_@{[$i]} -a $admixtable data/DP_T_probs_sorted_forsim.txt data/EML_T_probs_sorted_forsim.txt";
    
    #structure runs
    print "python ~/bin/fastStructure/structure.py -K 1 --input=sim_@{[$i]}/sim_@{[$i]} --output=sim_@{[$i]}/sim_@{[$i]}_out --full\n";
    system "python ~/bin/fastStructure/structure.py -K 1 --input=sim_@{[$i]}/sim_@{[$i]} --output=sim_@{[$i]}/sim_@{[$i]}_out --full";

    print "python ~/bin/fastStructure/structure.py -K 2 --input=sim_@{[$i]}/sim_@{[$i]} --output=sim_@{[$i]}/sim_@{[$i]}_out --full\n";
    system "python ~/bin/fastStructure/structure.py -K 2 --input=sim_@{[$i]}/sim_@{[$i]} --output=sim_@{[$i]}/sim_@{[$i]}_out --full";

    print "python ~/bin/fastStructure/structure.py -K 3 --input=sim_@{[$i]}/sim_@{[$i]} --output=sim_@{[$i]}/sim_@{[$i]}_out --full\n";
    system "python ~/bin/fastStructure/structure.py -K 3 --input=sim_@{[$i]}/sim_@{[$i]} --output=sim_@{[$i]}/sim_@{[$i]}_out --full";


    #choose K
    print "python ~/bin/fastStructure/chooseK.py --input=sim_@{[$i]}/sim_@{[$i]}_out >sim_@{[$i]}/sim_@{[$i]}_out_K\n";
    system "python ~/bin/fastStructure/chooseK.py --input=sim_@{[$i]}/sim_@{[$i]}_out >sim_@{[$i]}/sim_@{[$i]}_out_K";

    #run distruct with K=2
    print "python ~/bin/fastStructure/distruct.py -K 2 --input=sim_@{[$i]}/sim_@{[$i]}_out --output=sim_@{[$i]}/sim_@{[$i]}_out_distruct.svg\n";
    system "python ~/bin/fastStructure/distruct.py -K 2 --input=sim_@{[$i]}/sim_@{[$i]}_out --output=sim_@{[$i]}/sim_@{[$i]}_out_distruct.svg";

}

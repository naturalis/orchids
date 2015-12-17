#!/bin/bash
# Usage: ./phyml.sh

FAMILIES="A_E_AE AP3_PI C_D"
INPUT=data/selection/2015-12-15
OUTPUT=data/genetrees/2015-12-11

# iterate over gene families (local folder names)
for FAM in $FAMILIES; do

	# convert codon alignment to phylip for phyml
	perl script/fasta2phylip.pl $INPUT/$FAM/codon.aln.fasta > $OUTPUT/$FAM/codon.aln.phy

	# nt        = nucleotide
	# -f e      = estimate base frequencies
	# --ts/tv e = estimate transition/transversion ratio
	# --pinv e  = estimate proportion of invariant sites
	# --alpha e = estimate gamma distribution shape parameter
	# --search BEST = best topology search result from among NNI and SPR
	rm $OUTPUT/$FAM/codon.aln.phy_phyml_tree.txt
	rm $OUTPUT/$FAM/codon.aln.phy_phyml_stats.txt
	phyml --input $OUTPUT/$FAM/codon.aln.phy --pars --datatype nt --sequential --model GTR -f m --ts/tv e --pinv e --alpha e --search BEST --nclasses 6 --quiet

done
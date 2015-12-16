#!/bin/bash
# Usage: ./phyml.sh input.phy

FAMILIES="A_E_AE AP3_PI C_D"
DATA=data/selection/2015-10-15/

for FAM in $FAMILIES; do

	# convert codon alignment to phylip for phyml
	perl script/fasta2phylip.pl $DATA/$FAM/codon.aln.fasta > $DATA/$FAM/codon.aln.phy

	# nt        = nucleotide
	# -f e      = estimate base frequencies
	# --ts/tv e = estimate transition/transversion ratio
	# --pinv e  = estimate proportion of invariant sites
	# --alpha e = estimate gamma distribution shape parameter
	# --search BEST = best topology search result from among NNI and SPR
	phyml --input $DATA/$FAM/codon.aln.phy --datatype nt --sequential --model GTR -f e --ts/tv e --pinv e --alpha e --search BEST --quiet

done
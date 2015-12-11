#!/bin/bash
FAMILIES="AP3_PI A_E_AE C_D"
INPUT=data/selection/2015-10-15
OUTPUT=data/genetrees/2015-12-11

for FAMILY in $FAMILIES; do
	perl script/fasta2nexus.pl $INPUT/$FAMILY/codon.aln.fasta > $OUTPUT/$FAMILY/codon.aln.nex
	cd $OUTPUT/$FAMILY
	mb codon.aln.nex
	cd -
done
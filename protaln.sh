#!/bin/bash

DATA=data/selection/2015-10-15
FASTAS=`ls $DATA/*.fasta`
SCRIPT="perl script"

# iterate over alignments
for FASTA in $FASTAS; do

	# unalign nucleotide alignments
	$SCRIPT/unalign.pl -f fasta -t dna -i $FASTA > ${FASTA}.cds
	
	# translate nucleotide to aa
	$SCRIPT/nuc2aa.pl -f fasta -t dna -i ${FASTA}.cds -v -no_fetch >> ${DATA}/aa.fasta
	
	# append nucleotide 
	cat ${FASTA}.cds >> ${DATA}/codon.fasta
	rm ${FASTA}.cds
	
done

# align amino acids
# http://mafft.cbrc.jp/alignment/software/algorithms/algorithms.html#GLE
unset MAFFT_BINARIES
mafft --genafpair --maxiterate 1000 ${DATA}/aa.fasta > ${DATA}/aa.aln.fasta

# reconcile codons with amino acids
$SCRIPT/protalign.pl ${DATA}/codon.fasta ${DATA}/aa.aln.fasta > ${DATA}/codon.aln.fasta
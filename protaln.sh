#!/bin/bash

# first argument needs to be a folder containing FASTA files to merge and protalign
DATA=$1
if [ ! -d "$DATA" ]; then
	echo "Need data directory as command line argument"
	exit 1
fi

# list all alignments in data folder
FASTAS=`ls $DATA/*.fasta`

# shorthand
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
mafft --oldgenafpair --maxiterate 1000 ${DATA}/aa.fasta > ${DATA}/aa.aln.fasta

# reconcile codons with amino acids
$SCRIPT/protalign.pl ${DATA}/codon.fasta ${DATA}/aa.aln.fasta > ${DATA}/codon.aln.fasta
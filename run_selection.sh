#!/bin/bash

# unalign the old alignment, we will replace this with a protein-guided one
perl script/unalign.pl --infile=$1 --type=dna --format=fasta > ${1}.unaligned

# protein translate the unaligned version
perl script/nuc2aa.pl --infile=${1}.unaligned --type=dna --format=fasta > ${1}.unaligned.prot

# align the protein file
muscle < ${1}.unaligned.prot > ${1}.aligned.prot

# align the unaligned dna to the protein alignment
perl script/protalign.pl ${1}.unaligned ${1}.aligned.prot > ${1}.aligned.nuc

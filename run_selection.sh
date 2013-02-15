#!/bin/bash

# unalign the old alignment, we will replace this with a protein-guided one
perl script/unalign.pl -i $1 -t dna -f fasta > ${1}.unaligned

# protein translate the unaligned version
perl script/nuc2aa.pl -i ${1}.unaligned > ${1}.unaligned.prot

# align the protein file

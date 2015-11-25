#!/bin/bash
DATA=data/selection/2015-10-15
NAMES=data/speciestree/names.txt

if [ ! -e "$NAMES" ]; then
	files=`find $DATA -name "codon.aln.fasta"`
	cat $files | grep '>' | cut -f 1,2 -d '_' | sort | uniq | sed -e 's/>//' > $NAMES
fi

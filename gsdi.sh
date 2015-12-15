#!/bin/bash
JAR=bin/forester_1038.jar
SPECIESTREE=data/speciestree/cladogram
GENETREES=data/genetrees/2015-12-11/
FAMILIES="AP3_PI A_E_AE C_D"

# https://sites.google.com/site/cmzmasek/home/software/forester/gsdi
GSDI="java -Xmx1024m -cp $JAR org.forester.application.gsdi -g"

# iterate over families
for FAM in $FAMILIES; do

	# generate input files
	G=$GENETREES/$FAM/codon.aln.nex.con
#	if [ ! -e $SPECIESTREE.xml ]; then
		perl script/make_phyloxml.pl -g $G.tre -s $SPECIESTREE.dnd -o $SPECIESTREE.xml -v > $G.xml
#	else
#		perl script/make_phyloxml.pl -g $G.tre -v > $G.xml
#	fi

	# run GSDI
	$GSDI $G.xml $SPECIESTREE.xml $G.gsdi.xml

done
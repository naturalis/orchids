#!/bin/bash
JAR=bin/forester_1038.jar
SPECIESTREE=data/speciestree/cladogram
GENETREES=data/genetrees/2015-12-11/
ALIGNMENTS=data/selection/2015-12-15/
FAMILIES="AP3_PI A_E_AE C_D"

# https://sites.google.com/site/cmzmasek/home/software/forester/gsdi
GSDI="java -Xmx1024m -cp $JAR org.forester.application.gsdi -g"

# script to prepare input data. the $SPECIESTREE arguments are optional and a bit
# redundant because the same species tree is generated each time, but this also 
# triggers a check to make sure all species in the gene tree are present in the 
# species tree
PHYLOXML="perl script/make_phyloxml.pl -f newick -s $SPECIESTREE.dnd -o $SPECIESTREE.xml"

# iterate over families
for FAM in $FAMILIES; do

	# generate input files
	G=$GENETREES/$FAM/codon.aln.phy_phyml_tree
	$PHYLOXML -g $G.txt -a $ALIGNMENTS/$FAM/codon.aln.fasta -v > $G.xml

	# run GSDI
	rm ${G}.gsdi_gsdi_log.txt ${G}.gsdi_species_tree_used.xml
	$GSDI $G.xml $SPECIESTREE.xml $G.gsdi.xml

done
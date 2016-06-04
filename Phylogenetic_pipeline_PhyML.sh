#!/bin/bash

# Additional information:
# =======================
#
# 
#
# Just type /bin/bash Phylogenetic_Analysis and the pipeline starts.
#

# Show usage information:
if [ "$1" == "--h" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ "$1" == "-help" ]
then
	echo "" 
	echo "Dependencies:"
	echo ""
	echo "nano .bash_profile"
	echo "Add export PERL5LIB=\$PERL5LIB:/Users/username/supersmart/lib:/Users/janwillem/bio-phylo/lib without quotes to .bash_profile"
	echo "Add export SUPERSMART_HOME=/Users/username/supersmart without quotes to .bash_profile"
	echo ""
	echo "sudo apt-get install git"
	echo ""
	echo "git clone https://github.com/naturalis/supersmart.git"
	echo ""
	echo "sudo apt-get install cpan"
	echo ""
	echo "When youre into cpan, then install following applications:" 
	echo "install CJFIELDS/BioPerl-1.6.924.tar.gz"  
	echo "install Parallel::ForkManager"
	echo "install Config::Tiny"
	echo "install DBIx::Class"
	echo "install Moose"
	echo "install List::MoreUtils"
	echo "install LWP::UserAgent"
	echo "install URI::Escape"
	echo "install JSON"
	echo ""
	echo "Now youre good to go!"
	echo ""
	echo ""
	echo "Way of usage:" 
	echo "" 
	echo "The user can use this script for starting the phylogenetic-pipeline."
	echo "Read the full manual below:"
	echo "http://dx.doi.org/10.5281/zenodo.44533"
	echo ""
	echo "Example:" 
	echo ""
	echo "/bin/bash Phylogenetic_pipeline_Datamonkey_input.sh"
	echo ""
	
	exit  
fi

# first argument needs to be a folder containing FASTA files to merge and protalign
#FAMILIES="AP3_PI A_E_AE C_D"           #Gene families (Foldernames)
FAMILIES="A_FUL"
JAR=bin/forester_1038.jar              #Archeopteryx 
SPECIESTREE=data/speciestree/2016-6-1 #species tree
ALIGNMENTS=data/selection/2015-12-15   #fasta and alignment files
GENETREES=data/genetrees/2015-12-11    #gene lineage trees

#for FAM in $FAMILIES; do
#
#/bin/bash protaln.sh $ALIGNMENTS/$FAM/
#
#done

# iterate over gene families
#for FAM in $FAMILIES; do
#
#	# convert fasta file to relaxed phylip file
#	perl script/fasta2phylip.pl $ALIGNMENTS/$FAM/codon.aln.fasta > $GENETREES/$FAM/codon.aln.phy
#
#	# nt        = nucleotide
#	# -f e      = estimate base frequencies
#	# --ts/tv e = estimate transition/transversion ratio
#	# --pinv e  = estimate proportion of invariant sites
#	# --alpha e = estimate gamma distribution shape parameter
#	# --search BEST = best topology search result from among NNI and SPR
#	rm $GENETREES/$FAM/codon.aln.phy_phyml_tree.txt
#	rm $GENETREES/$FAM/codon.aln.phy_phyml_stats.txt
#	phyml --input $GENETREES/$FAM/codon.aln.phy --pars --datatype nt --sequential --model GTR -f m --ts/tv e --pinv e --alpha e --search BEST --nclasses 6 --quiet
#
#done

# https://sites.google.com/site/cmzmasek/home/software/forester/gsdi
GSDI="java -Xmx1024m -cp $JAR org.forester.application.gsdi -g"

# script to prepare input data. the $SPECIESTREE arguments are optional and a bit
# redundant because the same species tree is generated each time, but this also 
# triggers a check to make sure all species in the gene tree are present in the 
# species tree


# iterate over families
for FAM in $FAMILIES; do

	PHYLOXML="perl script/make_phyloxml.pl -f newick -s $SPECIESTREE/$FAM/cladogram.dnd -o $SPECIESTREE/$FAM/cladogram.xml"

	G=$GENETREES/$FAM/codon.aln.phy_phyml_tree
	
	# convert nexus/figtree dialect to newick, 
	# including support values as internal node labels
	# XXX This step requires that the $FAM folder contains a simple text file that 
	# contains the accession numbers of the outgroup taxa, one number per line.
	perl script/make_newick.pl -o $GENETREES/$FAM/outgroups.txt -f newick -i $G.txt --verbose > $G.dnd
	
	# generate input files
	$PHYLOXML -g $G.dnd -a $ALIGNMENTS/$FAM/codon.aln.fasta -v > $G.xml

	# run GSDI
	rm $G.gsdi_gsdi_log.txt $G.gsdi_species_tree_used.xml $G.gsdi.xml
	$GSDI $G.xml $SPECIESTREE/$FAM/cladogram.xml $G.gsdi.xml

done

# Iterate over families and create .nex-files as intput for Datamonkey
for FAM in $FAMILIES; do

	perl script/make_nexus.pl --treefile $GENETREES/$FAM/codon.aln.phy_phyml_tree.txt --phyloformat newick --matrixfile $GENETREES/$FAM/codon.aln.phy --dataformat phylip > $GENETREES/$FAM/outfile_$FAM.nex

done

#!/bin/bash

HYPHYDIR=data/HyPhy
GSDIDIR=data/genetrees/2015-12-11
OUTDIR=data/viz/2016-08-4
GENES=genes.tsv
SCRIPT='perl script'

# parse distinct upload IDs from files in directory
UPLOADS=$(ls $HYPHYDIR | grep 'upload' | cut -f 1 -d '_' | sort | uniq)

# do a generic merge of datamonkey CSV and NEXUS, produces NeXML
for U in $UPLOADS; do
	CSV=$(ls $HYPHYDIR/$U*csv)
	NEX=$(ls $HYPHYDIR/$U*nex)
	
	# parse gene family name from NEXUS file (note: non-standard naming)
	FAM=$(echo $NEX | sed -e 's/.*_bsr_//' | sed -e 's/.nex//')
	XML=$OUTDIR/$FAM.xml
	$SCRIPT/parse_datamonkey.pl -n $NEX -c $CSV -v > $XML
done

# iterate over NeXML files from previous loop
for XML in $(ls $OUTDIR/*.xml); do
	FAM=$(echo $XML | sed -e 's/.xml//' | sed -e 's/.*\///')
	PHY=$GSDIDIR/$FAM/codon.aln.phy_phyml_tree.gsdi_full_names.xml
	SVG=$OUTDIR/$FAM.svg
	
	# do the visualization
	$SCRIPT/draw_gsdi_bsr.pl -p $PHY -n $XML -g $GENES -v > $SVG
done

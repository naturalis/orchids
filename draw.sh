#!/bin/bash

HYPHYDIR=data/HyPhy
GSDIDIR=data/genetrees/2015-12-11
OUTDIR=data/viz/2016-01-06
SCRIPT='perl script'

# parse distinct upload IDs from files in directory
UPLOADS=$(ls $HYPHYDIR | egrep 'upload\.\d+' | cut -f 1 -d '_' | sort | uniq);

# do a generic merge of datamonkey CSV and NEXUS, produces NeXML
for U in $UPLOADS; do
	CSV=$(ls $HYPHYDIR/$U*csv)
	NEX=$(ls $HYPHYDIR/$U*nex)
	
	# parse gene family name from NEXUS file (note: non-standard naming)
	FAM=$(echo $NEX | sed -e 's/.*_bsr_//' | sed -e 's/.nex//')
	XML=$OUTDIR/$FAM.xml
	$SCRIPT/parse_datamonkey.pl -n $NEX -c $CSV > $XML
done
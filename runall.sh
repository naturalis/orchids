#!/bin/bash
DATA=data
RESULTS=results
SCRIPT=script
PERL=perl
TAXON=Polymeres
COLOR=silver
INFILE=$DATA/Bulbophyllinae.tre
OUTFILE=$RESULTS/Bulbophyllinae.svg
SECTIONS=$DATA/secties.txt

$PERL $SCRIPT/printtrees.pl -i $INFILE -f nexus -t $TAXON:$COLOR -s $SECTIONS -o $OUTFILE

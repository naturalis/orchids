#!/bin/bash
DATA=data/viz
RESULTS=results/viz
SCRIPT=script
PERL=perl
INFILE=$DATA/Bulbophyllinae.tre
OUTFILE=$RESULTS/Bulbophyllinae.svg

$PERL $SCRIPT/printtrees.pl -i $INFILE -f nexus -t Polymeres:silver > $OUTFILE

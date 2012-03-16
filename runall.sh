#!/bin/bash
DATA=data
RESULTS=results
SCRIPT=script
PERL=perl
TAXA="-t Polymeres:silver -t SestochilusStenochilus:red"
INFILE=$DATA/Bulbophyllinae.tre
OUTFILE=$RESULTS/Bulbophyllinae.svg
SECTIONS=$DATA/secties.txt

$PERL $SCRIPT/printtrees.pl -i $INFILE -f nexus $TAXA -s $SECTIONS -o $OUTFILE

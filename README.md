What is this?
-------------

This repository contains scripts and data to analyze the evolution of the [MADS box gene
family](genes.tsv) in orchids (with special attention to the occurrence and expression of 
these genes in *Erycina pusilla*).

The basic outline of the workflow enabled by these scripts is as follows:

## Merging and aligning

The raw data files are FASTA files for each gene class. These should be merged in various
combinations and then be aligned as codon alignments (i.e. exactly in-frame).  To this end
the set of files to be merged should be placed in a single folder, which is provided as
the argument for the shell script [protaln.sh](protaln.sh). This shell script unaligns any
previous alignment that's been applied to these files ([script/unalign.pl](script/unalign.pl)) and translates
them to amino acid ([script/nuc2aa.pl](script/nuc2aa.pl)). 

For this to be successful it is essential that the unaligned sequences translate exactly 
right without frame shifts. The sequences should start with the ORF (technically this is 
not a hard requirement as long as the sequences are in-frame). The stop codon must be 
omitted!

Subsequently, both the unaligned nucleotide sequences and the amino acid sequences are 
concatenated. The amino acid sequences are then aligned using MAFFT, using the algorithm
that is recommended for proteins with multiple conserved domains. The nucleotide sequences
are then reconciled with this amino acid alignment ([script/protalign.pl](script/protalign.pl)).

## Phylogenetic inference
<!--
### Old approach
-->

To build trees for the codon alignments we use PhyML. This requires PHYLIP format 
input, which is created from the FASTA files. 
Because PHYLIP format requires that sequence names are no longer than 10 characters we need to 
have some string that is guaranteed to be distinct for each sequence. For this we use the genbank
accession number, which is expected to be the last string in the FASTA definition line,
preceded by an underscore ('_').

The PHYLIP files are created and analyzed with PhyML using a shell script that has the search
parameters embedded in it ([phyml.sh](phyml.sh), which internally calls 
([a file conversion script](script/fasta2phylip.pl))). Inference goes very fast, at most a few
minutes.

## speciation/duplication inference

There have been duplications within [certain MADS classes](genes.tsv). It would be very
strong if we had an objective, tree-based inference of where these duplications occurred
so that we can identify which sequences are orthologous with respect to each other, and
which are paralogous. Given that the [species tree](data/speciestree/cladogram.dnd) is
relatively uncontroversial we should be able to class nodes in the gene trees as either
speciations or duplications, using the 
[(g)SDI algorithm](http://bioinformatics.oxfordjournals.org/content/17/9/821.abstract).

This requires the preparation of the right input files, in [phyloxml](http://phyloxml.org)
syntax. These files need to have unambiguous tags that identify to which species a sequence
belongs. This is done by a [conversion script](script/make_phyloxml.pl), which is called
by a [shell script](gsdi.sh) which invokes the [forester jar](bin/forester_1038.jar) to
run GSDI and produce annotated output tree files that have the inferred duplications
embedded in them.

<!--
### New approach

In order to obtain support values in the form of posterior probabilities we infer the gene
lineage trees using [MrBayes](http://mrbayes.sourceforge.net/). To this end there is a
shell script [genetrees.sh](genetrees.sh) that does the following:

1. convert the codon.aln.fasta files to the input that MrBayes accepts, which is NEXUS. This
   is done by invoking [script/fasta2nexus.pl](script/fasta2nexus.pl). This will produce
   NEXUS files with a taxa block and a characters block, where taxa and character rows are
   named after the accession numbers that are the last word in the FASTA definition lines.
   Also a simple mrbayes command block is appended. 
2. run mrbayes inside the right folders with data files. If there are results from previous
   runs, these probably need to be removed first so that mrbayes doesn't get confused.
-->

## dN/dS analysis

We analyze branch specific variation in dN/dS ratios using the 
[BranchSiteREL](http://mbe.oxfordjournals.org/content/early/2011/06/11/molbev.msr125.abstract) 
algorithm of HyPhy, as made available on the [datamonkey.org](http://datamonkey.org/) cluster. 
To this end we must create a NEXUS file that has both the codon alignment and the gene 
tree embedded in it. We create this from the phylip input file for phyml and the resulting 
tree file ([script/make_nexus.pl](script/make_nexus.pl)).

Subsequently, we upload the produced NEXUS file and click through the datamonkey wizard
for a BranchSiteREL analysis with the user-provided tree and the universal genetic code:

- go to http://datamonkey.org/dataupload.php
- upload the NEXUS file (datatype: codon, genetic code: universal)
- click the button "Proceed to the analysis menu"
- select "Branch-site REL" from the pulldown menu, click "User Tree(s)", and click "Run"

The analysis takes a few hours on the cluster, and multiple uploaded files are queued one
after the other. The results aren't stored indefinitely, so you should download them when
the analysis is done (or the next morning or something). What we need to download is the
NEXUS output and the CSV output.

**It is crucial that you keep track of which output files belong with which upload. A
reasonable way to do this is to take note of the Job ID that DataMonkey assigns to the 
upload and record this ID, for example as a NEXUS comment inside the file you uploaded.**

## Post-processing and visualization

The result files from datamonkey (NEXUS and CSV) need to be merged. Subsequently, this 
merge needs to be combined with the gene duplication (g)SDI analysis in a visualization
that in addition reconstructs the other member sequences for any of the Erycina pusilla
[target genes](genes.tsv).

Hence, this is a two-step approach that is implemented in a 
[driver shell script](script/draw.sh), which in turn executes the following steps:

1. a generic merge of data monkey results done by 
[script/parse_datamonkey.pl](script/parse_datamonkey.pl)

2. the visualization, to SVG format, done by 
[script/draw_gsdi_bsr.pl](script/draw_gsdi_bsr.pl)





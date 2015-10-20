What is this?
-------------

This repository contains scripts and data to analyze the evolution of the MADS box gene
family in orchids (with special attention to the occurrence and expression of these genes
in *Erycina pusilla*).

The basic outline of the workflow contained in these scripts is as follows:

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

To build trees for the codon alignments we now use PhyML. This requires PHYLIP format 
input, which is created from the FASTA files ([script/fasta2phylip.pl](script/fasta2phylip.pl)). Because PHYLIP
format requires that sequence names are no longer than 10 characters we need to have some
string that is guaranteed to be distinct for each sequence. For this we use the genbank
accession number, which is expected to be the last string in the FASTA definition line,
preceded by an underscore ('_').

The PHYLIP files are then analyzed with PhyML using a shell script that has the search
parameters embedded in it ([script/phyml.sh](script/phyml.sh)). Inference goes very fast, at most a few
minutes.

## dN/dS analysis

We analyze branch specific variation in dN/dS ratios using the BranchSiteREL algorithm
of HyPhy, as made available on the datamonkey.org cluster. To this end we must create a
NEXUS file that has both the codon alignment and the maximum likelihood tree embedded in
it. We create this from the PHYLIP file and the resulting tree file 
([script/make_nexus.pl](script/make_nexus.pl)).

Subsequently, we upload the produced NEXUS file and click through the datamonkey wizard
for a BranchSiteREL analysis with the user-provided tree and the universal genetic code.
The analysis takes a few hours on the cluster, and multiple uploaded files are queued one
after the other. The results aren't stored indefinitely, so you should download them when
the analysis is done (or the next morning or something). What we need to download is the
NEXUS output and the CSV output.

## Post-processing and visualization

The result files from datamonkey (NEXUS and CSV) need to be merged and visualized. 

(Depending on the data you feed into datamonkey it may transpire that certain identical
sequences are pruned out of the alignment and the input tree. The tree that is then 
inserted by datamonkey into the NEXUS result lacks branch lengths. For now my approach
has been to take the ML Newick tree from PhyML, remove the taxa that were pruned by
datamonkey, and paste the resulting tree into the NEXUS file.)

Merging the files is a two-step approach:

1. a generic merge that makes no assumptions about naming conventions 
([script/parse_datamonkey.pl](script/parse_datamonkey.pl))

2. a script that applies the original sequence names (remember: we had been working with
just accession numbers starting from the phylogenetic inference step, 
[script/relabel_datamonkey.pl](script/relabel_datamonkey.pl))

Once merged, the result can then be visualized as SVG using [script/draw_tree.pl](script/draw_tree.pl)




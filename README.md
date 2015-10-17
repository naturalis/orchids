The printtrees.pl script is used to write decorated phylogenies as SVG drawings. It is
executed as follows:

perl printtrees.pl -i outfile.nex -f nexus -s secties.txt -o tree.svg -t Polymeres:silver

-i (or --infile=)   an input tree file
-f (or --format=)   the format of the input tree file, e.g. newick, nexus, phyloxml, nexml
-s (or --sections=) a file with a list of names to be italicized
-o (or --outfile=)  a name for the output image file
-t (or --taxon=)    a taxon name to be shaded differently. This can be used multiple times
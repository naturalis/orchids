__author__ = 'janwillem'

# Import all modules
import datetime
from Bio import AlignIO
from Bio.Alphabet import IUPAC, Gapped

# Variable of the combination of the date and time.
now = datetime.datetime.now()

# Alignment file in FASTA-format.
# unambiguous_dna only AGTC.
# TODO Delete "'" from the headers in output-file.  tr -d "'"  is possible in UNIX.

alignment = AlignIO.read(open("codon.aln.fasta"), "fasta", alphabet=Gapped(IUPAC.unambiguous_dna))

# Open new nexus file.
fasta_to_nexus = open(
    "aln.nexus" + "_" + str(now.year) + "_" + str(now.month) + "_" + str(now.day) + "_" + str(now.hour) + "_" + str(
        now.minute) + ".nexus", "w")

# Convert the FASTA-file to NEXUS.
fasta_to_nexus.write(alignment.format("nexus"))

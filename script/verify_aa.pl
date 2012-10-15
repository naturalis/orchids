#!/usr/bin/perl
use strict;
use warnings;
use Bio::Phylo::IO 'parse_matrix';
use Bio::Tools::CodonTable;

my ( $aln, $aa ) = @ARGV;

my $nuc = parse_matrix(
	'-format' => 'fasta',
	'-file'   => $aln,
	'-type'   => 'dna',
	'-as_project' => 1,
);

my $prot = parse_matrix(
	'-format' => 'fasta',
	'-file'   => $aa,
	'-type'   => 'protein',
	'-as_project' => 1,
);

my $table = Bio::Tools::CodonTable->new;
for my $nucrow ( @{ $nuc->get_entities } ) {
	my $name    = $nucrow->get_name;
	my $protrow = $prot->get_by_name($name);
	my $nucseq  = $nucrow->get_char;
	my $protseq = $protrow->get_char;
	my $translated = $table->translate($nucseq);
	$translated =~ s/-//g;
	$translated =~ s/X//g;
	$protseq    =~ s/X//g;
	if ( $translated ne $protseq ) {
		die $name, "\n\n", $translated, "\n\n", $protseq, "\n";
	}
}

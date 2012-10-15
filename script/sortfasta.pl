#!/usr/bin/perl
use strict;
use warnings;
use Bio::Phylo::IO 'parse_matrix';

my $infile = shift;
my $type   = shift;
my $matrix = parse_matrix(
	'-format' => 'fasta',
	'-file'   => $infile,
	'-type'   => $type,
	'-as_project' => 1,
);

my @sorted = sort { $a->get_name cmp $b->get_name } @{ $matrix->get_entities };
for my $row ( @sorted ) {
	print '>', $row->get_name, "\n", $row->get_char, "\n";
}

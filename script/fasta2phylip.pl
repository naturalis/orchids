#!/usr/bin/perl
use strict;
use warnings;
use Bio::Phylo::IO qw'parse unparse';
use Bio::Phylo::Util::CONSTANT ':objecttypes';

# Usage: perl fasta2phylip.pl input.fasta > output.phy

my $infile = shift;
my $project = parse(
	'-type'   => 'dna',
	'-format' => 'fasta',
	'-file'   => $infile,
	'-as_project' => 1,
);

my @rows = @{ $project->get_items(_DATUM_) };
for my $row ( @rows ) {
	my $name = $row->get_name;
	my @parts = split /_/, $name;
	my $acc = $parts[-1];
	$row->set_name($acc);
}

print unparse(
	'-format' => 'phylip',
	'-phylo'  => $project,
	'-relaxed'  => 1,
);

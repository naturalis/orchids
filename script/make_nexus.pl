#!/usr/bin/perl
use strict;
use warnings;
use Bio::Phylo::Factory;
use Bio::Phylo::IO qw'parse_tree parse_matrix';

my ( $matrixfile, $treefile ) = @ARGV;

my $matrix = parse_matrix(
	'-file'       => $matrixfile,
	'-format'     => 'nexus',
	'-as_project' => 1,
);

my $tree = parse_tree(
	'-file'       => $treefile,
	'-format'     => 'nexus',
	'-as_project' => 1,
);

my $taxa = $matrix->make_taxa;

$tree->visit(sub{
	my $node = shift;
	if ( $node->is_terminal ) {
		$node->set_taxon( $taxa->get_by_name( $node->get_name ) );
	}
});

my $fac = Bio::Phylo::Factory->new;
my $proj = $fac->create_project;
my $forest = $fac->create_forest( '-taxa' => $taxa );
$forest->insert($tree);
$proj->insert($taxa);
$proj->insert($matrix);
$proj->insert($forest);
print $proj->to_nexus;
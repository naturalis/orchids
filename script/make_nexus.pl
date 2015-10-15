#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::Factory;
use Bio::Phylo::IO qw'parse_tree parse_matrix';

# process command line arguments
my ( $matrixfile, $treefile, $dataformat, $phyloformat );
if ( @ARGV == 2 ) {
	( $matrixfile, $treefile ) = @ARGV;
	$dataformat = $phyloformat = 'nexus';
}
else {
	GetOptions(
		'treefile=s'    => \$treefile,
		'matrixfile=s'  => \$matrixfile,
		'dataformat=s'  => \$dataformat,
		'phyloformat=s' => \$phyloformat,
	);
}

# read alignment
my $matrix = parse_matrix(
	'-type'       => 'dna',
	'-file'       => $matrixfile,
	'-format'     => $dataformat,
	'-as_project' => 1,
);

# read tree
my $tree = parse_tree(
	'-file'       => $treefile,
	'-format'     => $phyloformat,
	'-as_project' => 1,
);

# make taxa block from alignment
my $taxa = $matrix->make_taxa;

# link tips to taxa
$tree->visit(sub{
	my $node = shift;
	if ( $node->is_terminal ) {
		$node->set_taxon( $taxa->get_by_name( $node->get_name ) );
	}
});

# merge data into project
my $fac = Bio::Phylo::Factory->new;
my $proj = $fac->create_project;
my $forest = $fac->create_forest( '-taxa' => $taxa );
$forest->insert($tree);
$proj->insert($taxa);
$proj->insert($matrix);
$proj->insert($forest);

# write to STDOUT
print $proj->to_nexus;
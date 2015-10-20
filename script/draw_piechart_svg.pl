#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use List::Util 'max';
use Bio::Phylo::Factory;
use Bio::Phylo::IO 'parse_tree';
use Bio::Phylo::Treedrawer;

# process command line arguments
my ( $width, $height, $mode, $shape ) = ( 800, 600, 'RECT', 'PHYLO' );
my ( $treefile );
GetOptions(
	'treefile=s' => \$treefile,
	'width=i'    => \$width,
	'height=i'   => \$height,
	'mode=s'     => \$mode,
	'shape=s'    => \$shape,
);

# parameterize factory for tree drawing
my $fac = Bio::Phylo::Factory->new(
	'tree' => 'Bio::Phylo::Forest::DrawTree',
	'node' => 'Bio::Phylo::Forest::DrawNode',
);

# parse tree
my $tree = parse_tree(
	'-format'     => 'nexml',
	'-file'       => $treefile,
	'-as_project' => 1,
	'-factory'    => $fac,
);

# create pie chart values on nodes, find highest omega
my @omegas;
$tree->visit(sub{
	my $node = shift;
	if ( not $node->is_root ) {
		my $c1w  = $node->get_meta_object('hyphy:p1');
		my $c2w  = $node->get_meta_object('hyphy:p2');
		my $c3w  = $node->get_meta_object('hyphy:p3');
		my $c3o  = $node->get_meta_object('hyphy:omega3');
		push @omegas, $c3o;
		$node->set_generic( 'pie' => {
			'class 1' => $c1w,
			'class 2' => $c2w,
			'class 3' => $c3w,
		});
	}
});

# transforms omega3 into rgb color code
my $max = max @omegas;
my $transform = sub {
	my $val = shift;
	my $scaled = int( ( $max / 255 ) * $val );
	my $green  = 255 - $scaled;
	return "rgb($scaled,$green,0)";
};

# apply color code to focal branch, re-format node labels
$tree->visit(sub{
	my $node = shift;
	if ( not $node->is_root ) {
		my $c3o  = $node->get_meta_object('hyphy:omega3');
		$node->set_branch_color( $transform->($c3o) );
	}
	if ( $node->is_terminal and my $name = $node->get_name ) {
		$name =~ s/[^_]+$//;
		$node->set_name($name);
	}
	else {
		$node->set_name('');
	}
});

# apply midpoint rooting
my $midpoint = $tree->get_midpoint;
$midpoint->set_root_below;

# draw tree
my $treedrawer = Bio::Phylo::Treedrawer->new(
	'-width'  => $width,
	'-height' => $height,
	'-shape'  => $mode, # rectangular branches
	'-mode'   => $shape, # phylogram
	'-format' => 'SVG',
	'-node_radius' => 10,
	'-tip_radius'  => 10,
	'-text_horiz_offset' => 20,
);
$treedrawer->set_tree($tree);
print $treedrawer->draw;

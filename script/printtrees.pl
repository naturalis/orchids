#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::Factory;
use Bio::Phylo::Treedrawer;
use Bio::Phylo::IO 'parse_tree';

# process command line arguments
my ( $infile, $format, @taxon );
GetOptions(
	'infile=s' => \$infile,
	'format=s' => \$format,
	'taxon=s'  => \@taxon,
);

# build hash of command line section:color arguments
my %colour_for_section = map { split /:/ } @taxon;

# parse tree file, create DrawTree with DrawNodes
my $tree = parse_tree(
	'-file'    => $infile,
	'-format'  => $format,
	'-factory' => Bio::Phylo::Factory->new(
		'node' => 'Bio::Phylo::Forest::DrawNode',
		'tree' => 'Bio::Phylo::Forest::DrawTree',
	),
);

# change names to just section part, i.e. last "word"
$tree->visit(sub {
	my $node = shift;
	if ( my $name = $node->get_name ) {
		my @parts = split /_/, $name;
		my $newname = $parts[-1];
		$node->set_name($newname);
	}
});

# collapse on monophyletic sections
$tree->visit_depth_first(
	'-post' => sub {
		my $node = shift;
		my @sections;
		
		# build a growing list of section names
		if ( $node->is_terminal ) {
			push @sections, $node->get_name;			
		}
		else {
			for my $c ( @{ $node->get_children } ) {
				push @sections, @{ $c->get_generic('sections') };
			}
		}
		$node->set_generic( 'sections' => \@sections );
		
		# also see: http://www.perlmonks.org/?node_id=280658
		my @names = keys %{ { map { $_ => 1 } @sections } };
		
		# if all the names are identical, (i.e. the clade is monophyletic) the
		# list of @names will have length one, and consequently the focal node
		# must be collapsed. the way it is implemented, nested monophyletic
		# clades are collapsed recursively, i.e. not so efficient		
		if ( scalar(@names) == 1 ) {
			
			# this collapses the node and specifies how wide the triangle's
			# base needs to be
			$node->set_collapsed(1);			
			$node->set_collapsed_clade_width(23);
			
			# name the collapsed clade after the section
			$node->set_name($names[0]);
		}
		
		# set command-line specified node colour
		if ( my $name = $node->get_name ) {
			if ( my $colour = $colour_for_section{$name} ) {
				$node->set_node_colour($colour);
			}
		}
		
		# some text markup
		$node->set_font_style('italic');
		$node->set_font_face('Verdana');		
	},
);

# default is SVG
print Bio::Phylo::Treedrawer->new(
	'-width'  => 1200,
	'-height' => 2500,
	'-shape'  => 'rect',
	'-mode'   => 'clado',
	'-tree'   => $tree,
	'-text_horiz_offset' => 15,
)->draw;
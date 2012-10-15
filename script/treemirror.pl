#!/usr/bin/perl
use strict;
use warnings;
use XML::Twig;
use Getopt::Long;
use Bio::Phylo::Factory;
use Bio::Phylo::Treedrawer;
use Bio::Phylo::IO 'parse_tree';
use Bio::Phylo::Util::CONSTANT qw':objecttypes :namespaces';

# instantiate factory object
my $fac = Bio::Phylo::Factory->new(
	'tree' => 'Bio::Phylo::Forest::DrawTree',
	'node' => 'Bio::Phylo::Forest::DrawNode',
);

# process command line arguments
my ( $t1, $t2, $f1, $f2, $map, %defines );
GetOptions(
	't1=s'     => \$t1,
	't2=s'     => \$t2,
	'f1=s'     => \$f1,
	'f2=s'     => \$f2,
	'map=s'    => \$map,
	'define=s' => \%defines,
);
my %args = map { '-' . lc($_) => $defines{$_} } keys %defines;

# parse tree1
my $tree1 = parse_tree(
	'-format'  => $f1 || 'newick',
	'-file'    => $t1,
	'-factory' => $fac,
);

my $td = Bio::Phylo::Treedrawer->new( '-tree' => $tree1, %args );
$td->_compute_rooted_coordinates;

# flip coordinates
$tree1->visit_depth_first(
	'-pre' => sub {
		my $node = shift;
		$node->set_x( $td->get_width - $node->get_x );
	}
);

# flip text offset
$td->set_text_horiz_offset( -1 * $td->get_text_horiz_offset );

my $svg1 = $td->render;
print $svg1;

#my $tree2 = parse_tree(
#	'-format' => $f2 || 'newick',
#	'-file'   => $t2
#);
#
#my %map;
#{
#	open my $fh, '<', $map or die $!;
#	while(<$fh>) {
#		chomp;
#		my ( $key, $value ) = split /\t/, $_;
#		$map{$key} = [] if not $map{$key};
#		push @{ $map{$key} }, $value;
#	}
#}



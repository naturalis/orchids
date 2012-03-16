#!/usr/bin/perl
use strict;
use warnings;
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Treedrawer;
use Bio::Phylo::Util::CONSTANT ':objecttypes';
use Getopt::Long;
use Bio::Phylo::Factory;

my $factory = Bio::Phylo::Factory->new(
	'node' => 'Bio::Phylo::Forest::DrawNode',
	'tree' => 'Bio::Phylo::Forest::DrawTree',
);

my ( $infile, $format, $outfile, @taxon, $sections, %section );
GetOptions(
	'infile=s'   => \$infile,
	'format=s'   => \$format,
	'outfile=s'  => \$outfile,
	'taxon=s'    => \@taxon,
	'sections=s' => \$sections,
);

my $project = parse(
	'-file'       => $infile,
	'-format'     => $format,
	'-as_project' => 1,
	'-factory'    => $factory,
);

{
	open my $fh, '<', $sections or die $!;
	while(<$fh>) {
		chomp;
		s/\s//g;
		$section{$_}++;	
	}
}

my ($tree) = @{ $project->get_items(_TREE_) };

$tree->visit(sub {
	my $node = shift;
	if ( my $name = $node->get_name ) {
		my @parts = split /_/, $name;
		my $newname = $parts[-1];
		$node->set_name($newname);
	}
});

$tree->visit_depth_first(
	'-pre' => sub {
		my $node = shift;

		# first check to see if we haven't 
		# already collapsed an ancestor
		my $anc = $node->get_ancestors;
		for my $a ( @{ $anc } ) {
			return if $a->get_collapsed;
		}

		# if not, get all the tips subtended
		# by this focal node
		my $tips = $node->get_terminals;

		# build a hash keyed on the tip names
		my %seen;
		for my $tip ( @{ $tips } ) {
			$seen{$tip->get_name}++;
		}

		# if all the names are identical, the
		# list of keys should have length one,
		# and consequently the focal node must
		# be collapsed
		my @names = keys %seen;
		if ( scalar(@names) == 1 ) {
			$node->set_collapsed(1);
			$node->set_name($names[0]);
			$node->set_collapsed_clade_width(25);
			for my $taxon ( @taxon ) {
				if ( $taxon =~ /^(\S+):(\S+)$/ ) {
					my ( $focal, $color ) = ( $1, $2 );
					if ( $node->get_name eq $focal ) {
						$node->set_node_colour($color);
						#$node->set_branch_colour($color);
					}
				}
			}
		}
	},
);

my $treedrawer = Bio::Phylo::Treedrawer->new(
	'-width'  => 1200,
	'-height' => 2500,
	'-shape'  => 'rect',
	'-mode'   => 'clado',
);
$treedrawer->set_tree($tree);
my $svg = $treedrawer->draw;
open my $fh, '<', \$svg or die $!;
open my $outfh, '>', $outfile or die $!;
while(<$fh>) {
	if ( m|<text [^>]+>([^<]+)</text>| ) {
		my $taxon = $1;
		if ( $section{$taxon} ) {
			s/<text([^>]+) style="/<text$1 style="font-style: italic;/;
		}
	}
	s/stroke-width: 1/stroke-width: 2/;
	print $outfh $_;
}
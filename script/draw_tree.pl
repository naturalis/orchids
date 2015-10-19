#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Color::Spectrum 'generate';
use List::Util qw'min max';
use Bio::Phylo::Factory;
use Bio::Phylo::Treedrawer;
use Bio::Phylo::IO 'parse_tree';
use Bio::Phylo::Util::Logger ':levels';
use Bio::Phylo::Util::CONSTANT ':objecttypes';

# process command line arguments
my ( $width, $height, $predicate, $verbosity ) = ( 1200, 1200, 'hyphy:omega3', WARN );
my $colors = 'red,purple';
my $famroot;
my $infile;
GetOptions(
	'infile=s'    => \$infile,
	'width=i'     => \$width,
	'height=i'    => \$height,
	'predicate=s' => \$predicate,
	'colors=s'    => \$colors,
	'verbose+'    => \$verbosity,
	'famroot=s'   => \$famroot,
);

# instantiate helper objects
my $fac = Bio::Phylo::Factory->new(
	'node'     => 'Bio::Phylo::Forest::DrawNode',
	'tree'     => 'Bio::Phylo::Forest::DrawTree',
);
my $log = Bio::Phylo::Util::Logger->new(
	'-level'   => $verbosity,
	'-class'   => 'main',
);
my $tree = parse_tree(
	'-format'  => 'nexml',
	'-file'    => $infile,
	'-factory' => $fac,
);
my $draw = Bio::Phylo::Treedrawer->new(
	'-width'   => $width,
	'-height'  => $height,
	'-tree'	   => $tree,
	'-format'  => 'svg',
	'-shape'   => 'rect',
	'-mode'	   => 'phylo',
);

# get log transformed max value
my @values;
$tree->visit(sub{ push @values, shift->get_meta_object($predicate) || 0 });
my $max = max @values;
my $logmax = log($max)/log(10);

# apply omega3 colors
my %fam;
$tree->visit(sub{
	my $node = shift;
	my $val = $node->get_meta_object($predicate) || 0;
	my $transformed = ( $val == 0 ? 0 : (log($val)/log(10))/$logmax );
	my $red  = int( $transformed * 255 );
	my $blue = 255 - $red;
	$node->set_branch_color("rgb($red,0,$blue)");
	if ( $node->is_internal ) {
		$node->set_name('');
	}
	else {
		my $name = $node->get_name;
		my @parts = split / /, $name;
		my $fam = pop @parts;
		$node->set_generic( 'fam' => $fam );
		$fam{$fam}++;	
	}
});

# apply midpoint rooting
if ( $famroot ) {
	my @tips;
	$tree->visit(sub{
		my $n = shift;
		push @tips, $n if $n->is_terminal and $n->get_generic('fam') eq $famroot;
	});
	$tree->get_mrca(\@tips)->set_root_below(1000)->set_name('');
}
else {
	$tree->get_midpoint->set_root_below(1000)->set_name('');
}

# apply family colors
my @fams = keys %fam;
my @colors = generate( scalar(@fams), split /,/, $colors );
my %c = map { $fams[$_] => $colors[$_] } 0 .. $#fams;
$tree->visit(sub{
	my $node = shift;
	if ( $node->is_terminal ) {
		my $fam = $node->get_generic('fam');
		$node->set_font_color( $c{$fam} );
	}
});

# apply styling
$tree->set_font_face('Verdana');
$tree->set_font_style('Italic');
$tree->set_font_size(12);
$tree->set_branch_width(2);

# draw the tree
print $draw->draw;

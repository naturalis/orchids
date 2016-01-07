#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use Scalar::Util 'looks_like_number';
use List::Util qw'min max';
use Bio::Phylo::Treedrawer;
use Bio::Phylo::Util::Logger ':levels';
use Bio::Phylo::IO qw'parse parse_tree';
use Bio::Phylo::Util::CONSTANT qw':objecttypes :namespaces';

# process command line arguments
my $phyloxml; # phyloxml output from (G)SDI
my $nexml;    # NeXML output from parse_datamonkey.pl
my $genes;    # tab-separated spreadsheet of accession => gene mapping
my $verbosity = WARN;
my $attribute = 'hyphy:omega3';
my ( $width, $height ) = ( 1200, 1200 );
GetOptions(
	'phyloxml=s'  => \$phyloxml,
	'nexml=s'     => \$nexml,
	'verbose+'    => \$verbosity,
	'width=i'     => \$width,
	'height=i'    => \$height,
	'attribute=s' => \$attribute,
	'genes=s'     => \$genes,
);

# instantiate helper objects
my $log = Bio::Phylo::Util::Logger->new(
	'-class'  => 'main',
	'-level'  => $verbosity,	
);
my $bsr_tree = parse_tree(
	'-format' => 'nexml',
	'-file'   => $nexml,
);
my $sdi_tree = parse_tree(
	'-format' => 'phyloxml',
	'-file'   => $phyloxml,
);
my $drawer = Bio::Phylo::Treedrawer->new(
	'-format'       => 'svg',
	'-width'        => $width,
	'-height'       => $height,
	'-shape'        => 'rect',
	'-mode'	        => 'phylo',
	'-node_radius'  => 5,	
	'-branch_width' => 2,
);

# read genes spreadsheet
my %acc;
{
	my @header;
	open my $fh, '<', $genes or die $!;
	LINE: while(<$fh>) {
		chomp;
		my @record = split /\t/, $_;
		if ( not @header ) {
			@header = @record;
			next LINE;
		}
		my %record = map { $header[$_] => $record[$_] } ( 0 .. $#header );
		my $acc = $record[0];
		$acc{$acc} = \%record;
	}
}

# link SDI and BSR tips, clean up SDI node labels
$log->info("going to link tips in SDI and BSR trees");
for my $st ( @{ $sdi_tree->get_entities } ) {

	# link the tips
	if ( $st->is_terminal ) {

		# parse accession number out of tip label
		my $name = $st->get_name;
		my @parts = split /_/, $name;
		my $acc = pop @parts;
		$st->set_name( join ' ', @parts );
	
		# link the equivalent tips
		if ( my $bt = $bsr_tree->get_by_name($acc) ) {
			$st->set_generic( 'bt' => $bt );
			$bt->set_generic( 'st' => $st );
		}
		else {
			$log->warn("couldn't find BSR tip $acc");
		}
	}
	else {
		
		# interior node labels are aLRT support values.
		# these need to be rounded to two decimal places.
		my $val = $st->get_name;
		if ( looks_like_number $val ) {
			$val = sprintf '%.2f', $val;
			$st->set_name( $val );
			$st->set_text_horiz_offset(-20);
		}
		$st->set_name('') if $val eq 'root';
	}
}

# reroot the BSR tree
$log->info("going to re-root the BRS tree");
my @clades = @{ $sdi_tree->get_root->get_children };
CLADE: for my $c ( @clades ) {
	my @bt = map { $_->get_generic('bt') } @{ $c->get_terminals };
	
	# only one of the two clades from the root in SDI tree 
	# is going to be monophyletic in the BSR tree
	if ( $bsr_tree->is_clade(\@bt) ) {
		$log->info("found equivalent monophyletic clade to root on");
		$bsr_tree->deroot;
		$bsr_tree->get_mrca(\@bt)->set_root_below;
		last CLADE;
	}
	else {
		$log->info("not yet found equivalent monophyletic clade to root on");
	}
}

# copy over the BSR annotations
$log->info("going to copy BSR annotations to SDI tree");
for my $sn ( @{ $sdi_tree->get_entities } ) {
	my $bn;
	if ( $sn->is_internal ) {
		$bn = $bsr_tree->get_mrca([map { $_->get_generic('bt') } @{$sn->get_terminals}]);
	}
	else {
		$bn = $sn->get_generic('bt');		
	}
	if ( $bn ) {
		$sn->add_meta($_) for @{ $bn->get_meta };		
	}
	else {
		$log->warn("couldn't find equivalent node to copy annotations from");
	}
}	

# get log transformed max value for $attribute
my @values;
$sdi_tree->visit(sub{ push @values, shift->get_meta_object($attribute) || 0 });
my $max = max @values;
my $logmax = log($max)/log(10);

# apply omega3 and duplication colors
$log->info("going to apply BRS and SDI visual elements");
$sdi_tree->visit(sub{
	my $node = shift;

	# apply styling
	$node->set_font_face('Verdana');
	$node->set_font_size(12);
	$node->set_font_style('Italic') if $node->is_terminal;	
	$node->set_font_colour('blue') if $node->get_name =~ /Erycina pusilla/;
	
	# omega3
	my $val = $node->get_meta_object($attribute) || 0;
	my $transformed = ( $val == 0 ? 0 : (log($val)/log(10))/$logmax );
	my $red  = int( $transformed * 255 );
	my $blue = 255 - $red;
	$node->set_branch_color("rgb($red,0,$blue)");
	$log->info($node->get_meta_object('hyphy:Corrected_p_value'));
	
	# duplication
	if ( $node->is_internal ) {
		my $event = $node->get_meta_object('px:events');
		if ( $event ) {
			$event = $event->[0];
			$log->debug($event->get_predicate);
			if ( $event->get_predicate eq 'px:duplications' ) {
				$node->set_node_color('red');
				$node->set_generic('dup'=>1);
			}
			else {
				$node->set_node_color('green');
			}
		}
		else {
			$log->warn("no event annotations attached to interior node");
		}
	}
});

# draw the tree
$log->info("going to draw tree");
$drawer->set_tree($sdi_tree->ladderize);
print $drawer->draw;

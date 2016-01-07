#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use Scalar::Util qw'looks_like_number';
use List::Util qw'min max';
use Bio::Phylo::Treedrawer;
use Bio::Phylo::Util::Logger qw':levels';
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
$log->info("going to read BSR summary tree from $nexml");
my $bsr_tree = parse_tree(
	'-format' => 'nexml',
	'-file'   => $nexml,
);
$log->info("going to read SDI tree from $phyloxml");
my $sdi_tree = parse_tree(
	'-format' => 'phyloxml',
	'-file'   => $phyloxml,
);
my $drawer = Bio::Phylo::Treedrawer->new(
	'-height'       => scalar( @{ $sdi_tree->get_terminals } ) * 25,
	'-format'       => 'svg',
	'-width'        => $width,
	'-shape'        => 'rect',
	'-mode'	        => 'phylo',
	'-node_radius'  => 5,	
	'-branch_width' => 4,
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
		my $fam = pop @parts;
		$st->set_name( join ' ', @parts );
		$st->set_generic( 'fam' => $fam );

		# lookup accession number
		if ( my $anno = $acc{$acc} ) {
			if ( my $gene = $anno->{'Target_Gene'} ) {
				$log->info("seq $acc is target gene $gene");
				$st->set_generic( 'gene' => $gene );
			}
		}
	
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
	$log->debug($node->get_meta_object('hyphy:Corrected_p_value'));
	
	# duplication
	if ( $node->is_internal ) {
		my $event = $node->get_meta_object('px:events');
		if ( $event ) {
			$event = $event->[0];
			$log->debug($event->get_predicate);
			if ( $event->get_predicate eq 'px:duplications' ) {
				$node->set_node_color('red');
				$node->set_generic( 'dup' => 1 );
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


# apply target gene names
$log->info("going to apply target gene names");
for my $tip ( @{ $sdi_tree->get_terminals } ) {
    if ( my $gene = $tip->get_generic('gene') ) {
        $log->info("going to find members for target gene $gene");
        $tip->set_name( $tip->get_name . ' ' . $gene );
        $tip->set_generic( 'fam' => undef );
        my $anc = $tip->get_ancestors;
        unshift @$anc, $tip;

        # iterate over all other tips except annotated ones
        for my $t ( @{ $sdi_tree->get_terminals } ) {
            if ( not $t->get_generic('gene') ) {
            	
            	# count all duplications between tips and mrca
                my $dups;
                my $mrca = $tip->get_mrca($t)->get_id;
                my $ta = $t->get_ancestors;
                unshift @$ta, $t;
                for my $array ( $anc, $ta ) {
					MRCA: for my $i ( 0 .. $#{ $array } ) {					
						$dups++ if $array->[$i]->get_generic('dup');
						last MRCA if $array->[$i]->get_id == $mrca;						
					}
                }
                $t->set_name( $t->get_name . ' ' . $gene ) unless $dups;
                $t->set_generic( 'fam' => undef ) unless $dups;
            }
        }
    }
}

# append "default" families
for my $tip ( @{ $sdi_tree->get_terminals } ) {
	if ( my $fam = $tip->get_generic('fam') ) {
		$fam =~ s/-.*//;
		$fam = "($fam)";
		$log->info($tip->get_name . ' added to default family ' . $fam);
		$tip->set_name( $tip->get_name . ' ' . $fam );
	}
}

# draw the tree
$log->info("going to draw tree");
$drawer->set_tree($sdi_tree->ladderize);
print $drawer->draw;

#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Scalar::Util 'looks_like_number';
use Bio::Phylo::Util::CONSTANT ':objecttypes';
use Bio::Phylo::Util::Logger ':levels';
use Bio::Phylo::IO 'parse';

# process command line arguments
my $verbosity = WARN;
my $format = 'figtree';
my $infile;
my $outgroups;
GetOptions(
	'infile=s'    => \$infile,
	'verbose+'    => \$verbosity,
	'format=s'    => \$format,
	'outgroups=s' => \$outgroups,
);

# instantiate helper objects
my $log = Bio::Phylo::Util::Logger->new(
	'-level' => $verbosity,
	'-class' => [ 'main', 'Bio::Phylo::Parsers::Figtree', 'Bio::Phylo::Parsers::Newick' ],
);
$log->info("going to read $format tree from $infile");
my $proj = parse(
	'-format' => $format,
	'-file'   => $infile,
	'-as_project' => 1,
);
$log->info("read project $proj");
my ($tree) = @{ $proj->get_items(_TREE_) };
$log->info("have tree $tree");

# copy support values to internal node labels
$tree->visit(sub{
	my $node = shift;
	if ( $node->is_internal ) {
		my $p = $node->get_meta_object('fig:prob');
		if ( looks_like_number $p ) {
			$log->info("have support value $p");
			$node->set_name($p * 100);
		}
		else {
			$log->warn("NO support value found");
		}
	}
});

# root on outgroups.txt
if ( -e $outgroups ) {
	$log->info("going to read outgroups from $outgroups");
	my @og;
	open my $fh, '<', $outgroups or die $!;
	while(<$fh>) {
		chomp;
		if ( $_ ) {
			push @og, $tree->get_by_name($_);
		}
	}	
	$log->info("have ".scalar(@og)." outgroup taxa: ".Dumper(\@og));
	my $mrca = $tree->get_mrca([@og]);
	
	# outgroup is monophyletic
	if ( @{ $mrca->get_terminals } == @og ) {
		$mrca->set_root_below(100 => 1);
	}
	
	# outgroup is NOT monophyletic, need to invert
	else {
		$log->info("going to invert outgroup");
		my @ig;
		my %seen = map { $_->get_name => 1 } @og;		
		for my $tip ( @{ $tree->get_terminals } ) {
			if ( not $seen{ $tip->get_name } ) {
				push @ig, $tip;
			}		
			else {
				$log->info("skipping already seen tip ".$tip->get_name);
			}
		}
		$log->info("have ".scalar(@ig)." ingroup taxa");
		my $imrca = $tree->get_mrca([@ig]);
		if ( @{ $imrca->get_terminals } == @ig ) {
			$log->info("ingroup is monophyletic, will root below it");
			my $r = $imrca->set_root_below(100 => 1);
		}
		else {
			$log->warn("outgroup taxa are NOT monophyletic: ".scalar(@{$imrca->get_terminals})." != ".scalar(@ig));
		}
	}
}
else {
	$log->warn("no outgroups specified");
}

print $tree->to_newick( '-nodelabels' => 1 );
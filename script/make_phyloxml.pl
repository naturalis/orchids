#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::DB::GenBank;
use Bio::Phylo::Factory;
use Bio::Phylo::Util::Logger ':levels';
use Bio::Phylo::IO qw'parse_tree parse unparse';
use Bio::SUPERSMART::Service::MarkersAndTaxaSelector;
use Bio::Phylo::Util::CONSTANT qw':namespaces :objecttypes';

# process command line arguments
my $verbosity = WARN;
my $format = 'newick';
my ( $speciestree, $genetree, $outfile, $alignment );
GetOptions(
	'speciestree=s' => \$speciestree,
	'genetree=s'    => \$genetree,
	'outfile=s'     => \$outfile,
	'format=s'      => \$format,
	'verbose+'      => \$verbosity,
	'alignment=s'   => \$alignment,
);

# instantiate helper objects
my $db  = Bio::DB::GenBank->new;
my $fac = Bio::Phylo::Factory->new;
my $mts = Bio::SUPERSMART::Service::MarkersAndTaxaSelector->new;
my $log = Bio::Phylo::Util::Logger->new(
	'-level'  => $verbosity,
	'-class'  => 'main',
);

# this is optional...
my %seen;
if ( $speciestree ) {

	# ... but requires an outfile
	if ( not $outfile ) {
		$log->error("need -outfile argument when processing -speciestree");
		exit(1);
	}

	# annotate the species tree. we do this using TNRS.
	$log->info("going to annotate species tree $speciestree");
	my $sp = parse(
		'-format' => 'newick',
		'-file'   => $speciestree,	
		'-as_project' => 1,
	);
	my ($st) = @{ $sp->get_items(_TREE_) };
	$st->set_namespaces( 'px' => _NS_PHYLOXML_ );
	my @staxa;
	for my $tip ( @{ $st->get_terminals } ) {

		# pre-process the name
		my $name = $tip->get_name;
		$name =~ s/_/ /g;
		$name =~ s/-/ /g;
		$name =~ s/'//g;
	
		# do a lookup
		if ( my $id = $mts->_do_tnrs_search($name) ) {
			$log->info("$name => $id");
			$tip->set_name($name);
			$seen{$id} = $name;
			push @staxa, make_taxon($name,$tip,$id);
		}
		else {
			$log->error("Couldn't find name $name");
		}	
	}
	
	# write output
	open my $fh, '>', $outfile or die $!;
	print $fh unparse(
		'-format' => 'phyloxml',
		'-phylo'  => $sp,
	);
}

# annotate the gene tree. we do this by doing a lookup of the accession
$log->info("going to read gene tree $genetree");
my $gp = parse(
	'-format'     => $format,
	'-file'       => $genetree,
	'-as_project' => 1,
);
my ($gt) = @{ $gp->get_items(_TREE_) };

# outgroup root
{

	# map accession numbers to gene families
	$log->info("going to read gene families from $alignment");
	my %fam;
	open my $fh, '<', $alignment or die $!;
	while(<$fh>) {
		chomp;
		if ( />/ ) {
			my @parts = split /_/, $_;
			my $acc = $parts[-1];
			my $fam = $parts[-2];
			$fam{$acc} = $fam;
		}		
	}
	
	# group tips by gene family
	my %grouped;
	for my $acc ( keys %fam ) {
		my $fam = $fam{$acc};
		$grouped{$fam} = [] if not $grouped{$fam};
		my $tip = $gt->get_by_name($acc);
		if ( $tip ) {
			push @{ $grouped{$fam} }, $tip;
		}
	}
	$log->info("have ".scalar(keys(%grouped))." families");
	
	# find the first monophyletic family
	FAM: for my $fam ( keys %grouped ) {
		my $tips = $grouped{$fam};
		my $mrca = $gt->get_mrca($tips);
		my $desc = $mrca->get_terminals;
		if ( scalar(@$tips) == scalar(@$desc) ) {
			$log->info("going to root on $fam");
			$mrca->set_root_below(100);
			last FAM;
		}	
	}
}

# annotate/rename tips
$gt->set_namespaces( 'px' => _NS_PHYLOXML_ );
my @gtaxa;
my @prune;
for my $tip ( @{ $gt->get_terminals } ) {

	# pre-process the name
	my $name = $tip->get_name;
	my @parts = split /_/, $name;
	$name = $parts[-1];
	
	# do a lookup
	if ( my $seq = $db->get_Seq_by_acc($name) ) {
		my $id = $seq->species->ncbi_taxid;
		$name  = $seq->species->binomial . " $name";
		$name  =~ s/ /_/g;
		$tip->set_name($name);
		$log->info("$name => $id");
		push @gtaxa, make_taxon($name,$tip,$id);
		
		# check if seen in species tree
		if ( %seen ) {
			if ( $seen{$id} ) {
				$log->debug("$name in gene tree seen in species tree");
			}
			else {
				push @prune, $tip;
				$log->error("$name in gene tree not seen in species tree");
			}
		}
		else {
			$log->debug("No indexing of species nodes done");
		}
	}
	else {
		$log->error("Couldn't find sequence $name");
	}
}

# prune taxa not in species tree
if ( @prune ) {
	$log->warn("going to prune ".scalar(@prune)." tips not in species tree");
	$gt->prune_tips(\@prune);
}

# write output
print unparse(
	'-format' => 'phyloxml',
	'-phylo'  => $gp,
);

sub make_taxon {
	my ( $name, $node, $id ) = @_;
	my $taxon = $fac->create_taxon(
		'-name'  => $name,
		'-nodes' => [ $node ],
	);
	$taxon->set_meta_object(
		'px:id' => $fac->create_meta(
			'-namespaces' => { 'px' => _NS_PHYLOXML_ },
			'-triple'     => { 'px:uniprot' => $id   },
		)
	);	
	return $taxon;
}
#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::Factory;
use Bio::Phylo::IO qw'parse unparse';
use Bio::Phylo::Util::CONSTANT qw':objecttypes :namespaces';

# can use predicate sswap:genbankAccessionNumber
my $sswap = 'http://sswapmeet.sswap.info/sequence/';
my $bp = _NS_BIOPHYLO_;

# process command line arguments
my ( $nexml, $fasta, $outformat, $type );
GetOptions(
	'nexml=s'     => \$nexml,
	'fasta=s'     => \$fasta,
	'outformat=s' => \$outformat,
	'type=s'      => \$type,
);

# instantiate helper objects
my $fac = Bio::Phylo::Factory->new;
my $np = parse(
	'-format'     => 'nexml',
	'-file'       => $nexml,
	'-as_project' => 1,
);
my $fp = parse(
	'-format'     => 'fasta',
	'-file'       => $fasta,
	'-as_project' => 1,
	'-type'       => $type,
);

# process starting from taxa
$np->set_namespaces( 'sswap' => $sswap, 'bp' => $bp );
my ($taxa) = @{ $np->get_items(_TAXA_) };
my %taxon;
$taxa->visit(sub{
	my $taxon = shift;
	my $acc = $taxon->get_name;
	my ($name) = grep { /_$acc$/ } map { $_->get_name } @{ $fp->get_items(_DATUM_) };
	my @parts = split /_/, $name;
	
	# apply binomial name to taxa, nodes and rows
	my $binomial = $parts[0] . ' ' . $parts[1] . ' ' . $parts[2];
	$_->set_name($binomial) for @{ $taxon->get_nodes }, @{ $taxon->get_data }, $taxon;
	
	# attach accession numbers to rows
	for my $row ( @{ $taxon->get_data } ) {
		$row->set_meta_object( 'sswap:genbankAccessionNumber' => $acc );
		$row->set_meta_object( 'bp:geneFamily' => $parts[2] );
	}
	
	# store taxon duplicates
	my $key = $parts[0] . ' ' . $parts[1];
	$taxon{$key} = [] if not $taxon{$key};
	push @{ $taxon{$key} }, $taxon;
});

# repopulate taxa
$taxa->clear();
my @taxa;
for my $name ( keys %taxon ) {
	my @node = map { @{ $_->get_nodes } } @{ $taxon{$name} };
	my @data = map { @{ $_->get_data  } } @{ $taxon{$name} };
	push @taxa, $fac->create_taxon( 
		'-name'  => $name,
		'-nodes' => \@node,
		'-data'  => \@data,
	);
}
$taxa->insert( sort { $a->get_name cmp $b->get_name } @taxa );

# write output
if ( $outformat ) {
	print unparse(
		'-phylo'  => $np,
		'-format' => $outformat,
	);
}
else {
	print $np->to_xml( 
		'-compact' => 1,	
	);
}

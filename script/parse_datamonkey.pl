#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::IO qw'parse parse_tree';
use Bio::Phylo::Util::Logger ':levels';
use Bio::Phylo::Util::CONSTANT ':objecttypes';

# process command line arguments
my $verbosity = WARN;
my ( $nexus, $csv );
GetOptions(
	'verbose+' => \$verbosity,
	'nexus=s'  => \$nexus,
	'csv=s'    => \$csv,
);

# instantiate helper objects
my $ns  = 'http://www.hyphy.org/terms#';
my $log = Bio::Phylo::Util::Logger->new(
	'-level' => $verbosity,
	'-class' => 'main',
);

# read CSV
my %csv;
{
	my @header;
	open my $fh, '<', $csv or die $!;
	LINE: while(<$fh>) {
		chomp;
		
		# parse the header
		if ( not @header ) {
			@header = split /,/, $_;
			s/[ \-]/_/g for @header;
			shift @header;	
			next LINE;		
		}
		
		# parse the record
		my @record = split /,/, $_;
		my $id = shift @record;
		my %r;
		$r{$header[$_]} = $record[$_] for 0 .. $#record;
		$csv{$id} = \%r;
	}
	$log->info("parsed CSV file $csv");
}

# read hyphy block
my ( $mixtree, $nexusdata );
{
	open my $fh, '<', $nexus or die $!;
	LINE: while(<$fh>) {
		s/'//g;
		$nexusdata .= $_;
	
		# parse the mixtureTree statement, which we need for the node labels
		if ( /Tree mixtureTree=(.+)/ ) {
			my $newick = $1;
			$newick =~ s/{.+?}//g;
			$log->info("found mixtureTree in HyPhy block");			
			$mixtree = parse_tree(
				'-format' => 'newick',
				'-string' => $newick,
			);
			last LINE;
		}
	}
}

# parse nexus data
my $project = parse(
	'-format' => 'nexus',
	'-string' => $nexusdata,
	'-as_project' => 1,
);
$log->info("parsed nexus file $nexus");

# node indexer function
my %lookup;
sub indexer {
	my $node = shift;
	my @children = @{ $node->get_children };
	if ( @children ) {
		my @tips = sort { $a cmp $b } map { @{ $_->get_generic('tips') } } @children;
		my $key  = join ',', @tips;
		$lookup{$key} = [] if not $lookup{$key};
		push @{ $lookup{$key} }, $node;
		$node->set_generic( 'tips' => \@tips );
		$node->set_generic( 'key'  => $key   );
	}
	else {
		$node->set_generic( 'tips' => [ $node->get_name ] );
	}
}

# index the trees
my ($orgtree) = @{ $project->get_items(_TREE_) };
$orgtree->visit_depth_first( '-post' => \&indexer );
$mixtree->visit_depth_first( '-post' => \&indexer );
$log->info("done indexing nodes");

# apply csv annotations
$project->set_namespaces( 'hyphy' => $ns );
$orgtree->visit(sub{
	my $node = shift;
	my $name;
	
	# copy node name over if internal
	if ( $node->is_internal ) {
		my $key = $node->get_generic('key');
		my ( $org, $mix ) = @{ $lookup{$key} };
		$name = $mix->get_name;
		$node->set_name( $name );
	}
	else {
		$name = $node->get_name;
	}
	
	# copy annotations
	if ( $csv{$name} ) {
		my %anno = %{ $csv{$name} };
		for my $predicate ( keys %anno ) {
			$node->set_meta_object( "hyphy:$predicate" => $anno{$predicate} );
		}
	}	
	$log->info("copied annotations for name $name");	
});

# print output
print $project->to_xml( '-compact' => 1 );
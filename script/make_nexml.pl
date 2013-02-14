#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::IO qw'parse parse_tree';
use Bio::Phylo::Util::CONSTANT '_TREE_';
use Bio::Phylo::Util::Logger ':levels';
use Bio::Phylo::Factory;

# process command line arguments
my ( $treefile, $logfile );
my $verbosity = WARN;
GetOptions(
	'treefile=s' => \$treefile,
	'logfile=s'  => \$logfile,
	'verbose+'   => \$verbosity,
);

# instantiate factory object and helper vars
my $ns  = 'http://www.hyphy.org/terms#';
my $fac = Bio::Phylo::Factory->new;
my $log = Bio::Phylo::Util::Logger->new(
	'-level' => $verbosity,
	'-class' => 'main',
);

# parse input bayesian tree as project
my $proj = parse(
	'-format'     => 'nexus',
	'-file'       => $treefile,
	'-as_project' => 1,
);
$proj->set_namespaces( 'hyphy' => $ns );
my ($tree) = @{ $proj->get_items(_TREE_) };

# open hyphy log file
open my $logfh, '<', $logfile or die $!;

# iterate over lines
my $relabeled;
my $current;
my %seen;
while(<$logfh>) {
	chomp;
	my $line = $_;
	
	# grab the first tree description in the file and copy the internal
	# node labels over to the bayesian tree
	if ( ! $relabeled && $line =~ /Tree mixtureTreeG=(.+)/ ) {
		my $mixtreestring = $1;
		$log->debug("going to match up node labels");
		align_mixtree($mixtreestring);		
	}
	
	# record the current focal node label
	if ( $line =~ /^Node: mixtureTree\.(.+)$/ ) {
		$current = $1;
		$seen{$current} = 0 if not defined $seen{$current};
	}
	
	# parse the current omega class's parameter values and apply
	# them to the focal node
	if ( $line =~ /Class ([1-3]): omega = (\d+\.?\d*) weight = (\d+\.?\d*)/ ) {
		my ( $class, $omega, $weight ) = ( $1, $2, $3 );
		if ( $seen{$current} < 3 ) {
			my ($node) = @{ $tree->get_by_regular_expression(
				'-value' => 'get_name',
				'-match' => qr/^$current$/i,
			) };
			$node->add_meta(
				$fac->create_meta(
					'-triple' => { "hyphy:class${class}omega" => $omega }
				)
			);
			$node->add_meta(
				$fac->create_meta(
					'-triple' => { "hyphy:class${class}weight" => $weight }
				)
			);			
		}
		$seen{$current}++;
	}
}

print $proj->to_xml;

sub align_mixtree {
	my $mixtreestring = shift;
	my $mixtree = parse_tree(
		'-format' => 'newick',
		'-string' => $mixtreestring,
		'-as_project' => 1
	);	
	
	# traverse trees to find equivalent nodes
	$mixtree->visit_depth_first(
		'-post' => sub {
			my $node = shift;
			my $name = $node->get_name;
			my @children = @{ $node->get_children };
			
			# node is internal
			if ( @children ) {
				$log->debug("matching up label on internal node $name");
			
				# extend array of tip names subtended by $node
				my @tips;
				push @tips, @{ $_->get_generic('tips') } for @children;
				$node->set_generic( 'tips' => \@tips );
				
				# fetch equivalent tips in other tree
				my @node_objects;
				for my $tip ( @tips ) {
					$log->debug("searching for tip $tip");
					my $node_object = $tree->get_by_regular_expression(
						'-value' => 'get_name',
						'-match' => qr/^$tip$/i,
					);
					if ( scalar( @{ $node_object } ) == 1 ) {
						push @node_objects, $node_object->[0];
						$log->debug("found matching node");
					}
					else {
						$log->error("didn't find expected number of matches");
					}
				}
				my $mrca = $tree->get_mrca(\@node_objects);
				$mrca->set_name($node->get_name);
			}
			else {
			
				# initialize array of tip names
				$node->set_generic( 'tips' => [ $node->get_name ] );
			}
		}
	);
}
#!/usr/bin/perl
use strict;
use warnings;
use Bio::Phylo::IO 'parse_matrix';

my ( $nucfile, $aafile ) = @ARGV;

my $nucmat = parse_matrix(
	'-format' => 'fasta',
	'-type'   => 'dna',
	'-file'   => $nucfile,
	'-as_project' => 1,
);

my $aamat = parse_matrix(
	'-format' => 'fasta',
	'-type'   => 'protein',
	'-file'   => $aafile,
	'-as_project' => 1,
);

$nucmat->visit(sub{
	my $row   = shift;
	my $name  = $row->get_name;
	my $aarow = $aamat->get_by_name($name);
	my @aa    = $aarow->get_char;
	my @nuc   = $row->get_char;
	print ">$name\n";
	my $gaps = 0;	
	for my $i ( 0 .. $#aa ) {
		if ( $aa[$i] eq '-' ) {
			print '---';
			$gaps++;
		}
		else {
			print $nuc[ ( $i - $gaps ) * 3 ];
			print $nuc[ ( $i - $gaps ) * 3 + 1 ];
			print $nuc[ ( $i - $gaps ) * 3 + 2 ];
		}
	}
	print "\n";
});

#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::IO 'parse_matrix';
use Bio::DB::GenBank;

my ( $format, $type, $infile ) = ( 'fasta', 'dna' );
GetOptions(
	'format=s' => \$format,
	'type=s'   => \$type,
	'infile=s' => \$infile,
);

my $matrix = parse_matrix(
	'-format' => $format,
	'-file'   => $infile,
	'-type'   => $type,
);

$matrix->visit(sub{
	my $row = shift;
	my @char = grep { $_ !~ /-/ } $row->get_char;
	print '>', $row->get_name, "\n", join( '', @char ), "\n";
});

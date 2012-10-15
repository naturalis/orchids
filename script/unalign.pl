#!/usr/bin/perl
use strict;
use warnings;
use Bio::Phylo::IO 'parse_matrix';
use Bio::DB::GenBank;

my $infile = shift;
my $matrix = parse_matrix(
	'-format' => 'nexus',
	'-file'   => $infile,
	'-as_project' => 1,
);

$matrix->visit(sub{
	my $row = shift;
	my @char = grep { $_ !~ /-/ } $row->get_char;
	print '>', $row->get_name, "\n", join( '', @char ), "\n";
});

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

my $gb = Bio::DB::GenBank->new;

$matrix->visit(sub{
	my $row = shift;
	if ( my $name = $row->get_name ) {
		if ( $name =~ m/([^_]+)$/ ) {
			my $accession = $1;
			if ( $accession !~ /^AP3\d+$/ && $accession =~ /^[A-Z][A-Z][0-9]+$/ ) {
				warn "trying to fetch AA for $accession from GenBank";
				if ( my $seq = $gb->get_Seq_by_gi($accession) ) {

					# iterate over features sequence
					for my $feat ( $seq->get_SeqFeatures ) {

						# check to see if it's a protein coding sequence with an AA translation
						if ( $feat->primary_tag eq 'CDS' and $feat->has_tag('translation') ) {

							# fetch and pring the translation
							my ($protseq) = $feat->get_tag_values('translation');
							print '>', $name, "\n", $protseq, "\n";
						}
					}
				}
			}
			else {
				warn "$name is not on GenBank";
				print '>', $name, "\n";
			}
		}
	}
});

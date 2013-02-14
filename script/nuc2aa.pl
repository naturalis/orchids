#!/usr/bin/perl
use strict;
use warnings;
use Bio::DB::GenBank;

my $infile = shift;
my $gb = Bio::DB::GenBank->new;
open my $fh, '<', $infile or die $!;
while(<$fh>) {
	next unless /^>/;
	my $defline = $_;
	if ( $defline =~ m/^>.+_([A-Z][A-Z][0-9]+)$/ ) {
		my $accession = $1;
		warn "trying to fetch AA for $accession from GenBank";
		if ( my $seq = $gb->get_Seq_by_gi($accession) ) {

			# iterate over features sequence
			for my $feat ( $seq->get_SeqFeatures ) {

				# check to see if it's a protein coding sequence with an AA translation
				if ( $feat->primary_tag eq 'CDS' and $feat->has_tag('translation') ) {

					# fetch and pring the translation
					my ($protseq) = $feat->get_tag_values('translation');
					print $defline, $protseq, "\n";
				}
			}
		}
	}
	else {
		warn "$_ is not on GenBank";
		print $_;
	}
}

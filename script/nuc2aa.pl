#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use Bio::Seq;
use Bio::DB::GenBank;
use Bio::Phylo::IO 'parse_matrix';
use Bio::Phylo::Util::Logger ':levels';

my ( $format, $type, $verbosity, $infile, $no_fetch ) = ( 'fasta', 'dna', WARN );
GetOptions(
	'format=s' => \$format,
	'type=s'   => \$type,
	'infile=s' => \$infile,
	'verbose+' => \$verbosity,
	'no_fetch' => \$no_fetch,
);

my $log = Bio::Phylo::Util::Logger->new(
	'-level' => $verbosity,
	'-class' => 'main',
);

my $matrix = parse_matrix(
	'-format' => $format,
	'-type'   => $type,
	'-file'   => $infile,
	'-as_project' => 1,
);

my $gb = Bio::DB::GenBank->new;

$matrix->visit(sub{
	my $row = shift;
	my $name = $row->get_name;
	if ( not $no_fetch and $name =~ m/^.+_([A-Z][A-Z]?[0-9]+)$/ ) {
		my $accession = $1;
		$log->info("trying to fetch AA for $accession from GenBank");
		if ( my $seq = $gb->get_Seq_by_gi($accession) ) {

			# iterate over features sequence
			for my $feat ( $seq->get_SeqFeatures ) {

				# check to see if it's a protein coding sequence with an AA translation
				if ( $feat->primary_tag eq 'CDS' and $feat->has_tag('translation') ) {

					# fetch and print the translation
					my ($protseq) = $feat->get_tag_values('translation');
					print '>', $name, "\n", $protseq, "\n";
				}
			}
		}
	}
	else {
		if ( $no_fetch ) {
			$log->info("Going to translate locally");
		}
		else {
			$log->warn("Couldn't find accession number in $name");
		}
		my $seq_data = $row->get_char;
		my $seq_obj = Bio::Seq->new( '-display_id' => $name, '-seq' => $seq_data );
		my $translated = $seq_obj->translate();
		print '>', $name, "\n", $translated->seq, "\n";
	}
});

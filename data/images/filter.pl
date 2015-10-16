#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use utf8;
use open ':encoding(utf8)';

# process command line arguments
my ( $listing, $spreadsheet, $outfile );
GetOptions(
	'listing=s'     => \$listing,
	'spreadsheet=s' => \$spreadsheet,
	'outfile=s'     => \$outfile,
);


# read file listing
my %ID;
{
	open my $fh, '<', $listing or die $!;
	while(<$fh>) {
		chomp;
		if ( /0*(\d+)/ ) {
			my $id = $1;
			$ID{$id}++;
		}
	}
}

# read spreadsheet
{
	my $header;
	open my $fh, '<', $spreadsheet or die $!;
	open my $out, '>', $outfile or die $!;
	LINE: while(<$fh>) {
		chomp;
		my @line = split /\t/, $_;
		if ( not $header ) {
			print $out join( "\t", @line ), "\n";
			$header++;
			next LINE;
		}
		if ( $ID{$line[0]} ) {
			print $out join( "\t", @line ), "\n";		
		}	
	}
}




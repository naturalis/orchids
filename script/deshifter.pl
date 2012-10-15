#!/usr/bin/perl
use strict;
use warnings;
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Util::Logger ':levels';

my $log = Bio::Phylo::Util::Logger->new(
	'-class' => 'Bio::Phylo::Parsers::Nexus',
	'-level' => DEBUG,
);

my $file = shift;
my $proj = parse(
	'-format' => 'nexus',
	'-file'   => $file,
	'-as_project' => 1,
);
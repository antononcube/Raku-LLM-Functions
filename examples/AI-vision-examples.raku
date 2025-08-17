#!/usr/bin/env raku
use v6.d;

# use lib <. lib>;

use LLM::Functions;

my $url1 = 'https://i.imgur.com/LEGfCeql.jpg';
my $url2 = 'https://i.imgur.com/H2n3m0Xl.jpg';
my $fname1 = $*HOME ~ '/Downloads/Racoon-inkblot.jpg';
my $fname2 = $*HOME ~ '/Downloads/ThreeHunters.jpg';
my @images = [$url1, $fname2];
my @urlImages = [$url1, $url2];
my @fileImages = [$fname1, $fname2];

#say llm-vision-synthesize(:@images2);
say llm-vision-synthesize('Describe the images:', @fileImages);
say '=' x 120;
say llm-vision-synthesize('Describe the images:', @urlImages);
#say llm-vision-synthesize(images => [$url1,]);
#say llm-vision-synthesize(images => [$fname2,]);
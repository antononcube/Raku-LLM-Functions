#!/usr/bin/env raku
use v6.d;

use lib <. lib>;
use LLM::Functions;

my @queries = [
    'make a classifier with the method RandomForeset over the data dfTitanic',
    'show precision and accuracy',
    'plot True Positive Rate vs Positive Predictive Value',
    'what is a good meat and potatoes recipe'
];

my $tstart = now;
#my @vecs = llm-embedding(@queries, e => llm-configuration("ChatGPT")):echo;
my @vecs = llm-embedding(@queries, e => llm-configuration("ChatGPT", model => 'text-embedding-002')):echo;
#my @vecs = llm-embedding(@queries, e => llm-configuration("Gemini")):echo;
my $tend = now;

say "Time {$tend - $tstart}.";

say '=' x 100;

.elems.say for @vecs;

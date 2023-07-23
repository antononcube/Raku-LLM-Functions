use v6.d;

use lib '.';
use lib './lib';

use LLM::Functions;
use LLM::Functions::Configuration;
use LLM::Functions::Evaluator;

use Test;

plan *;

## 1
my $conf1 = llm-configuration('palm');
my $conf2 = $conf1.clone;

$conf2.prompts = ['new', "prompt"];

is-deeply $conf1.prompts, [];

## 2
my $evaluator1 = LLM::Functions::Evaluator.new(conf => llm-configuration('palm'));
my $evaluator2 = $evaluator1.clone;

$evaluator2.conf.prompts = ['new', "prompt"];

is-deeply $evaluator1.conf.prompts, [];


done-testing;

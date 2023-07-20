use v6.d;

use lib '.';
use lib './lib';

use LLM::Functions;
use LLM::Functions::Evaluator;

use Test;

plan *;

## 1
ok LLM::Functions::Evaluator.new;

## 2
ok LLM::Functions::Evaluator.new(conf => llm-configuration(Whatever));

## 3
ok LLM::Functions::ChatEvaluator.new(conf => llm-configuration(Whatever));

## 4
ok LLM::Functions::ChatEvaluator.new(conf => llm-configuration('PaLM'));


done-testing;

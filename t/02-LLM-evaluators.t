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

## 5
is-deeply
        llm-evaluator(llm-configuration('PaLM', api-user-id => 'u5')),
        LLM::Functions::Evaluator.new(conf => llm-configuration('PaLM', api-user-id => 'u5'));

## 6
is-deeply
        llm-evaluator('PaLM', api-user-id => 'u6'),
        llm-evaluator(llm-configuration('PaLM', api-user-id => 'u6'));

## 7
is-deeply
        llm-evaluator('PaLM', api-user-id => 'BrandNewUser3233'),
        llm-evaluator(llm-configuration('PaLM', api-user-id => 'BrandNewUser3233'));

## 8
is-deeply
        llm-evaluator('PaLM', formatron => Numeric, api-user-id => 'u8'),
        LLM::Functions::Evaluator.new(conf => llm-configuration('PaLM', api-user-id => 'u8'), formatron => Numeric);


done-testing;

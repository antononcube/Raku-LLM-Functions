use v6.d;

use lib '.';
use lib './lib';

use WWW::OpenAI;
use LLM::Functions;

use Test;

plan *;

## 1
ok llm-configuration('openai');

## 2
my $prompt2 = "Make a recipe for the given phrase.";
ok $prompt2 ==> llm-function(llm-evaluator => llm-configuration('openai') )("greek salad");

## 3
ok $prompt2 ==> llm-function(llm-evaluator => 'openai')("greek salad");

done-testing;

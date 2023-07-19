use v6.d;

use lib '.';
use lib './lib';

use WWW::OpenAI;
use LLM::Functions;

use Test;

plan *;

## 1
ok llm-configuration('palm');

## 2
my $prompt2 = "Make a recipe for the given phrase.";
ok ($prompt2 ==> llm-function(llm-evaluator => llm-configuration('palm') ))("greek salad");

## 3
ok ($prompt2 ==> llm-function(llm-evaluator => 'palm'))("greek salad");

## 3
my &prompt3 = {"How many $^a can fit inside one $^b?"};
ok (&prompt3 ==> llm-function(llm-evaluator => 'palm'))(['basket balls', 'toyota corolla 2010']);

## 4
my &prompt4 = -> :$dish, :$cuisine {"Given a recipe for $dish in the $cuisine cuisine."}
ok (&prompt4 ==> llm-function(llm-evaluator => 'palm'))(dish => 'salad', cuisine => 'Russion', max-tokens => 300);

done-testing;

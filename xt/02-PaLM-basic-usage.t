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
ok llm-function($prompt2, llm-evaluator => llm-configuration('palm'))("greek salad");

## 3
isa-ok llm-function($prompt2, llm-evaluator => 'palm')("greek salad"),
        Str,
        'greek salad';

## 4
my &prompt3 = { "How many $^a can fit inside one $^b?" };
is llm-function(&prompt3, llm-evaluator => 'palm')(['basket balls', 'toyota corolla 2010']).all ~~ Str,
        True,
        'basket balls in toyota corolla 2010';

## 5
my &prompt4 = -> :$dish, :$cuisine { "Given a recipe for $dish in the $cuisine cuisine." }
is llm-function(&prompt4, llm-evaluator => 'palm')(dish => 'salad', cuisine => 'Russion', max-tokens => 300).all ~~ Str,
        True,
        'recipe';

done-testing;

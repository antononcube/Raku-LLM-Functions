#!/usr/bin/env raku
use v6.d;

use lib '.';
use lib './lib';

use LLM::Functions;

#========================================================================================================================

.raku.say for llm-configuration(Whatever).Hash;

#========================================================================================================================

say '=' x 120;

my &func = llm-function('Show a recipe for:');

say &func;

say '-' x 120;

say &func('greek salad');


#========================================================================================================================

say '=' x 120;
say 'Positional agruments';
say '-' x 120;

my &func2 = llm-function({"How many $^a can fit inside one $^b?"}, llm-evaluator => 'palm');

say &func2;

say '-' x 120;

say &func2("tenis balls", "toyota corolla 2010");


#========================================================================================================================

say '=' x 120;
say 'Named agruments';
say '-' x 120;

my &func3 = llm-function(-> :$dish, :$cuisine {"Give a recipe for $dish in the $cuisine cuisine."},
        llm-evaluator => llm-configuration('openai', stop-tokens => Empty));
#        llm-evaluator => llm-configuration('openai', stop-tokens => ['Instructions',]));

say &func3;

say '-' x 120;

say &func3(dish => 'salad', cuisine => 'Russion', max-tokens => 300);
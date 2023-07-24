use v6.d;

use lib '.';
use lib './lib';

use LLM::Functions;

use Test;

plan *;

## 1
ok llm-example-function(<finger hand> => <hand arm>, llm-evaluator => 'palm')('foot');

## 2
isa-ok llm-example-function( '<| A->3, 4->K1 |>' => '{ A:3, 4:K1 }')('<| 23->3, G->33, T -> R5|>'), Str;

## 3
isa-ok llm-example-function({"crocodile" => "grasshopper", "fox" => "cardinal"}, hint => 'animal colors')('raccoon'), Str;

## 4
is llm-example-function( (1..4) Z=> 11 «*« (1..4) )(8).trim, '88';

done-testing;

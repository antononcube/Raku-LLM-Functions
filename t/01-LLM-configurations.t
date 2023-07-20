use v6.d;

use lib '.';
use lib './lib';

use WWW::OpenAI;
use LLM::Functions;

use Test;

plan *;

## 1
isa-ok llm-configuration(Whatever).Hash, Hash;

## 2
isa-ok llm-configuration('openai'), LLM::Functions::Configuration;

## 3
my $pre3 = 'Use to GitHub table specification of the result if possible.';
ok llm-configuration(llm-configuration('openai'), prompts => [$pre3, ]);

## 4
ok llm-configuration('openai', prompts => [$pre3, ]);

## 5
is-deeply
        llm-configuration('PaLM').Hash.grep({ $_.key ∉ <api-user-id>}).Hash,
        llm-configuration('palm').Hash.grep({ $_.key ∉ <api-user-id>}).Hash;

done-testing;

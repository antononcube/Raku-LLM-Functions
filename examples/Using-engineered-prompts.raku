#!/usr/bin/env raku
use v6.d;

# use lib <. lib>;

use LLM::Functions;

my $lang = 'Wolfram Language';

say '=' x 120;
say 'Code Writer';
say '-' x 120;

# Message response based on a (pre-)prompt
my $pre = slurp($*CWD ~ '/resources/prompts/Code-Writer.txt');

$pre .= subst('$LANG', $lang):g;

my $msg = q:to/END/;
Create a table listing the first 9 layers of Pascal's triangle.
END


my $conf = llm-configuration('chatgpt');

my &func = llm-function($pre, llm-evaluator => $conf);

say &func;

say '-' x 120;

say &func($msg):!echo;

#===================================================================================================
#`[
say '=' x 120;
say 'Learn Anything Now GPT';
say '-' x 120;

# Message response based on a (pre-)prompt
my $preLAN = slurp($*CWD ~ '/resources/prompts/LAN-GPT.txt');


my $msgLAN = q:to/END/;
What are the names of the asteroids belts?
END

my &func2 = llm-function($preLAN, llm-evaluator => $conf);

say &func;

say '-' x 120;

say &func($msgLAN, max-tokens => 400);
]

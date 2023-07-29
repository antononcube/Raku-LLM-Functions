# Expand tests into documentation examples


## Introduction

In this document we ingest tests and narrate them with the help of an LLM.
(ChatGPT or PaLM.)

Load packages:

```perl6
use LLM::Functions;
```
```
# (Any)
```

------

## Prompt 

```perl6
my $pre = q:to/END/;
You are a Raku Code Narrator. 
You explain Raku code into documentation examples.
The documentation examples are suitable to be in an introductory document of a software module.
When you see "isa-ok" interpret it as "the output is the same as".
When you see "is-deeply" interpret it as "the output is the same as".
When you see "ok" interpret it as "no problems during the execution".
END
```
```
# You are a Raku Code Narrator. 
# You explain Raku code into documentation examples.
# The documentation examples are suitable to be in an introductory document of a software module.
# When you see "isa-ok" interpret it as "the output is the same as".
# When you see "is-deeply" interpret it as "the output is the same as".
# When you see "ok" interpret it as "no problems during the execution".
```

------

## Tests ingestion 

```perl6
my &testNarrator = llm-function($pre, llm-evaluator => 'openai');
```
```
# -> $text, *%args { #`(Block|3019711648248) ... }
```

```perl6
my $testCode = slurp($*CWD ~ "/../t/01-LLM-configurations.t");
my @testSpecs = $testCode.split( / '##' | 'done-testing' /).tail(*-1)>>.trim;
@testSpecs = @testSpecs.grep({ $_.chars > 30});
.say for @testSpecs;
```
```
# 1
# isa-ok llm-configuration(Whatever).Hash, Hash;
# 2
# isa-ok llm-configuration('openai'), LLM::Functions::Configuration;
# 3
# my $pre3 = 'Use to GitHub table specification of the result if possible.';
# ok llm-configuration(llm-configuration('openai'), prompts => [$pre3, ]);
# 4
# ok llm-configuration('openai', prompts => [$pre3, ]);
# 5
# is-deeply
#         llm-configuration('PaLM').Hash.grep({ $_.key ∉ <api-user-id>}).Hash,
#         llm-configuration('palm').Hash.grep({ $_.key ∉ <api-user-id>}).Hash;
# 6
# my $conf6 = llm-configuration('openai', prompts => [$pre3, ]);
# isa-ok $conf6.prompts, Positional;
# 7
# is-deeply $conf6.prompts, [$pre3,];
```

```perl6, results=asis
for @testSpecs.kv -> $k, $t {
    say "## ", $k + 1;
    say "{'`' x 3}\n$t\n{'`' x 3}\n\n";
    say &testNarrator($t);
    say "\n\n"
}
```
## 1
```
1
isa-ok llm-configuration(Whatever).Hash, Hash;
```




The output of llm-configuration(Whatever).Hash is the same as a Hash object.



## 2
```
2
isa-ok llm-configuration('openai'), LLM::Functions::Configuration;
```




This code checks that the output of llm-configuration('openai') is an object of type LLM::Functions::Configuration.



## 3
```
3
my $pre3 = 'Use to GitHub table specification of the result if possible.';
ok llm-configuration(llm-configuration('openai'), prompts => [$pre3, ]);
```




Here, we use the llm-configuration function to configure the OpenAI prompts. We pass in an llm-configuration object, plus an array containing the prompt we defined earlier. The llm-configuration returns an output, which we use ok to check that there were no problems during execution.



## 4
```
4
ok llm-configuration('openai', prompts => [$pre3, ]);
```




No problems during the execution of llm-configuration('openai', prompts => [$pre3, ]). This code sets the configuration for an openai module using the variable $pre3 as a prompt.



## 5
```
5
is-deeply
        llm-configuration('PaLM').Hash.grep({ $_.key ∉ <api-user-id>}).Hash,
        llm-configuration('palm').Hash.grep({ $_.key ∉ <api-user-id>}).Hash;
```




The code above will check the Hash of the llm-configuration('PaLM') and llm-configuration('palm') for any keys that do not equal <api-user-id>. If none are found, it will return an empty Hash. This can be tested using the is-deeply command to check that the output is the same as the expected result.



## 6
```
6
my $conf6 = llm-configuration('openai', prompts => [$pre3, ]);
isa-ok $conf6.prompts, Positional;
```



is-deeply $conf6.prompts, [$pre3, ];
ok llm-configuration('openai', prompts => [$pre3, ]).out(:$pre3);

Here is an example of a configuration object created by the llm-configuration method using the 'openai' keyword. This configuration object contains one prompt, which is the $pre3 variable. The isa-ok test verifies that the value of the 'prompts' key is an array. The is-deeply test verifies that the array contains the value of the $pre3 variable. The ok test verifies that the configuration object's out method successfully returns the value of the $pre3 variable.



## 7
```
7
is-deeply $conf6.prompts, [$pre3,];
```




The output of $conf6.prompts is the same as [$pre3,].


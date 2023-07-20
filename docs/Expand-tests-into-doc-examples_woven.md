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
my &testNarrator = llm-function($pre, llm-evaluator => 'chatgpt');
```
```
# -> $text, *%args { #`(Block|3645374785080) ... }
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
```

```perl6
for @testSpecs -> $t {
    say "=" x 100;
    say $t;
    say "-" x 100;
    say &testNarrator($t);
}
```
```
# ====================================================================================================
# 1
# isa-ok llm-configuration(Whatever).Hash, Hash;
# ----------------------------------------------------------------------------------------------------
# error => {code => (Any), message => That model is currently overloaded with other requests. You can retry your request, or contact us through our help center at help.openai.com if the error persists. (Please include the request ID aaa0aaa2e7f37681c2c8c9320e8a4ce2 in your message.), param => (Any), type => server_error}
# ====================================================================================================
# 2
# isa-ok llm-configuration('openai'), LLM::Functions::Configuration;
# ----------------------------------------------------------------------------------------------------
# The code `llm-configuration('openai')` is checking if the output of this function is an instance of the `LLM::Functions::Configuration` class. If the output is an instance of that class, the test will pass.
# ====================================================================================================
# 3
# my $pre3 = 'Use to GitHub table specification of the result if possible.';
# ok llm-configuration(llm-configuration('openai'), prompts => [$pre3, ]);
# ----------------------------------------------------------------------------------------------------
# error => {code => (Any), message => That model is currently overloaded with other requests. You can retry your request, or contact us through our help center at help.openai.com if the error persists. (Please include the request ID cb83b8f995ff30be561412b342d8722e in your message.), param => (Any), type => server_error}
# ====================================================================================================
# 4
# ok llm-configuration('openai', prompts => [$pre3, ]);
# ----------------------------------------------------------------------------------------------------
# The code snippet provided is calling a function named "llm-configuration" with the argument 'openai' and a named argument 'prompts' which is an array containing a variable named '$pre3'. The function is expected to return a result without any issues during execution.
# ====================================================================================================
# 5
# is-deeply
#         llm-configuration('PaLM').Hash.grep({ $_.key ∉ <api-user-id>}).Hash,
#         llm-configuration('palm').Hash.grep({ $_.key ∉ <api-user-id>}).Hash;
# ----------------------------------------------------------------------------------------------------
# The code snippet compares the outputs of two expressions using the `is-deeply` function in Raku. 
# 
# The first expression is `llm-configuration('PaLM').Hash.grep({ $_.key ∉ <api-user-id>}).Hash`, which retrieves the hash from the "PaLM" configuration in `llm-configuration`, and then filters out any elements whose key is not in the `<api-user-id>` list.
# 
# The second expression is `llm-configuration('palm').Hash.grep({ $_.key ∉ <api-user-id>}).Hash`, which does the same thing as the first expression, but with the configuration key "palm" instead of "PaLM".
# 
# The `is-deeply` function compares the outputs of these two expressions and checks if they are the same.
```

# Expand tests into documentation examples


## Introduction

In this document we ingest tests and narrate them with the help of an LLM.
(ChatGPT or PaLM.)

Load packages:

```perl6
use LLM::Functions;
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

------

## Tests ingestion 

```perl6
my &testNarrator = llm-function($pre, llm-evaluator => 'chatgpt');
```

```perl6
my $testCode = slurp($*CWD ~ "/../t/01-LLM-configurations.t");
my @testSpecs = $testCode.split( / '##' | 'done-testing' /).tail(*-1)>>.trim;
@testSpecs = @testSpecs.grep({ $_.chars > 30});
.say for @testSpecs;
```

```perl6
for @testSpecs -> $t {
    say "=" x 100;
    say $t;
    say "-" x 100;
    say &testNarrator($t);
}
```

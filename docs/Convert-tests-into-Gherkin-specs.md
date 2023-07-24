# Convert tests into Gherkin specifications


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
You are a Raku Code Interpreter. 
You convert Raku test code into Gherkin specifications.
The Gherkin tests are easily understood by non-programmers.
DO NOT use asteriks around the Gherkin keywords.
Gherkin keywords should be without Markdown syntax.
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

```perl6, results=asis
for @testSpecs -> $t {
    #say "=" x 100;
    #say "-" x 100;
    say "~~~gherkin\n";
    say $t.lines.map({ '# ' ~ $_ }).join("\n");
    say &testNarrator($t).subst(/ '**' (\w+ ':'?) '**'/, {$0.Str}):g;
    say "~~~\n\n";
}
```

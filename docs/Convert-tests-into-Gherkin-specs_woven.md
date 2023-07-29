# Convert tests into Gherkin specifications


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
You are a Raku Code Interpreter. 
You convert Raku test code into Gherkin specifications.
The Gherkin tests are easily understood by non-programmers.
DO NOT use asteriks around the Gherkin keywords.
Gherkin keywords should be without Markdown syntax.
END
```
```
# You are a Raku Code Interpreter. 
# You convert Raku test code into Gherkin specifications.
# The Gherkin tests are easily understood by non-programmers.
# DO NOT use asteriks around the Gherkin keywords.
# Gherkin keywords should be without Markdown syntax.
```

------

## Tests ingestion 

```perl6
my &testNarrator = llm-function($pre, llm-evaluator => 'chatgpt');
```
```
# -> $text, *%args { #`(Block|5080813848184) ... }
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
for @testSpecs -> $t {
    #say "=" x 100;
    #say "-" x 100;
    say "~~~gherkin\n";
    say $t.lines.map({ '# ' ~ $_ }).join("\n");
    say &testNarrator($t).subst(/ '**' (\w+ ':'?) '**'/, {$0.Str}):g;
    say "~~~\n\n";
}
```
~~~gherkin

# 1
# isa-ok llm-configuration(Whatever).Hash, Hash;
Feature: Check type of `llm-configuration` result

Scenario: Verify `llm-configuration` result is a Hash

Given a `Whatever` instance

When `llm-configuration` is called on the instance

Then the result should be a Hash
~~~


~~~gherkin

# 2
# isa-ok llm-configuration('openai'), LLM::Functions::Configuration;
Feature: Check Configuration

Scenario: Check LLM Configuration

Given I have an LLM configuration with the name 'openai'
When I check if it is an instance of LLM::Functions::Configuration
Then it should return true
~~~


~~~gherkin

# 3
# my $pre3 = 'Use to GitHub table specification of the result if possible.';
# ok llm-configuration(llm-configuration('openai'), prompts => [$pre3, ]);
Feature: Raku LLM Configuration
  Scenario: LLM Configuration with OpenAI and Prompts
    Given a variable $pre3 with the value 'Use to GitHub table specification of the result if possible.'
    When the function llm-configuration is called with the parameters llm-configuration('openai') and prompts => [$pre3, ]
    Then the result should be successful
~~~


~~~gherkin

# 4
# ok llm-configuration('openai', prompts => [$pre3, ]);
Scenario: Configure LLM with OpenAI provider and prompts

Given the LLM is configured
When configuring the LLM with the OpenAI provider and prompts
Then the LLM should be successfully configured with the OpenAI provider and the provided prompts
~~~


~~~gherkin

# 5
# is-deeply
#         llm-configuration('PaLM').Hash.grep({ $_.key ∉ <api-user-id>}).Hash,
#         llm-configuration('palm').Hash.grep({ $_.key ∉ <api-user-id>}).Hash;
Feature: Raku test - is-deeply

Scenario: Verify is-deeply function

Given a llm-configuration with 'PaLM' 

When Hash is filtered by excluding <api-user-id> keys

Then the filtered Hash should be deeply equal to the llm-configuration Hash

Given a llm-configuration with 'palm' 

When Hash is filtered by excluding <api-user-id> keys

Then the filtered Hash should be deeply equal to the llm-configuration Hash
~~~


~~~gherkin

# 6
# my $conf6 = llm-configuration('openai', prompts => [$pre3, ]);
# isa-ok $conf6.prompts, Positional;
**Feature: Check LLM Configuration**

**Scenario: Verify Prompts**
  Given a LLM configuration with the provider "openai" and prompts
  | Prompt |
  | $pre3  |
  When I check the type of the prompts
  Then the prompts should be a positional
~~~


~~~gherkin

# 7
# is-deeply $conf6.prompts, [$pre3,];
Feature: Verify if the prompts are deeply equal

Scenario: Verify if the prompts are deeply equal
  Given a configuration object
  When the prompts are checked for deep equality with the expected prompts
  Then the prompts should be deeply equal to the expected prompts
~~~


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
# -> $text, *%args { #`(Block|6535408581240) ... }
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
Feature: Check if LLM configuration is a Hash

Scenario: Verify if LLM configuration is of type Hash
  Given the LLM configuration object is of type Whatever
  When I check the type of LLM configuration
  Then the type of LLM configuration should be Hash
~~~


~~~gherkin

# 2
# isa-ok llm-configuration('openai'), LLM::Functions::Configuration;
Feature: LLM Configuration

Scenario: Checking LLM Configuration

Given the LLM configuration for 'openai'

When I check if it is an instance of LLM::Functions::Configuration

Then it should return true
~~~


~~~gherkin

# 3
# my $pre3 = 'Use to GitHub table specification of the result if possible.';
# ok llm-configuration(llm-configuration('openai'), prompts => [$pre3, ]);
Feature: LLM Configuration

Scenario: LLM Configuration with OpenAI prompt

Given the LLM configuration is set to 'openai'

When the LLM configuration is called with the following prompts:
```
- 'Use to GitHub table specification of the result if possible.'
```

Then the result should be successful
~~~


~~~gherkin

# 4
# ok llm-configuration('openai', prompts => [$pre3, ]);
**Feature: LLM Configuration**

**Scenario: Setting OpenAI LLM Configuration**

Given a LLM configuration with provider set to "openai"
And the configuration includes the following prompts:
"""
$pre3
"""
~~~


~~~gherkin

# 5
# is-deeply
#         llm-configuration('PaLM').Hash.grep({ $_.key ∉ <api-user-id>}).Hash,
#         llm-configuration('palm').Hash.grep({ $_.key ∉ <api-user-id>}).Hash;
Feature: Raku Test

Scenario: Test is-deeply function with llm-configuration

Given llm-configuration with Key 'PaLM' and Hash values where key is not equal to <api-user-id>

When the is-deeply function is applied to the llm-configuration Hash

Then the result should be equal to llm-configuration Hash with Key 'PaLM'
~~~


~~~gherkin

# 6
# my $conf6 = llm-configuration('openai', prompts => [$pre3, ]);
# isa-ok $conf6.prompts, Positional;
Feature: Check LLM Configuration

Scenario: Verify LLM Configuration Prompts

Given a LLM Configuration with provider "openai" and prompts

```
$pre3
```

When checking the type of `$conf6.prompts`

Then it should be a `Positional`
~~~


~~~gherkin

# 7
# is-deeply $conf6.prompts, [$pre3,];
Specification:

```
Feature: Verify the prompts of the configuration

Scenario: Verify the prompts are deeply equal
    Given a configuration with prompts
    When the prompts are compared with an expected set of prompts
    Then the prompts should be deeply equal
```

**Scenario Outline:**

| conf6.prompts      | expected_prompts |
|--------------------|-----------------|
| [$pre3,]           | [$pre3,]        |

Examples:

```gherkin
Given a configuration with prompts
When the prompts are compared with an expected set of prompts
Then the prompts should be deeply equal
```
~~~


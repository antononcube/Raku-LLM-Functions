# LLM::Functions 

[![MacOS](https://github.com/antononcube/Raku-LLM-Functions/actions/workflows/macos.yml/badge.svg)](https://github.com/antononcube/Raku-LLM-Functions/actions/workflows/macos.yml)
[![Linux](https://github.com/antononcube/Raku-LLM-Functions/actions/workflows/linux.yml/badge.svg)](https://github.com/antononcube/Raku-LLM-Functions/actions/workflows/linux.yml)
[![Win64](https://github.com/antononcube/Raku-LLM-Functions/actions/workflows/windows.yml/badge.svg)](https://github.com/antononcube/Raku-LLM-Functions/actions/workflows/windows.yml)
[![https://raku.land/zef:antononcube/LLM::Functions](https://raku.land/zef:antononcube/LLM::Functions/badges/version)](https://raku.land/zef:antononcube/LLM::Functions)

## In brief

This Raku package provides functions and function objects to access, interact, and utilize 
Large Language Models (LLMs), like 
[OpenAI](https://platform.openai.com), [OAI1],
[PaLM](https://developers.generativeai.google/products/palm), [ZG1],
and
[MistralAI](https://docs.mistral.ai), [MAI1].

For more details how the concrete LLMs are accessed see the packages
["WWW::OpenAI"](https://raku.land/zef:antononcube/WWW::OpenAI), [AAp2],
["WWW::PaLM"](https://raku.land/zef:antononcube/WWW::PaLM), [AAp3], and
["WWW::MistralAI"](https://raku.land/zef:antononcube/WWW::MistralAI), [AAp9].

The LLM functions built by this package can have evaluators that use "sub-parsers" -- see 
["Text::SubParsers"](https://raku.land/zef:antononcube/Text::SubParsers), [AAp4].

The primary motivation to have handy, configurable functions for utilizing LLMs
came from my work on the packages
["ML::FindTextualAnswer"](https://raku.land/zef:antononcube/ML::FindTextualAnswer), [AAp6], and
["ML::NLPTemplateEngine"](https://raku.land/zef:antononcube/ML::NLPTemplateEngine), [AAp7].

A very similar system of functionalities is developed by Wolfram Research Inc.;
see the paclet
["LLMFunctions"](https://resources.wolframcloud.com/PacletRepository/resources/Wolfram/LLMFunctions/), [WRIp1].

For well curated and instructive examples of LLM prompts see the
[Wolfram Prompt Repository](https://resources.wolframcloud.com/PromptRepository/).
Many of those prompts (≈220) are available in Raku and Python --
see ["LLM::Prompts"](https://raku.land/zef:antononcube/LLM::Prompts), [AAp8], and
["LLMPrompts"](https://pypi.org/project/LLMPrompts/), [AAp10], respectively.

The article
["Generating documents via templates and LLMs"](https://rakuforprediction.wordpress.com/2023/07/11/generating-documents-via-templates-and-llms/), [AA1],
shows an alternative way of streamlining LLMs usage. (Via Markdown, Org-mode, or Pod6 templates.)

-----

## Installation

Package installations from both sources use [zef installer](https://github.com/ugexe/zef)
(which should be bundled with the "standard" Rakudo installation file.)

To install the package from [Zef ecosystem](https://raku.land/) use the shell command:

```
zef install LLM::Functions
```

To install the package from the GitHub repository use the shell command:

```
zef install https://github.com/antononcube/Raku-LLM-Functions.git
```

------

## Design

"Out of the box"
["LLM::Functions"](https://raku.land/zef:antononcube/LLM::Functions) uses
["WWW::OpenAI"](https://raku.land/zef:antononcube/WWW::OpenAI), [AAp2],
["WWW::PaLM"](https://raku.land/zef:antononcube/WWW::PaLM), [AAp3], and
["WWW::MistralAI"](https://raku.land/zef:antononcube/WWW::MistralAI), [AAp9].
Other LLM access packages can be utilized via appropriate LLM configurations.

Configurations:
- Are instances of the class `LLM::Functions::Configuration`
- Are used by instances of the class `LLM::Functions::Evaluator`
- Can be converted to Hash objects (i.e. have a `.Hash` method)

New LLM functions are constructed with the function `llm-function`.

The function `llm-function`:

- Has the option "llm-evaluator" that takes evaluators, configurations, or string shorthands as values
- Returns anonymous functions (that access LLMs via evaluators/configurations.)
- Gives result functions that can be applied to different types of arguments depending on the first argument
- Can take a (sub-)parser argument for post-processing of LLM results
- Takes as a first argument a prompt that can be a:
    - String
    - Function with positional arguments
    - Function with named arguments

Here is a sequence diagram that follows the steps of a typical creation procedure of 
LLM configuration- and evaluator objects, and the corresponding LLM-function that utilizes them:

```mermaid
sequenceDiagram
  participant User
  participant llmfunc as llm-function
  participant llmconf as llm-configuration
  participant LLMConf as LLM configuration
  participant LLMEval as LLM evaluator
  participant AnonFunc as Anonymous function
  User ->> llmfunc: ・prompt<br>・conf spec
  llmfunc ->> llmconf: conf spec
  llmconf ->> LLMConf: conf spec
  LLMConf ->> LLMEval: wrap with
  LLMEval ->> llmfunc: evaluator object
  llmfunc ->> AnonFunc:  create with:<br>・evaluator object<br>・prompt
  AnonFunc ->> llmfunc: handle
  llmfunc ->> User: handle
```

Here is a sequence diagram for making a LLM configuration with a global (engineered) prompt,
and using that configuration to generate a chat message response:

```mermaid
sequenceDiagram
  participant WWWOpenAI as WWW::OpenAI
  participant User
  participant llmfunc as llm-function
  participant llmconf as llm-configuration
  participant LLMConf as LLM configuration
  participant LLMChatEval as LLM chat evaluator
  participant AnonFunc as Anonymous function
  User ->> llmconf: engineered prompt
  llmconf ->> User: configuration object
  User ->> llmfunc: ・prompt<br>・configuration object
  llmfunc ->> LLMChatEval: configuration object
  LLMChatEval ->> llmfunc: evaluator object
  llmfunc ->> AnonFunc: create with:<br>・evaluator object<br>・prompt
  AnonFunc ->> llmfunc: handle
  llmfunc ->> User: handle
  User ->> AnonFunc: invoke with<br>message argument
  AnonFunc ->> WWWOpenAI: ・engineered prompt<br>・message
  WWWOpenAI ->> User: LLM response 
```

------

## Configurations

### OpenAI-based

Here is the default, OpenAI-based configuration:

```perl6
use LLM::Functions;
.raku.say for llm-configuration('OpenAI').Hash;
```
```
# :stop-tokens($[])
# :model("text-davinci-003")
# :api-user-id("user:853403645647")
# :evaluator(Whatever)
# :examples($[])
# :temperature(0.8)
# :max-tokens(300)
# :name("openai")
# :images($[])
# :prompt-delimiter(" ")
# :tools($[])
# :api-key(Whatever)
# :tool-response-insertion-function(WhateverCode)
# :module("WWW::OpenAI")
# :tool-prompt("")
# :argument-renames(${:api-key("auth-key"), :stop-tokens("stop")})
# :format("values")
# :prompts($[])
# :tool-request-parser(WhateverCode)
# :function(proto sub OpenAITextCompletion ($prompt is copy, :$model is copy = Whatever, :$suffix is copy = Whatever, :$max-tokens is copy = Whatever, :$temperature is copy = Whatever, Numeric :$top-p = 1, Int :$n where { ... } = 1, Bool :$stream = Bool::False, Bool :$echo = Bool::False, :$stop = Whatever, Numeric :$presence-penalty = 0, Numeric :$frequency-penalty = 0, :$best-of is copy = Whatever, :api-key(:$auth-key) is copy = Whatever, Int :$timeout where { ... } = 10, :$format is copy = Whatever, Str :$method = "tiny") {*})
# :total-probability-cutoff(0.03)
```

Here is the ChatGPT-based configuration:

```perl6
.say for llm-configuration('ChatGPT').Hash;
```
```
# prompts => []
# tool-response-insertion-function => (WhateverCode)
# module => WWW::OpenAI
# tool-request-parser => (WhateverCode)
# api-user-id => user:300992191133
# argument-renames => {api-key => auth-key, stop-tokens => stop}
# evaluator => (my \LLM::Functions::EvaluatorChat_5457798984688 = LLM::Functions::EvaluatorChat.new(context => "", examples => Whatever, user-role => "user", assitant-role => "assistant", system-role => "system", conf => LLM::Functions::Configuration.new(name => "chatgpt", api-key => Whatever, api-user-id => "user:300992191133", module => "WWW::OpenAI", model => "gpt-3.5-turbo", function => proto sub OpenAIChatCompletion ($prompt is copy, :$role is copy = Whatever, :$model is copy = Whatever, :$temperature is copy = Whatever, :$max-tokens is copy = Whatever, Numeric :$top-p = 1, Int :$n where { ... } = 1, Bool :$stream = Bool::False, :$stop = Whatever, Numeric :$presence-penalty = 0, Numeric :$frequency-penalty = 0, :@images is copy = Empty, :api-key(:$auth-key) is copy = Whatever, Int :$timeout where { ... } = 10, :$format is copy = Whatever, Str :$method = "tiny") {*}, temperature => 0.8, total-probability-cutoff => 0.03, max-tokens => 300, format => "values", prompts => [], prompt-delimiter => " ", examples => [], stop-tokens => [], tools => [], tool-prompt => "", tool-request-parser => WhateverCode, tool-response-insertion-function => WhateverCode, images => [], argument-renames => {:api-key("auth-key"), :stop-tokens("stop")}, evaluator => LLM::Functions::EvaluatorChat_5457798984688), formatron => "Str"))
# images => []
# api-key => (Whatever)
# tool-prompt => 
# format => values
# model => gpt-3.5-turbo
# function => &OpenAIChatCompletion
# prompt-delimiter =>  
# total-probability-cutoff => 0.03
# stop-tokens => []
# tools => []
# temperature => 0.8
# examples => []
# name => chatgpt
# max-tokens => 300
```

**Remark:** `llm-configuration(Whatever)` is equivalent to `llm-configuration('OpenAI')`.

**Remark:** Both the "OpenAI" and "ChatGPT" configuration use functions of the package "WWW::OpenAI", [AAp2].
The "OpenAI" configuration is for text-completions;
the "ChatGPT" configuration is for chat-completions. 

### PaLM-based

Here is the default PaLM configuration:

```perl6
.say for llm-configuration('PaLM').Hash;
```
```
# total-probability-cutoff => 0
# name => palm
# tools => []
# examples => []
# model => text-bison-001
# module => WWW::PaLM
# stop-tokens => []
# argument-renames => {api-key => auth-key, max-tokens => max-output-tokens, stop-tokens => stop-sequences}
# evaluator => (Whatever)
# function => &PaLMGenerateText
# temperature => 0.4
# prompt-delimiter =>  
# prompts => []
# tool-response-insertion-function => (WhateverCode)
# images => []
# api-user-id => user:794547769572
# max-tokens => 300
# api-key => (Whatever)
# format => values
# tool-request-parser => (WhateverCode)
# tool-prompt =>
```

-----

## Basic usage of LLM functions

### Textual prompts

Here we make a LLM function with a simple (short, textual) prompt:

```perl6
my &func = llm-function('Show a recipe for:');
```
```
# -> $text, *%args { #`(Block|5457781528120) ... }
```

Here we evaluate over a message: 

```perl6
say &func('greek salad');
```
```
# Greek Salad
# 
# Ingredients:
# 
# -1 head of romaine lettuce, chopped 
# -1 cucumber, sliced
# -1/2 red onion, diced
# -1 green pepper, sliced
# -1/2 cup feta cheese crumbles
# -1/2 cup kalamata olives
# -1/4 cup olive oil
# -3 tablespoons red wine vinegar
# -1 teaspoon oregano
# -Salt and pepper to taste
# 
# Instructions:
# 
# 1. In a large bowl, combine the lettuce, cucumber, red onion, green pepper, feta cheese, and olives.
# 
# 2. In a small bowl, whisk together the olive oil, red wine vinegar, oregano, salt, and pepper.
# 
# 3. Drizzle the dressing over the salad and toss to combine.
# 
# 4. Serve and enjoy!
```

### Positional arguments

Here we make a LLM function with a function-prompt and numeric interpreter of the result:

```perl6
my &func2 = llm-function(
        {"How many $^a can fit inside one $^b?"},
        form => Numeric,
        llm-evaluator => 'palm');
```
```
# -> **@args, *%args { #`(Block|5457817200328) ... }
```

Here were we apply the function:

```perl6
my $res2 = &func2("tennis balls", "toyota corolla 2010");
```
```
# 50
```

Here we show that we got a number:

```perl6
$res2 ~~ Numeric
```
```
# False
```


### Named arguments

Here the first argument is a template with two named arguments: 

```perl6
my &func3 = llm-function(-> :$dish, :$cuisine {"Give a recipe for $dish in the $cuisine cuisine."}, llm-evaluator => 'palm');
```
```
# -> **@args, *%args { #`(Block|5457817237688) ... }
```

Here is an invocation:

```perl6
&func3(dish => 'salad', cuisine => 'Russian', max-tokens => 300);
```
```
# **Russian Salad (Olivier Salad)**
# 
# Ingredients:
# 
# * 2 pounds (900g) potatoes, peeled and cubed
# * 1 pound (450g) carrots, peeled and cubed
# * 1 pound (450g) celery root, peeled and cubed
# * 1 pound (450g) red cabbage, thinly sliced
# * 1 pound (450g) green beans, cooked and cooled
# * 1 cup (240ml) mayonnaise
# * 1/2 cup (120ml) sour cream
# * 1/4 cup (60ml) finely chopped fresh dill
# * 1/4 cup (60ml) finely chopped fresh parsley
# * Salt and pepper to taste
# 
# Instructions:
# 
# 1. In a large bowl, combine the potatoes, carrots, celery root, and red cabbage.
# 2. In a small bowl, whisk together the mayonnaise, sour cream, dill, parsley, salt, and pepper.
# 3. Pour the dressing over the salad and toss to coat.
# 4. Serve immediately or chill for later.
# 
# **Tips:**
# 
# * To make the salad ahead of time, chill it for at least 2 hours before serving.
# * If you don't have time to cook the green beans, you can use canned green beans instead.
# * Feel free to add
```

--------

## LLM example functions

The function `llm-example-function` can be given a training set of examples in order 
to generating results according to the "laws" implied by that training set.  

Here a LLM is asked to produce a generalization:

```perl6
llm-example-function([ 'finger' => 'hand', 'hand' => 'arm' ])('foot')
```
```
# leg
```

Here is an array of training pairs is used:

```perl6
'Oppenheimer' ==> (["Einstein" => "14 March 1879", "Pauli" => "April 25, 1900"] ==> llm-example-function)()
```
```
# April 22, 1904
```

Here is defined a LLM function for translating WL associations into Python dictionaries:

```perl6
my &fea = llm-example-function( '<| A->3, 4->K1 |>' => '{ A:3, 4:K1 }');
&fea('<| 23->3, G->33, T -> R5|>');
```
```
# { 23:3, G:33, T:R5 }
```

The function `llm-example-function` takes as a first argument:
- Single `Pair` object of two scalars
- Single `Pair` object of two `Positional` objects with the same length
- A `Hash`
- A `Positional` object of pairs

**Remark:** The function `llm-example-function` is implemented with `llm-function` and suitable prompt.

Here is an example of using hints:

```perl6
my &fec = llm-example-function(
        ["crocodile" => "grasshopper", "fox" => "cardinal"],
        hint => 'animal colors');

say &fec('raccoon');
```
```
# opossum
```

--------

## Using predefined prompts

Using predefined prompts of the package ["LLM::Prompts"](https://raku.land/zef:antononcube/LLM::Prompts), [AAp8],
can be very convenient in certain (many) cases.

Here is an example using "Fixed That For You" synthesis:

```perl6
use LLM::Prompts;

llm-synthesize([llm-prompt('FTFY'), 'Wha is ther population?'])
```
```
# What is the population?
```

--------

## Using chat-global prompts

The configuration objects can be given prompts that influence the LLM responses 
"globally" throughout the whole chat. (See the second sequence diagram above.)

For detailed examples see the documents:

- ["Using engineered prompts"](./docs/Using-engineered-prompts_woven.md)
- ["Expand tests into documentation examples"](./docs/Expand-tests-into-doc-examples_woven.md)

--------

## Chat objects

Here we create chat object that uses OpenAI's ChatGPT:

```perl6
my $prompt = 'You are a gem expert and you give concise answers.';
my $chat = llm-chat(chat-id => 'gem-expert-talk', conf => 'ChatGPT', :$prompt);
```
```
# LLM::Functions::Chat(chat-id = gem-expert-talk, llm-evaluator.conf.name = chatgpt, messages.elems = 0)
```

```perl6
$chat.eval('What is the most transparent gem?');
```
```
# The most transparent gem is diamond.
```

```perl6
$chat.eval('Ok. What are the second and third most transparent gems?');
```
```
# The second most transparent gem is spinel, and the third most transparent gem is sapphire.
```

Here are the prompt(s) and all messages of the chat object:

```perl6
$chat.say
```
```
# Chat: gem-expert-talk
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# Prompts: You are a gem expert and you give concise answers.
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role	user
# content	What is the most transparent gem?
# timestamp	2023-12-24T13:03:10.357824-05:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role	assistant
# content	The most transparent gem is diamond.
# timestamp	2023-12-24T13:03:11.436697-05:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role	user
# content	Ok. What are the second and third most transparent gems?
# timestamp	2023-12-24T13:03:11.464407-05:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role	assistant
# content	The second most transparent gem is spinel, and the third most transparent gem is sapphire.
# timestamp	2023-12-24T13:03:12.298578-05:00
```

--------

## Potential problems

With PaLM with certain wrong configuration we get the error:

```
error => {code => 400, message => Messages must alternate between authors., status => INVALID_ARGUMENT}
```

--------

## TODO

- [X] DONE Resources
  - See ["LLM::Prompts"](https://github.com/antononcube/Raku-LLM-Prompts)
  - [X] DONE Gather prompts
  - [X] DONE Process prompts into a suitable database
    - Using JSON.
- [ ] TODO Implementation
  - [X] DONE Processing and array of prompts as a first argument
  - [X] DONE Prompt class / object / record
    - Again, see ["LLM::Prompts"](https://github.com/antononcube/Raku-LLM-Prompts)
    - For retrieval and management of prompts.
      - [X] DONE Prompts can be both plain strings or templates / functions.
      - [X] DONE Each prompt has associated metadata:
        - Type: persona, function, modifier
        - Tool/parser
        - Keywords
        - Contributor?
        - Topics: "Advisor bot", "AI Guidance", "For Fun", ...
          - See: https://resources.wolframcloud.com/PromptRepository/
    - [X] DONE Most likely, there would be a separate package "LLM::Prompts", [AAp8].
  - [ ] MAYBE Random selection of LLM-evaluator
    - Currently, the LLM-evaluator of the LLM-functions and LLM-chats is static, assigned at creation.
    - This is easily implemented at "top-level." 
  - [X] DONE Chat class / object
    - For long conversations
  - [X] DONE LLM example function
    - [X] DONE First version with the signatures:
      - [X] `@pairs`
      - [X] `@input => @output`
      - [X] Hint option
    - [X] DONE Verify works with OpenAI 
    - [X] DONE Verify works with PaLM
  - [X] DONE Interpreter argument for `llm-function`
    - See the `formatron` attribute of `LLM::Functions::Evaluator`.
  - [X] DONE Adding `form` option to chat objects evaluator
- [ ] TODO CLI
  - [ ] TODO Based on Chat objects
  - [ ] TODO Storage and retrieval of chats
  - [ ] TODO Has as parameters all attributes of the LLM-configuration objects.
- [ ] TODO Documentation  
  - [ ] TODO Detailed parameters description
    - [ ] TODO Configuration
    - [ ] TODO Evaluator
    - [ ] TODO Chat
  - [X] DONE Using engineered prompts
  - [X] DONE Expand tests in documentation examples
  - [X] DONE Conversion of a test file tests into Gherkin specs
  - [X] DONE Number game programming
    - [X] DONE Man vs Machine
    - [X] DONE Machine vs Machine
  - [X] DONE Using retrieved prompts
  - [ ] TODO Longer conversations / chats

--------

## References

### Articles

[AA1] Anton Antonov,
["Generating documents via templates and LLMs"](https://rakuforprediction.wordpress.com/2023/07/11/generating-documents-via-templates-and-llms/),
(2023),
[RakuForPrediction at WordPress](https://rakuforprediction.wordpress.com).

[ZG1] Zoubin Ghahramani,
["Introducing PaLM 2"](https://blog.google/technology/ai/google-palm-2-ai-large-language-model/),
(2023),
[Google Official Blog on AI](https://blog.google/technology/ai/).

### Repositories, sites

[MAI1] MistralAI team, [MistralAI platform](https://docs.mistral.ai).

[OAI1] OpenAI team, [OpenAI platform](https://platform.openai.com/).

[WRIr1] Wolfram Research, Inc.
[Wolfram Prompt Repository](https://resources.wolframcloud.com/PromptRepository/).

### Packages, paclets

[AAp1] Anton Antonov,
[LLM::Functions Raku package](https://github.com/antononcube/Raku-LLM-Functions),
(2023),
[GitHub/antononcube](https://github.com/antononcube).

[AAp2] Anton Antonov,
[WWW::OpenAI Raku package](https://github.com/antononcube/Raku-WWW-OpenAI),
(2023),
[GitHub/antononcube](https://github.com/antononcube).

[AAp3] Anton Antonov,
[WWW::PaLM Raku package](https://github.com/antononcube/Raku-WWW-PaLM),
(2023),
[GitHub/antononcube](https://github.com/antononcube).

[AAp4] Anton Antonov,
[Text::SubParsers Raku package](https://github.com/antononcube/Raku-Text-SubParsers),
(2023),
[GitHub/antononcube](https://github.com/antononcube).

[AAp5] Anton Antonov,
[Text::CodeProcessing Raku package](https://github.com/antononcube/Raku-Text-CodeProcessing),
(2021),
[GitHub/antononcube](https://github.com/antononcube).

[AAp6] Anton Antonov,
[ML::FindTextualAnswer Raku package](https://github.com/antononcube/Raku-ML-FindTextualAnswer),
(2023),
[GitHub/antononcube](https://github.com/antononcube).

[AAp7] Anton Antonov,
[ML::NLPTemplateEngine Raku package](https://github.com/antononcube/Raku-ML-NLPTemplateEngine),
(2023),
[GitHub/antononcube](https://github.com/antononcube).

[AAp8] Anton Antonov,
[LLM::Prompts Raku package](https://github.com/antononcube/Raku-LLM-Prompts),
(2023),
[GitHub/antononcube](https://github.com/antononcube).

[AAp9] Anton Antonov,
[WWW::MistralAI Raku package](https://github.com/antononcube/Raku-WWW-MistralAI),
(2023),
[GitHub/antononcube](https://github.com/antononcube).

[AAp10] Anton Antonov,
[LLMPrompts Python package](https://pypi.org/project/LLMPrompts/),
(2023),
[PyPI.org/antononcube](https://pypi.org/user/antononcube/).

[WRIp1] Wolfram Research, Inc.
[LLMFunctions paclet](https://resources.wolframcloud.com/PacletRepository/resources/Wolfram/LLMFunctions/),
(2023),
[Wolfram Language Paclet Repository](https://resources.wolframcloud.com/PacletRepository/).

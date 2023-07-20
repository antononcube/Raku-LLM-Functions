# Raku-LLM-Functions

## In brief

Raku package provides functions and function objects to access, interact, and utilize LLMs,
like [OpenAI](https://platform.openai.com), [OAI1], and 
[PaLM](https://developers.generativeai.google/products/palm), [ZG1].

For more details how the concrete LLMs are accessed see the packages
["WWW::OpenAI"](https://raku.land/zef:antononcube/WWW::OpenAI), [AAp2], and
["WWW::PaLM"](https://raku.land/zef:antononcube/WWW::PaLM), [AAp3].

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
["WWW::OpenAI"](https://raku.land/zef:antononcube/WWW::OpenAI), [AAp2], and
["WWW::PaLM"](https://raku.land/zef:antononcube/WWW::PaLM), [AAp3].
Other LLM access packages can utilizes via appropriate LLM configurations.

The configurations are instances of the class `LLM::Functions::Configuration`.
The configurations are used by instances of the class `LLM::Functions::Evaluator`.

New LLM functions are constructed with the function `llm-function`.

The function `llm-function`:

- Has the option "llm-evaluator" that takes evaluators or configurations as values
- Returns anonymous functions (that access LLMs via evaluators/configurations)
- Gives result functions that can be applied to different types of arguments depending on the first argument
- Takes as a first argument a prompt that can be a:
  - String
  - Function with positional arguments
  - Function with named arguments


------

## Basic usage examples

### Configurations

Here is a default configuration:

```perl6
use LLM::Functions;
.raku.say for llm-configuration(Whatever).Hash;
```
```
# :prompts($[])
# :total-probability-cutoff(0.03)
# :tool-response-insertion-function(WhateverCode)
# :api-user-id("user:319315650499")
# :tools($[])
# :tool-prompt("")
# :tool-request-parser(WhateverCode)
# :name("openai")
# :temperature(0.8)
# :prompt-delimiter(" ")
# :model("text-davinci-003")
# :max-tokens(300)
# :api-key(Whatever)
# :module("WWW::OpenAI")
# :function(proto sub OpenAITextCompletion ($prompt is copy, :$model is copy = Whatever, :$suffix is copy = Whatever, :$max-tokens is copy = Whatever, :$temperature is copy = Whatever, Numeric :$top-p = 1, Int :$n where { ... } = 1, Bool :$stream = Bool::False, Bool :$echo = Bool::False, :$stop = Whatever, Numeric :$presence-penalty = 0, Numeric :$frequency-penalty = 0, :$best-of is copy = Whatever, :$auth-key is copy = Whatever, Int :$timeout where { ... } = 10, :$format is copy = Whatever, Str :$method = "tiny") {*})
# :format("values")
# :evaluator(Whatever)
# :stop-tokens($[".", "?", "!"])
```

Here is the ChatGPT configuration:

```perl6
.say for llm-configuration('ChatGPT').Hash;
```
```
# max-tokens => 300
# stop-tokens => [. ? !]
# prompt-delimiter =>  
# module => WWW::OpenAI
# name => openai
# api-user-id => user:122628590160
# function => &OpenAIChatCompletion
# api-key => (Whatever)
# evaluator => (my \LLM::Functions::ChatEvaluator_2884537468088 = LLM::Functions::ChatEvaluator.new(conf => LLM::Functions::Configuration.new(name => "openai", api-key => Whatever, api-user-id => "user:122628590160", module => "WWW::OpenAI", model => "gpt-3.5-turbo", function => proto sub OpenAIChatCompletion ($prompt is copy, :$type is copy = Whatever, :$role is copy = Whatever, :$model is copy = Whatever, :$temperature is copy = Whatever, :$max-tokens is copy = Whatever, Numeric :$top-p = 1, Int :$n where { ... } = 1, Bool :$stream = Bool::False, :$stop = Whatever, Numeric :$presence-penalty = 0, Numeric :$frequency-penalty = 0, :$auth-key is copy = Whatever, Int :$timeout where { ... } = 10, :$format is copy = Whatever, Str :$method = "tiny") {*}, temperature => 0.8, total-probability-cutoff => 0.03, max-tokens => 300, format => "values", prompts => [], prompt-delimiter => " ", stop-tokens => [".", "?", "!"], tools => [], tool-prompt => "", tool-request-parser => WhateverCode, tool-response-insertion-function => WhateverCode, argument-renames => {:api-key("auth-key")}, evaluator => LLM::Functions::ChatEvaluator_2884537468088)))
# temperature => 0.8
# tools => []
# format => values
# model => gpt-3.5-turbo
# prompts => []
# tool-request-parser => (WhateverCode)
# tool-prompt => 
# tool-response-insertion-function => (WhateverCode)
# total-probability-cutoff => 0.03
```

Here is the PaLM configuration

```perl6
.say for llm-configuration('PaLM').Hash;
```
```
# max-tokens => 300
# evaluator => (Whatever)
# tools => []
# tool-response-insertion-function => (WhateverCode)
# api-key => (Whatever)
# stop-tokens => [. ? !]
# model => text-bison-001
# prompt-delimiter =>  
# api-user-id => user:303169049075
# format => values
# function => &PaLMGenerateText
# module => WWW::PaLM
# prompts => []
# tool-prompt => 
# name => palm
# temperature => 0.4
# total-probability-cutoff => 0
# tool-request-parser => (WhateverCode)
```

### Textual prompts

Here we make a LLM function with simple (short textual) prompt:

```perl6
my &func = llm-function('Show a recipe for:');
```
```
# -> $text, *%args { #`(Block|2884558176832) ... }
```

Here we evaluate over a message: 

```perl6
say &func('greek salad');
```
```
# Ingredients:
# 
# • 2 large tomatoes, diced
# 
# • 1 large cucumber, peeled and diced
# 
# • 1/2 red onion, diced
# 
# • 1/2 cup Kalamata olives, pitted and halved
# 
# • 1/3 cup feta cheese, crumbled
# 
# • 2 tablespoons olive oil
# 
# • 1 tablespoon red wine vinegar
# 
# • 1 teaspoon dried oregano
# 
# • Salt and pepper to taste
# 
# Instructions:
# 
# 1. In a large bowl, combine the tomatoes, cucumber, red onion and Kalamata olives.
# 
# 2. Sprinkle the feta cheese over the top.
# 
# 3. In a small bowl, whisk together the olive oil, red wine vinegar, oregano, salt and pepper.
# 
# 4. Pour the dressing over the salad and toss to combine.
# 
# 5. Serve immediately or chill until ready to serve.
```

### Positional arguments

Here we make a LLM function with function-prompt:

```perl6
my &func2 = llm-function({"How many $^a can fit inside one $^b?"}, llm-evaluator => 'palm');
```
```
# -> **@args, *%args { #`(Block|2884642894208) ... }
```

Here were we apply the function:

```perl6
&func2("tenis balls", "toyota corolla 2010");
```
```
# (390)
```

### Named arguments

Here the first argument is a template with two named arguments: 

```perl6
my &func3 = llm-function(-> :$dish, :$cuisine {"Given a recipe for $dish in the $cuisine cuisine."}, llm-evaluator => 'palm');
```
```
# -> **@args, *%args { #`(Block|2884642898024) ... }
```

Here is an invocation:

```perl6
&func3(dish => 'salad', cuisine => 'Russion', max-tokens => 300);
```
```
# (**Russian Salad**
# 
# Ingredients:
# 
# * 1 pound (450g) red potatoes, peeled and cubed
# * 1 pound (450g) carrots, peeled and cubed
# * 1 pound (450g) celery, thinly sliced
# * 1/2 cup (120ml) mayonnaise
# * 1/4 cup (60ml) sour cream
# * 1/4 cup (60ml) finely chopped fresh dill
# * 1/4 cup (60ml) finely chopped fresh parsley
# * 1/4 cup (60ml) finely chopped red onion
# * Salt and pepper to taste
# 
# Instructions:
# 
# 1. In a large bowl, combine the potatoes, carrots, and celery.
# 2. In a small bowl, whisk together the mayonnaise, sour cream, dill, parsley, and red onion.
# 3. Pour the dressing over the salad and toss to coat.
# 4. Season with salt and pepper to taste.
# 5. Serve immediately or chill for later.
# 
# **Tips:**
# 
# * To make the potatoes and carrots more flavorful, roast them in the oven before adding them to the salad.
# * For a more authentic Russian salad, use a hard-boiled egg instead of red onion.
# * Garnish the salad with fresh herbs, such as dill or parsley, before serving.)
```

--------

## Using chat-global prompts

The configuration objects can be given prompts that influence the LLM responses 
"globally" throughout the whole chat.

For detailed examples see the documents:

- ["Using engineered prompts"](./docs/Using-engineered-prompts.md)
- ["Expand tests into documentation examples"](./docs/Expand-tests-into-doc-examples.md)

--------

## References

### Articles

[ZG1] Zoubin Ghahramani,
["Introducing PaLM 2"](https://blog.google/technology/ai/google-palm-2-ai-large-language-model/),
(2023),
[Google Official Blog on AI](https://blog.google/technology/ai/).

### Packages, repositories, sites

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
[Text::CodeProcessing Raku package](https://github.com/antononcube/Raku-Text-CodeProcessing),
(2021),
[GitHub/antononcube](https://github.com/antononcube).

[OAI1] OpenAI Platform, [OpenAI platform](https://platform.openai.com/).


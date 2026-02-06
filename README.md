# LLM::Functions 

[![MacOS](https://github.com/antononcube/Raku-LLM-Functions/actions/workflows/macos.yml/badge.svg)](https://github.com/antononcube/Raku-LLM-Functions/actions/workflows/macos.yml)
[![Linux](https://github.com/antononcube/Raku-LLM-Functions/actions/workflows/linux.yml/badge.svg)](https://github.com/antononcube/Raku-LLM-Functions/actions/workflows/linux.yml)
[![Win64](https://github.com/antononcube/Raku-LLM-Functions/actions/workflows/windows.yml/badge.svg)](https://github.com/antononcube/Raku-LLM-Functions/actions/workflows/windows.yml)
[![https://raku.land/zef:antononcube/LLM::Functions](https://raku.land/zef:antononcube/LLM::Functions/badges/version)](https://raku.land/zef:antononcube/LLM::Functions)

## Introduction

This Raku package provides functions and function objects to access, interact, and utilize 
Large Language Models (LLMs), like 
[OpenAI](https://platform.openai.com), [OAI1],
[Gemini](https://ai.google.dev/gemini-api/docs/models),
[MistralAI](https://docs.mistral.ai), [MAI1],
and
[Ollama](https://ollama.com/search).

For more details how the concrete LLMs are accessed see the packages
["WWW::OpenAI"](https://raku.land/zef:antononcube/WWW::OpenAI), [AAp2],
["WWW::MistralAI"](https://raku.land/zef:antononcube/WWW::MistralAI), [AAp9],
["WWW::Gemini"](https://raku.land/zef:antononcube/WWW::Gemini), [AAp11], and
["WWW::Ollama"](https://raku.land/zef:antononcube/WWW::Ollama), [AAp12].

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
Many of those prompts (more than 220) are available in Raku and Python --
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
["WWW::MistralAI"](https://raku.land/zef:antononcube/WWW::MistralAI), [AAp9],
["WWW::Gemini"](https://raku.land/zef:antononcube/WWW::Gemini), [AAp11], and
["WWW::Ollama"](https://raku.land/zef:antononcube/WWW::Ollama), [AAp12],
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

```raku
use LLM::Functions;
.raku.say for llm-configuration('OpenAI').Hash;
```
```
# :tools($[])
# :images($[])
# :temperature(0.8)
# :argument-renames(${:api-key("auth-key"), :stop-tokens("stop")})
# :embedding-model("text-embedding-3-small")
# :evaluator(Whatever)
# :examples($[])
# :prompt-delimiter(" ")
# :base-url("https://api.openai.com/v1")
# :total-probability-cutoff(0.03)
# :api-key(Whatever)
# :prompts($[])
# :embedding-function(proto sub OpenAIEmbeddings ($prompt, :$model = Whatever, :$encoding-format = Whatever, :api-key(:$auth-key) is copy = Whatever, Int :$timeout where { ... } = 10, :$format is copy = Whatever, Str :$method = "tiny", Str :$base-url = "https://api.openai.com/v1") {*})
# :tool-prompt("")
# :max-tokens(2048)
# :stop-tokens($[])
# :format("values")
# :verbosity(Whatever)
# :tool-response-insertion-function(WhateverCode)
# :module("WWW::OpenAI")
# :model("gpt-3.5-turbo-instruct")
# :tool-request-parser(WhateverCode)
# :name("openai")
# :reasoning-effort(Whatever)
# :function(proto sub OpenAITextCompletion ($prompt is copy, :$model is copy = Whatever, :$suffix is copy = Whatever, :$max-tokens is copy = Whatever, :$temperature is copy = Whatever, Numeric :$top-p = 1, Int :$n where { ... } = 1, Bool :$stream = Bool::False, Bool :$echo = Bool::False, :$stop = Whatever, Numeric :$presence-penalty = 0, Numeric :$frequency-penalty = 0, :$best-of is copy = Whatever, :api-key(:$auth-key) is copy = Whatever, Int :$timeout where { ... } = 10, :$format is copy = Whatever, Str :$method = "tiny", Str :$base-url = "https://api.openai.com/v1") {*})
# :api-user-id("user:714782766884")
```

Here is the ChatGPT-based configuration:

```raku
.say for llm-configuration('ChatGPT').Hash;
```
```
# evaluator => (my \LLM::Functions::EvaluatorChat_6474669042944 = LLM::Functions::EvaluatorChat.new(context => "", examples => Whatever, user-role => "user", assistant-role => "assistant", system-role => "system", conf => LLM::Functions::Configuration.new(name => "chatgpt", api-key => Whatever, api-user-id => "user:811123441248", module => "WWW::OpenAI", base-url => "https://api.openai.com/v1", path => Whatever, model => "gpt-4.1-mini", function => proto sub OpenAIChatCompletion ($prompt is copy, :$role is copy = Whatever, :$model is copy = Whatever, :$temperature is copy = Whatever, :$max-tokens is copy = Whatever, Numeric :$top-p = 1, Int :$n where { ... } = 1, Bool :$stream = Bool::False, :$stop = Whatever, Numeric :$presence-penalty = 0, Numeric :$frequency-penalty = 0, :@images is copy = Empty, :$reasoning-effort = Whatever, :$verbosity = Whatever, :@tools = Empty, :api-key(:$auth-key) is copy = Whatever, Int :$timeout where { ... } = 10, :$format is copy = Whatever, Str:D :$method = "tiny", Str:D :$base-url = "https://api.openai.com/v1", Str:D :$path = "chat/completions") {*}, embedding-model => "text-embedding-3-small", embedding-function => proto sub OpenAIEmbeddings ($prompt, :$model = Whatever, :$encoding-format = Whatever, :api-key(:$auth-key) is copy = Whatever, Int :$timeout where { ... } = 10, :$format is copy = Whatever, Str :$method = "tiny", Str :$base-url = "https://api.openai.com/v1") {*}, temperature => 0.8, total-probability-cutoff => 0.03, max-tokens => 2048, format => "values", prompts => [], prompt-delimiter => " ", examples => [], stop-tokens => [], tools => [], tool-config => {}, tool-prompt => "", tool-request-parser => WhateverCode, tool-response-insertion-function => WhateverCode, images => [], reasoning-effort => Whatever, verbosity => Whatever, argument-renames => {:api-key("auth-key"), :stop-tokens("stop")}, evaluator => LLM::Functions::EvaluatorChat_6474669042944), formatron => "Str"))
# prompt-delimiter =>  
# reasoning-effort => (Whatever)
# module => WWW::OpenAI
# base-url => https://api.openai.com/v1
# verbosity => (Whatever)
# api-key => (Whatever)
# embedding-model => text-embedding-3-small
# api-user-id => user:811123441248
# format => values
# model => gpt-4.1-mini
# tools => []
# prompts => []
# max-tokens => 2048
# images => []
# argument-renames => {api-key => auth-key, stop-tokens => stop}
# embedding-function => &OpenAIEmbeddings
# stop-tokens => []
# name => chatgpt
# function => &OpenAIChatCompletion
# tool-response-insertion-function => (WhateverCode)
# total-probability-cutoff => 0.03
# temperature => 0.8
# examples => []
# tool-request-parser => (WhateverCode)
# tool-prompt =>
```

**Remark:** `llm-configuration(Whatever)` is equivalent to `llm-configuration('OpenAI')`.

**Remark:** Both the "OpenAI" and "ChatGPT" configuration use functions of the package "WWW::OpenAI", [AAp2].
The "OpenAI" configuration is for text-completions;
the "ChatGPT" configuration is for chat-completions. 

### Gemini-based

Here is the default Gemini configuration:

```raku
.say for llm-configuration('Gemini').Hash;
```
```
# prompts => []
# examples => []
# verbosity => (Whatever)
# argument-renames => {api-key => auth-key, max-tokens => max-output-tokens, stop-tokens => stop-sequences, tool-config => toolConfig}
# api-key => (Whatever)
# evaluator => (Whatever)
# stop-tokens => []
# total-probability-cutoff => 0
# base-url => https://generativelanguage.googleapis.com/v1beta/models
# tool-prompt => 
# max-tokens => 4096
# name => gemini
# api-user-id => user:217147130577
# embedding-model => embedding-001
# function => &GeminiGenerateContent
# reasoning-effort => (Whatever)
# tools => []
# module => WWW::Gemini
# temperature => 0.4
# embedding-function => &GeminiEmbedContent
# format => values
# prompt-delimiter =>  
# images => []
# tool-response-insertion-function => (WhateverCode)
# tool-request-parser => (WhateverCode)
# model => gemini-2.0-flash-lite
```

-----

## Basic usage of LLM functions

### Textual prompts

Here we make a LLM function with a simple (short, textual) prompt:

```raku
my &func = llm-function('Show a recipe for:');
```
```
# LLM::Function(-> $text = "", *%args { #`(Block|6474941406888) ... }, 'chatgpt')
```

Here we evaluate over a message: 

```raku
say &func('greek salad');
```
```
# Certainly! Here's a classic recipe for a refreshing Greek Salad:
# 
# ### Greek Salad Recipe
# 
# **Ingredients:**
# - 3 large ripe tomatoes, chopped
# - 1 cucumber, peeled and sliced
# - 1 green bell pepper, sliced into rings
# - 1 small red onion, thinly sliced
# - 1/2 cup Kalamata olives
# - 200g (about 7 oz) feta cheese, cut into cubes or crumbled
# - 2 tablespoons extra virgin olive oil
# - 1 tablespoon red wine vinegar (optional)
# - 1 teaspoon dried oregano
# - Salt and freshly ground black pepper, to taste
# 
# **Instructions:**
# 1. In a large bowl, combine the chopped tomatoes, cucumber, green peppers, red onion, and olives.
# 2. Add the feta cheese on top.
# 3. Drizzle the olive oil and red wine vinegar over the salad.
# 4. Sprinkle with dried oregano, salt, and black pepper.
# 5. Gently toss everything together to combine, or serve it with the feta on top un-mixed as preferred.
# 6. Serve immediately with crusty bread or as a side dish.
# 
# Enjoy your fresh and delicious Greek salad!
```

### Positional arguments

Here we make a LLM function with a function-prompt composed with a dedicated LLM numbers-only prompt and a numeric interpreter of the result:

```raku
use LLM::Prompts;

my &func2 = llm-function(
        {"How many $^a can fit inside one $^b?" ~ llm-prompt('NumericOnly')},
        form => Numeric,
        llm-evaluator => 'chatgpt');
```
```
# LLM::Function(-> **@args, *%args { #`(Block|6474967901528) ... }, 'chatgpt')
```

Here were we apply the function:

```raku
my $res2 = &func2("tennis balls", "toyota corolla 2010");
```
```
# 2702700
```

Here we show that we got a number:

```raku
$res2 ~~ Numeric
```
```
# False
```


### Named arguments

Here the first argument is a template with two named arguments: 

```raku
my &func3 = llm-function(-> :$dish, :$cuisine {"Give a recipe for $dish in the $cuisine cuisine."}, llm-evaluator => 'chatgpt');
```
```
# LLM::Function(-> **@args, *%args { #`(Block|6474967933384) ... }, 'chatgpt')
```

Here is an invocation:

```raku
&func3(dish => 'salad', cuisine => 'Russian', max-tokens => 300);
```
```
# Certainly! One classic Russian salad is **Olivier Salad**, also known as Russian Salad. It’s a popular dish in Russia, especially during celebrations and holidays.
# 
# ### Olivier Salad Recipe
# 
# #### Ingredients:
# - 3 medium potatoes
# - 2 medium carrots
# - 4 eggs
# - 200 grams cooked chicken breast (or boiled ham or bologna)
# - 150 grams peas (canned or boiled fresh)
# - 3-4 pickled cucumbers
# - 1 small onion (optional)
# - 200 grams mayonnaise
# - Salt to taste
# - Freshly ground black pepper (optional)
# 
# #### Instructions:
# 1. **Prepare the vegetables and eggs**:
#    - Boil the potatoes and carrots in their skins until tender (about 20-25 minutes). Let them cool, then peel.
#    - Hard boil the eggs (about 10 minutes), then cool and peel.
#    
# 2. **Chop all ingredients**:
#    - Dice the potatoes, carrots, eggs, pickled cucumbers, and chicken into small cubes (about 1 cm).
#    - Finely chop the onion if using.
#    
# 3. **Combine**:
#    - In a large bowl, mix the diced potatoes, carrots, eggs, chicken, peas, cucumbers, and onion.
#    
# 4. **Dress the salad**:
#    - Add mayonnaise, salt, and pepper to taste.
#    - Mix gently until everything is well coated.
#    
# 5. **Chill and serve**
```

--------

## LLM example functions

The function `llm-example-function` can be given a training set of examples in order 
to generating results according to the "laws" implied by that training set.  

Here a LLM is asked to produce a generalization:

```raku
llm-example-function([ 'finger' => 'hand', 'hand' => 'arm' ])('foot')
```
```
# leg
```

Here is an array of training pairs is used:

```raku
'Oppenheimer' ==> (["Einstein" => "14 March 1879", "Pauli" => "April 25, 1900"] ==> llm-example-function)()
```
```
# Output: April 22, 1904
```

Here is defined a LLM function for translating WL associations into Python dictionaries:

```raku
my &fea = llm-example-function( '<| A->3, 4->K1 |>' => '{ A:3, 4:K1 }');
&fea('<| 23->3, G->33, T -> R5|>');
```
```
# Output: { 23:3, G:33, T:R5 }
```

The function `llm-example-function` takes as a first argument:
- Single `Pair` object of two scalars
- Single `Pair` object of two `Positional` objects with the same length
- A `Hash`
- A `Positional` object of pairs

**Remark:** The function `llm-example-function` is implemented with `llm-function` and suitable prompt.

Here is an example of using hints:

```raku
my &fec = llm-example-function(
        ["crocodile" => "grasshopper", "fox" => "cardinal"],
        hint => 'animal colors');

say &fec('raccoon');
```
```
# Input: raccoon  
# Output: panda
```

--------

## Using predefined prompts

Using predefined prompts of the package ["LLM::Prompts"](https://raku.land/zef:antononcube/LLM::Prompts), [AAp8],
can be very convenient in certain (many) cases.

Here is an example using "Fixed That For You" synthesis:

```raku
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

```raku
my $prompt = 'You are a gem expert and you give concise answers.';
my $chat = llm-chat(chat-id => 'gem-expert-talk', conf => 'ChatGPT', :$prompt);
```
```
# LLM::Functions::Chat(chat-id = gem-expert-talk, llm-evaluator.conf.name = chatgpt, messages.elems = 0)
```

```raku
$chat.eval('What is the most transparent gem?');
```
```
# The most transparent gem is typically **diamond**. It has excellent clarity and allows light to pass through with minimal distortion, making it highly transparent.
```

```raku
$chat.eval('Ok. What are the second and third most transparent gems?');
```
```
# After diamond, the second and third most transparent gems are generally:
# 
# 2. **White sapphire** – known for its high clarity and good light transmission.  
# 3. **Zircon** – prized for its brilliance and transparency, sometimes confused with diamond.
```

Here are the prompt(s) and all messages of the chat object:

```raku
$chat.say
```
```
# Chat: gem-expert-talk
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# Prompts: You are a gem expert and you give concise answers.
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role : user
# content : What is the most transparent gem?
# timestamp : 2026-02-06T09:54:09.497688-05:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role : assistant
# content : The most transparent gem is typically **diamond**. It has excellent clarity and allows light to pass through with minimal distortion, making it highly transparent.
# timestamp : 2026-02-06T09:54:10.396412-05:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role : user
# content : Ok. What are the second and third most transparent gems?
# timestamp : 2026-02-06T09:54:10.419407-05:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role : assistant
# content : After diamond, the second and third most transparent gems are generally:
# 
# 2. **White sapphire** – known for its high clarity and good light transmission.  
# 3. **Zircon** – prized for its brilliance and transparency, sometimes confused with diamond.
# timestamp : 2026-02-06T09:54:12.232754-05:00
```

--------

## AI-vision functions

Consider [this image](https://raw.githubusercontent.com/antononcube/MathematicaForPrediction/master/MarkdownDocuments/Diagrams/AI-vision-via-WL/0iyello2xfyfo.png):

![](https://raw.githubusercontent.com/antononcube/MathematicaForPrediction/master/MarkdownDocuments/Diagrams/AI-vision-via-WL/0iyello2xfyfo.png)

Here we import the image (as a Base64 string):

```raku
use Image::Markup::Utilities;
my $url = 'https://raw.githubusercontent.com/antononcube/MathematicaForPrediction/master/MarkdownDocuments/Diagrams/AI-vision-via-WL/0iyello2xfyfo.png';
my $img = image-import($url);
$img.substr(^100)
```
```
# ![](data:image/jpeg;base64,iVBORw0KGgoAAAANSUhEUgAAArwAAAK8CAIAAACC2PsUAAAA1XpUWHRSYXcgcHJvZmlsZSB0e
```

Here we apply one of OpenAI's AI omni models (which is the default one) over the ***URL of the image***:

```raku
llm-vision-synthesize('Describe the image.', $url);
```
```
# The image is a bar chart titled "Cyber Week Spending Set to Hit New Highs in 2023." It shows estimated online spending on Thanksgiving weekend in the United States from 2019 to 2023. The data is divided into three categories: Thanksgiving Day, Black Friday, and Cyber Monday. Each year is represented by a different color: 2019 (light blue), 2020 (medium blue), 2021 (dark blue), 2022 (navy blue), and 2023 (yellow, marked as a forecast).
# 
# - **Thanksgiving Day**: Spending increases steadily each year, with 2023 projected to be the highest.
# - **Black Friday**: Spending remains relatively stable from 2020 to 2022, with a slight increase forecasted for 2023.
# - **Cyber Monday**: Shows the highest spending overall, with a significant increase projected for 2023.
# 
# The source of the data is Adobe Analytics, and the chart is created by Statista.
```


**Remark:** Currently, Gemini works with (Base64) images only (and does not with URLs.) OpenAI's vision works with both URLs and images.


The function `llm-vision-function` uses the same evaluators (configurations, models) as `llm-vision-synthesize`.

--------

## Potential problems

With Gemini with certain wrong configuration we get the error:

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
  - [X] CANCELED Random selection of LLM-evaluator
    - Currently, the LLM-evaluator of the LLM-functions and LLM-chats is static, assigned at creation.
    - This is easily implemented at "top-level." 
  - [X] DONE Chat class / object
    - For long conversations
  - [X] DONE Include LLaMA 
    - Just using a different `:$base-url` for "ChatGPT" for the configurations.
  - [X] DONE Include Gemini
    - [X] DONE Separate configuration
    - [X] DONE Its own evaluator class
  - [X] DONE LLM example function
    - [X] DONE First version with the signatures:
      - [X] `@pairs`
      - [X] `@input => @output`
      - [X] Hint option
    - [X] DONE Verify works with OpenAI 
    - [X] DONE Verify works with PaLM
      - Removed in version 0.5.5 since PaLM is obsoleted. 
    - [X] DONE Verify works with Gemini
    - [X] DONE Verify works with Ollama
  - [X] DONE Interpreter argument for `llm-function`
    - See the `formatron` attribute of `LLM::Functions::Evaluator`.
  - [X] DONE Adding `form` option to chat objects evaluator
  - [X] DONE Implement `llm-embedding` function
    - Generic, universal function for accessing the embeddings of different providers/models. 
  - [X] DONE Implement LLM-functor class `LLM::Function`
    - [X] DONE Class design & implementation
    - [X] DONE Make `&llm-function` return functors
      - And Block-functions based on the option `:$type`.
  - [X] DONE Implement LLM-tooling infrastructure
  - [ ] TODO Hook-up LLM-tooling for/in: 
    - [ ] TODO `&llm-synthesize`
    - [ ] TODO `&llm-function`
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
[LLM::Functions, Raku package](https://github.com/antononcube/Raku-LLM-Functions),
(2023),
[GitHub/antononcube](https://github.com/antononcube).

[AAp2] Anton Antonov,
[WWW::OpenAI, Raku package](https://github.com/antononcube/Raku-WWW-OpenAI),
(2023),
[GitHub/antononcube](https://github.com/antononcube).

[AAp3] Anton Antonov,
[WWW::PaLM, Raku package](https://github.com/antononcube/Raku-WWW-PaLM),
(2023),
[GitHub/antononcube](https://github.com/antononcube).

[AAp4] Anton Antonov,
[Text::SubParsers, Raku package](https://github.com/antononcube/Raku-Text-SubParsers),
(2023),
[GitHub/antononcube](https://github.com/antononcube).

[AAp5] Anton Antonov,
[Text::CodeProcessing, Raku package](https://github.com/antononcube/Raku-Text-CodeProcessing),
(2021),
[GitHub/antononcube](https://github.com/antononcube).

[AAp6] Anton Antonov,
[ML::FindTextualAnswer, Raku package](https://github.com/antononcube/Raku-ML-FindTextualAnswer),
(2023),
[GitHub/antononcube](https://github.com/antononcube).

[AAp7] Anton Antonov,
[ML::NLPTemplateEngine, Raku package](https://github.com/antononcube/Raku-ML-NLPTemplateEngine),
(2023),
[GitHub/antononcube](https://github.com/antononcube).

[AAp8] Anton Antonov,
[LLM::Prompts, Raku package](https://github.com/antononcube/Raku-LLM-Prompts),
(2023),
[GitHub/antononcube](https://github.com/antononcube).

[AAp9] Anton Antonov,
[WWW::MistralAI, Raku package](https://github.com/antononcube/Raku-WWW-MistralAI),
(2023),
[GitHub/antononcube](https://github.com/antononcube).

[AAp10] Anton Antonov,
[LLMPrompts, Python package](https://pypi.org/project/LLMPrompts/),
(2023),
[PyPI.org/antononcube](https://pypi.org/user/antononcube/).

[AAp11] Anton Antonov,
[WWW::Gemini, Raku package](https://github.com/antononcube/Raku-WWW-Gemini),
(2024),
[GitHub/antononcube](https://github.com/antononcube).

[AAp12] Anton Antonov,
[WWW::Ollama, Raku package](https://github.com/antononcube/Raku-WWW-Ollama),
(2026),
[GitHub/antononcube](https://github.com/antononcube).

[WRIp1] Wolfram Research, Inc.
[LLMFunctions paclet](https://resources.wolframcloud.com/PacletRepository/resources/Wolfram/LLMFunctions/),
(2023),
[Wolfram Language Paclet Repository](https://resources.wolframcloud.com/PacletRepository/).

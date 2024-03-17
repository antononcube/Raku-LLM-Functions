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
["WWW::PaLM"](https://raku.land/zef:antononcube/WWW::PaLM), [AAp3],
["WWW::MistralAI"](https://raku.land/zef:antononcube/WWW::MistralAI), [AAp9], and
["WWW::Gemini"](https://raku.land/zef:antononcube/WWW::Gemini), [AAp11].

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
# :evaluator(Whatever)
# :module("WWW::OpenAI")
# :function(proto sub OpenAITextCompletion ($prompt is copy, :$model is copy = Whatever, :$suffix is copy = Whatever, :$max-tokens is copy = Whatever, :$temperature is copy = Whatever, Numeric :$top-p = 1, Int :$n where { ... } = 1, Bool :$stream = Bool::False, Bool :$echo = Bool::False, :$stop = Whatever, Numeric :$presence-penalty = 0, Numeric :$frequency-penalty = 0, :$best-of is copy = Whatever, :api-key(:$auth-key) is copy = Whatever, Int :$timeout where { ... } = 10, :$format is copy = Whatever, Str :$method = "tiny", Str :$base-url = "https://api.openai.com/v1") {*})
# :max-tokens(300)
# :temperature(0.8)
# :prompts($[])
# :name("openai")
# :images($[])
# :tools($[])
# :api-key(Whatever)
# :api-user-id("user:109176182730")
# :base-url("https://api.openai.com/v1")
# :tool-prompt("")
# :tool-response-insertion-function(WhateverCode)
# :argument-renames(${:api-key("auth-key"), :stop-tokens("stop")})
# :stop-tokens($[])
# :examples($[])
# :format("values")
# :tool-request-parser(WhateverCode)
# :total-probability-cutoff(0.03)
# :model("gpt-3.5-turbo-instruct")
# :prompt-delimiter(" ")
```

Here is the ChatGPT-based configuration:

```perl6
.say for llm-configuration('ChatGPT').Hash;
```
```
# tool-request-parser => (WhateverCode)
# total-probability-cutoff => 0.03
# model => gpt-3.5-turbo
# api-user-id => user:475496933842
# images => []
# argument-renames => {api-key => auth-key, stop-tokens => stop}
# max-tokens => 300
# module => WWW::OpenAI
# tool-prompt => 
# format => values
# stop-tokens => []
# examples => []
# temperature => 0.8
# prompts => []
# tool-response-insertion-function => (WhateverCode)
# tools => []
# function => &OpenAIChatCompletion
# prompt-delimiter =>  
# api-key => (Whatever)
# base-url => https://api.openai.com/v1
# name => chatgpt
# evaluator => (my \LLM::Functions::EvaluatorChat_6288007030840 = LLM::Functions::EvaluatorChat.new(context => "", examples => Whatever, user-role => "user", assitant-role => "assistant", system-role => "system", conf => LLM::Functions::Configuration.new(name => "chatgpt", api-key => Whatever, api-user-id => "user:475496933842", module => "WWW::OpenAI", base-url => "https://api.openai.com/v1", model => "gpt-3.5-turbo", function => proto sub OpenAIChatCompletion ($prompt is copy, :$role is copy = Whatever, :$model is copy = Whatever, :$temperature is copy = Whatever, :$max-tokens is copy = Whatever, Numeric :$top-p = 1, Int :$n where { ... } = 1, Bool :$stream = Bool::False, :$stop = Whatever, Numeric :$presence-penalty = 0, Numeric :$frequency-penalty = 0, :@images is copy = Empty, :api-key(:$auth-key) is copy = Whatever, Int :$timeout where { ... } = 10, :$format is copy = Whatever, Str :$method = "tiny", Str :$base-url = "https://api.openai.com/v1") {*}, temperature => 0.8, total-probability-cutoff => 0.03, max-tokens => 300, format => "values", prompts => [], prompt-delimiter => " ", examples => [], stop-tokens => [], tools => [], tool-prompt => "", tool-request-parser => WhateverCode, tool-response-insertion-function => WhateverCode, images => [], argument-renames => {:api-key("auth-key"), :stop-tokens("stop")}, evaluator => LLM::Functions::EvaluatorChat_6288007030840), formatron => "Str"))
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
# tool-request-parser => (WhateverCode)
# stop-tokens => []
# images => []
# format => values
# name => palm
# api-user-id => user:948311569993
# argument-renames => {api-key => auth-key, max-tokens => max-output-tokens, stop-tokens => stop-sequences}
# examples => []
# api-key => (Whatever)
# prompt-delimiter =>  
# model => text-bison-001
# prompts => []
# temperature => 0.4
# function => &PaLMGenerateText
# tool-response-insertion-function => (WhateverCode)
# tool-prompt => 
# tools => []
# evaluator => (Whatever)
# module => WWW::PaLM
# max-tokens => 300
# total-probability-cutoff => 0
# base-url =>
```

-----

## Basic usage of LLM functions

### Textual prompts

Here we make a LLM function with a simple (short, textual) prompt:

```perl6
my &func = llm-function('Show a recipe for:');
```
```
# -> $text, *%args { #`(Block|6288098091184) ... }
```

Here we evaluate over a message: 

```perl6
say &func('greek salad');
```
```
# Ingredients:
# - 1 large cucumber, diced
# - 1 bell pepper, diced
# - 1 red onion, thinly sliced
# - 2-3 tomatoes, diced
# - 1 cup Kalamata olives, pitted
# - 1 cup feta cheese, crumbled
# - 1/4 cup extra virgin olive oil
# - 2 tablespoons red wine vinegar
# - 1 teaspoon dried oregano
# - Salt and pepper to taste
# 
# Instructions:
# 1. In a large salad bowl, combine the cucumber, bell pepper, red onion, tomatoes, and olives.
# 2. In a small bowl, whisk together the olive oil, red wine vinegar, oregano, salt, and pepper.
# 3. Pour the dressing over the vegetables and toss to combine.
# 4. Add the feta cheese on top of the salad.
# 5. Serve immediately or refrigerate for 1-2 hours to allow the flavors to meld together before serving. Enjoy your delicious Greek salad!
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
# -> **@args, *%args { #`(Block|6288154113224) ... }
```

Here were we apply the function:

```perl6
my $res2 = &func2("tennis balls", "toyota corolla 2010");
```
```
# 48
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
# -> **@args, *%args { #`(Block|6288120035248) ... }
```

Here is an invocation:

```perl6
&func3(dish => 'salad', cuisine => 'Russian', max-tokens => 300);
```
```
# **Ingredients:**
# 
# * 1 head of cabbage (chopped)
# * 2 carrots (grated)
# * 1 cucumber (chopped)
# * 1/2 red onion (chopped)
# * 1/2 cup of mayonnaise
# * 1/4 cup of sour cream
# * Salt and pepper to taste
# 
# **Instructions:**
# 
# 1. In a large bowl, combine the cabbage, carrots, cucumber, and onion.
# 2. In a small bowl, whisk together the mayonnaise, sour cream, salt, and pepper.
# 3. Pour the dressing over the salad and toss to coat.
# 4. Serve immediately or chill for later.
# 
# **Tips:**
# 
# * For a more flavorful salad, add some chopped fresh herbs, such as dill or parsley.
# * You can also add some protein to the salad, such as shredded chicken or crumbled bacon.
# * If you don't have any sour cream on hand, you can use yogurt or even just milk to thin out the mayonnaise.
# * This salad is best served cold, so make sure to chill it for at least a few hours before serving.
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
# panda
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
# Diamond is the most transparent gem.
```

```perl6
$chat.eval('Ok. What are the second and third most transparent gems?');
```
```
# The second most transparent gem is sapphire, and the third most transparent gem is emerald.
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
# timestamp	2024-03-17T15:35:54.133613-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role	assistant
# content	Diamond is the most transparent gem.
# timestamp	2024-03-17T15:35:54.831745-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role	user
# content	Ok. What are the second and third most transparent gems?
# timestamp	2024-03-17T15:35:54.846413-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role	assistant
# content	The second most transparent gem is sapphire, and the third most transparent gem is emerald.
# timestamp	2024-03-17T15:35:56.018877-04:00
```

--------

## AI-vision functions

Consider [this image](https://raw.githubusercontent.com/antononcube/MathematicaForPrediction/master/MarkdownDocuments/Diagrams/AI-vision-via-WL/0iyello2xfyfo.png):

![](https://raw.githubusercontent.com/antononcube/MathematicaForPrediction/master/MarkdownDocuments/Diagrams/AI-vision-via-WL/0iyello2xfyfo.png)

Here we import the image (as a Base64 string):

```perl6
use Image::Markup::Utilities;
my $url = 'https://raw.githubusercontent.com/antononcube/MathematicaForPrediction/master/MarkdownDocuments/Diagrams/AI-vision-via-WL/0iyello2xfyfo.png';
my $img = image-import($url);
$img.substr(^100)
```
```
# ![](data:image/jpeg;base64,iVBORw0KGgoAAAANSUhEUgAAArwAAAK8CAIAAACC2PsUAAAA1XpUWHRSYXcgcHJvZmlsZSB0e
```

Here we apply OpenAI's AI vision model `gpt-4-vision-preview` (which is the default one) over the ***URL of the image***:

```perl6
llm-vision-synthesize('Describe the image.', $url);
```
```
# The image is an infographic titled "Cyber Week Spending Set to Hit New Highs in 2023". It shows estimated online spending on Thanksgiving weekend in the United States for the years 2019 through 2023, with 2023 being a forecast. The data is presented in a bar chart format, with different colored bars representing each year.
# 
# There are three categories on the horizontal axis: Thanksgiving Day, Black Friday, and Cyber Monday. The vertical axis represents spending in billions of dollars, ranging from $0B to $12B.
# 
# The bars show an increasing trend in spending over the years for each of the three days. For Thanksgiving Day, the spending appears to have increased from just over $4B in 2019 to a forecast of around $6B in 2023. Black Friday shows a rise from approximately $7B in 2019 to a forecast of nearly $10B in 2023. Cyber Monday exhibits the highest spending, with an increase from around $9B in 2019 to a forecast of over $11B in 2023.
# 
# There is an icon of a computer monitor with a shopping tag, indicating the focus on online spending. At the bottom of the image, the source of the data is credited to Adobe Analytics, and the logo of Statista is present, indicating that they have produced or distributed the infographic. There are also two icons, one resembling a Creative Commons license and the other a share or export button.
```

Here we apply Gemini's AI vision model `gemini-pro-vision` over the image:

```perl6
llm-vision-synthesize('Describe the image.', $img, e => 'Gemini');
```
```
# The image shows the estimated online spending on Thanksgiving weekend in the United States from 2019 to 2023. The y-axis shows the spending amount in billions of dollars, while the x-axis shows the year. The data is presented in four bars, each representing a different year. The colors of the bars are blue, orange, green, and yellow, respectively. The values for each year are shown below:
# 
# * 2019: $7.4 billion
# * 2020: $9.0 billion
# * 2021: $10.7 billion
# * 2022: $11.3 billion
# * 2023: $12.2 billion (estimated)
# 
# The image shows that online spending on Thanksgiving weekend has increased steadily over the years. In 2023, online spending is expected to reach $12.2 billion, up from $7.4 billion in 2019.
```

**Remark:** Currently, Gemini works with (Base64) images only (and does not with URLs.) OpenAI's vision works with both URLs and images.


The function `llm-vision-function` uses the same evaluators (configurations, models) as `llm-vision-synthesize`.

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
    - [X] DONE Verify works with Gemini
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

[AAp11] Anton Antonov,
[WWW::Gemini Raku package](https://github.com/antononcube/Raku-WWW-Gemini),
(2024),
[GitHub/antononcube](https://github.com/antononcube).

[WRIp1] Wolfram Research, Inc.
[LLMFunctions paclet](https://resources.wolframcloud.com/PacletRepository/resources/Wolfram/LLMFunctions/),
(2023),
[Wolfram Language Paclet Repository](https://resources.wolframcloud.com/PacletRepository/).

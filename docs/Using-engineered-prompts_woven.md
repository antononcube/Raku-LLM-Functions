# Using engineered prompts

## Introduction

This document demonstrates the usage of
[engineered prompts](https://www.freecodecamp.org/news/how-to-communicate-with-ai-tools-prompt-engineering/)
with ChatGPT (OpenAI) and PaLM via the package
["LLM::Functions"](https://raku.land/zef:antononcube/LLM::Functions).

**Remark:** "Out of the box" 
["LLM::Functions"](https://raku.land/zef:antononcube/LLM::Functions) uses
["WWW::OpenAI"](https://raku.land/zef:antononcube/WWW::OpenAI), [AAp2], and 
["WWW::PaLM"](https://raku.land/zef:antononcube/WWW::PaLM), [AAp3]. 
Other LLM access packages can utilized via appropriate LLM configurations. 

**Remark:** In
["WWW::OpeAI"](https://raku.land/zef:antononcube/WWW::OpenAI)
engineered (pre-)prompts chat completions can be specified using Pair objects.
The engineered prompt has to be associated with the role "system".
(OpenAI API documentation chapter/section 
["Create chat completion"](https://platform.openai.com/docs/api-reference/chat/create) for details.)

Here the package is loaded:

```perl6
use LLM::Functions;
```
```
# (Any)
```

------

## Configurations

### ChatGPT

Here is the ChatGPT configuration:

```perl6
.say for llm-configuration('ChatGPT').Hash;
```
```
# format => values
# name => openai
# model => gpt-3.5-turbo
# tool-response-insertion-function => (WhateverCode)
# stop-tokens => [. ? !]
# module => WWW::OpenAI
# api-key => (Whatever)
# tools => []
# api-user-id => user:143318792976
# function => &OpenAIChatCompletion
# total-probability-cutoff => 0.03
# max-tokens => 300
# prompts => []
# tool-prompt => 
# prompt-delimiter =>  
# temperature => 0.8
# tool-request-parser => (WhateverCode)
# evaluator => (my \LLM::Functions::ChatEvaluator_4958840084504 = LLM::Functions::ChatEvaluator.new(conf => LLM::Functions::Configuration.new(name => "openai", api-key => Whatever, api-user-id => "user:143318792976", module => "WWW::OpenAI", model => "gpt-3.5-turbo", function => proto sub OpenAIChatCompletion ($prompt is copy, :$type is copy = Whatever, :$role is copy = Whatever, :$model is copy = Whatever, :$temperature is copy = Whatever, :$max-tokens is copy = Whatever, Numeric :$top-p = 1, Int :$n where { ... } = 1, Bool :$stream = Bool::False, :$stop = Whatever, Numeric :$presence-penalty = 0, Numeric :$frequency-penalty = 0, :$auth-key is copy = Whatever, Int :$timeout where { ... } = 10, :$format is copy = Whatever, Str :$method = "tiny") {*}, temperature => 0.8, total-probability-cutoff => 0.03, max-tokens => 300, format => "values", prompts => [], prompt-delimiter => " ", stop-tokens => [".", "?", "!"], tools => [], tool-prompt => "", tool-request-parser => WhateverCode, tool-response-insertion-function => WhateverCode, argument-renames => {:api-key("auth-key")}, evaluator => LLM::Functions::ChatEvaluator_4958840084504)))
```

### PaLM

Here is the PaLM configuration

```perl6
.say for llm-configuration('PaLM').Hash;
```
```
# evaluator => (Whatever)
# api-key => (Whatever)
# tool-response-insertion-function => (WhateverCode)
# name => palm
# tool-prompt => 
# prompt-delimiter =>  
# format => values
# api-user-id => user:892002494573
# prompts => []
# function => &PaLMGenerateText
# stop-tokens => [. ? !]
# temperature => 0.4
# model => text-bison-001
# module => WWW::PaLM
# max-tokens => 300
# total-probability-cutoff => 0
# tool-request-parser => (WhateverCode)
# tools => []
```


------

### Emojify

Here is a prompt for "emojification" (see the
[Wolfram Prompt Repository](https://resources.wolframcloud.com/PromptRepository/)
entry
["Emojify"](https://resources.wolframcloud.com/PromptRepository/resources/Emojify/)):

```perl6
my $preEmojify = q:to/END/;
Rewrite the following text and convert some of it into emojis.
The emojis are all related to whatever is in the text.
Keep a lot of the text, but convert key words into emojis.
Do not modify the text except to add emoji.
Respond only with the modified text, do not include any summary or explanation.
Do not respond with only emoji, most of the text should remain as normal words.
END
```
```
# Rewrite the following text and convert some of it into emojis.
# The emojis are all related to whatever is in the text.
# Keep a lot of the text, but convert key words into emojis.
# Do not modify the text except to add emoji.
# Respond only with the modified text, do not include any summary or explanation.
# Do not respond with only emoji, most of the text should remain as normal words.
```

Here we create a Chat-GPT-based LLM-function to do "emojification" with:

```perl6
my &gptEmojify = llm-function($preEmojify, llm-evaluator => 'ChatGPT'); 
```
```
# -> $text, *%args { #`(Block|4958840391520) ... }
```

Here is an example of chat completion with emojification:

```perl6
gptEmojify('Python sucks, Raku rocks, and Perl is annoying');
```
```
# 🐍 Python 🙅‍♂️, Raku 🤘, and Perl 😒
```

Here we create PaLM-based LLM-function:

```perl6
my &palmEmojify = llm-function($preEmojify, llm-evaluator => 'PaLM'); 
```
```
# -> $text, *%args { #`(Block|4958878361784) ... }
```

Here is an invocation over the same text:

```perl6
palmEmojify('Python sucks, Raku rocks, and Perl is annoying');
```
```
# 🐍 👎, 🦀 👍, 🐍 😒
```

---------

## Limerick styled

Here is a prompt for "limerick styling" (see the
[Wolfram Prompt Repository](https://resources.wolframcloud.com/PromptRepository/)
entry
["LimerickStyled"](https://resources.wolframcloud.com/PromptRepository/resources/LimerickStyled/)).

```perl6
my $preLimerick = q:to/END/;
Respond in the form of a limerick.
You must always observe the correct rhyme scheme for a limerick
END
```
```
# Respond in the form of a limerick.
# You must always observe the correct rhyme scheme for a limerick
```

Here is an example limerick rephrasing of descriptions of Raku modules:

```perl6
my @descriptions = [
    "Raku SDK for Resend",
    "A module that allows true inline use of Brainfuck code",
    "ML::FindTextualAnswer provides function(s) for finding sub-strings in given text that appear to answer given questions.",
];

my &gptLimerick = llm-function($preLimerick, llm-evaluator => 'ChatGPT');

for @descriptions -> $d {
    say '=' x 80;
    say $d;
    say '-' x 80;
    say &gptLimerick($d);
}
```
```
# ================================================================================
# Raku SDK for Resend
# --------------------------------------------------------------------------------
# There once was a coder named Fred,
# Who needed an SDK to embed.
# With Raku in hand,
# He could easily command,
# And his code was a masterpiece, widespread.
# ================================================================================
# A module that allows true inline use of Brainfuck code
# --------------------------------------------------------------------------------
# There once was a module, quite neat,
# For Brainfuck it offered a treat.
# Inline use was its aim,
# With rhyme scheme to claim,
# Coding tricks in a limerick, sweet!
# ================================================================================
# ML::FindTextualAnswer provides function(s) for finding sub-strings in given text that appear to answer given questions.
# --------------------------------------------------------------------------------
# When searching for text that's been sought,
# ML::FindTextualAnswer's been brought.
# With functions precise,
# It finds answers nice,
# To questions, it's surely a thought.
```

-------

## Finding textual answers

Here is a prompt for finding textual answers (i.e. substrings that appear to be answers to given questions):

```perl6
my $preFTA = q:to/END/;
The following text describes elements of a computational workflow.
Answer the questions appropriate for computer programming processings.
Answer the questions concisely.
DO NOT use the word "and" as list separator. Separate list elements with commas.
DO NOT number the list or the items of the list.
Give preference to numeric results, and Yes/No results.
Try to put the question-answer pairs in GitHub Markdown table.
END
```
```
# The following text describes elements of a computational workflow.
# Answer the questions appropriate for computer programming processings.
# Answer the questions concisely.
# DO NOT use the word "and" as list separator. Separate list elements with commas.
# DO NOT number the list or the items of the list.
# Give preference to numeric results, and Yes/No results.
# Try to put the question-answer pairs in GitHub Markdown table.
```

Here we make a special configuration with the prompt above:

```perl6
my $conf = llm-configuration('ChatGPT', prompts => [$preFTA,]);
```
```
# prompts	The following text describes elements of a computational workflow.
# Answer the questions appropriate for computer programming processings.
# Answer the questions concisely.
# DO NOT use the word "and" as list separator. Separate list elements with commas.
# DO NOT number the list or the items of the list.
# Give preference to numeric results, and Yes/No results.
# Try to put the question-answer pairs in GitHub Markdown table.
#  format	values tool-prompt	 tool-request-parser	WhateverCode function	OpenAIChatCompletion api-user-id	user:403821603985 total-probability-cutoff	0.03 model	gpt-3.5-turbo name	openai evaluator	LLM::Functions::ChatEvaluator<4958945034416> api-key	Whatever temperature	0.8 tools	 max-tokens	300 module	WWW::OpenAI prompt-delimiter	  tool-response-insertion-function	WhateverCode stop-tokens	. ? !
```

Here we create a LLM-function that uses a function-prompt:

```perl6
my &gptFTA = llm-function( -> $cmd, @qs { "Given the text: $cmd, answer the questions {@qs.join(' ')}." }, llm-evaluator => $conf);
```
```
# -> **@args, *%args { #`(Block|4958866010344) ... }
```

**Remark:** At this point the function `&gptFTA` has the "chat-global" LLM prompt `$preFTA` 
and gives the LLM messages based on a template takes a command (`$cmd`) and an array of questions (`@qs`.)

Here is a computational workflow specification:

```perl6
my $command = 'Make a classifier with the method RandomForest over the data dfTitanic; show recall, precision and accuracy; split the data with ratio 0.73';
```
```
# Make a classifier with the method RandomForest over the data dfTitanic; show recall, precision and accuracy; split the data with ratio 0.73
```

Here are related questions:

```perl6
my @questions =
        ['What is the dataset?',
         'What is the method?',
         'Which metrics to show?',
         'What is the splitting ratio?',
         'How to split the data?',
         'Are ROC metrics specified?'   
        ];
```
```
# [What is the dataset? What is the method? Which metrics to show? What is the splitting ratio? How to split the data? Are ROC metrics specified?]
```

Here we find the answers of the questions:

```perl6, results=asis
&gptFTA($command, @questions);
```
| Question | Answer |
| --- | --- |
| What is the dataset? | dfTitanic |
| What is the method? | RandomForest |
| Which metrics to show? | Recall, Precision, Accuracy |
| What is the splitting ratio? | 0.73 |
| How to split the data? | Not specified |
| Are ROC metrics specified? | No |


**Remark:** The code cell above has the parameter `results=asis` which instructs
the CLI program `file-code-chunks-eval` of the package 
["Text::CodeProcessing"](https://raku.land/zef:antononcube/Text::CodeProcessing), [AAp4], 
to place the LLM result without changes. 

**Remark:** If the result adheres to conventions of GitHub's Markdown table specifications, 
then GitHub (and IDEs like IntelliJ) would render the table. 
The result adherence is "very likely" -- see the last line of the prompt.

-------

## References

### Packages, repositories

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

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
Other LLM access packages can utilizes via appropriate LLM configurations. 

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

------

## Configurations

### ChatGPT

Here is the ChatGPT configuration:

```perl6
.say for llm-configuration('ChatGPT').Hash;
```

### PaLM

Here is the PaLM configuration

```perl6
.say for llm-configuration('PaLM').Hash;
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

Here we create a Chat-GPT-based LLM-function to do "emojification" with:

```perl6
my &gptEmojify = llm-function($preEmojify, llm-evaluator => 'ChatGPT'); 
```

Here is an example of chat completion with emojification:

```perl6
gptEmojify('Python sucks, Raku rocks, and Perl is annoying');
```

Here we create PaLM-based LLM-function:

```perl6
my &palmEmojify = llm-function($preEmojify, llm-evaluator => 'PaLM'); 
```

Here is an invocation over the same text:

```perl6
palmEmojify('Python sucks, Raku rocks, and Perl is annoying');
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

Here we make a special configuration with the prompt above:

```perl6
my $conf = llm-configuration('ChatGPT', prompts => [$preFTA,]);
```

Here we create a LLM-function that uses a function-prompt:

```perl6
my &gptFTA = llm-function( -> $cmd, @qs { "Given the text: $cmd, answer the questions {@qs.join(' ')}." }, llm-evaluator => $conf);
```

**Remark:** At this point the function `&gptFTA` has the "chat-global" LLM prompt `$preFTA` 
and gives the LLM messages based on a template takes a command (`$cmd`) and an array of questions (`@qs`.)

Here is a computational workflow specification:

```perl6
my $command = 'Make a classifier with the method RandomForest over the data dfTitanic; show recall, precision and accuracy; split the data with ratio 0.73';
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

Here we find the answers of the questions:

```perl6, results=asis
&gptFTA($command, @questions);
```

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

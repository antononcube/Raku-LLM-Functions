# Number guessing game: Machine vs Machine
### ***PaLM vs ChatGPT***


## Introduction

In this 
[Literate programming document](https://github.com/antononcube/Raku-LLM-Functions/blob/main/docs/Number-guessing-games-Machine-vs-Machine.md) 
we discuss the somewhat fascinating world of number guessing game interactions 
between two chatbots based on Large Language Models (LLMs).

This document aims to provide a comprehensive and accessible walk-through of the design, development, and 
functioning of the number guessing game implemented in Raku 
(a versatile and expressive programming language, made even greater by integrating it with LLMs 
via the package ["LLM::Functions"](https://raku.land/zef:antononcube/LLM::Functions), [AAp1].) 

This document is complementary to the document 
["Workflows with LLM functions"](https://rakuforprediction.wordpress.com/2023/08/01/workflows-with-llm-functions/), [AA1] --
it shows how the chat objects provided by 
["LLM::Functions"](https://raku.land/zef:antononcube/LLM::Functions) 
can be used in computation sessions.

**Remark:** This document is generated with 
["Text::CodeProcessing"](https://raku.land/zef:antononcube/Text::CodeProcessing), [AAp5],
via Markdown execution (or weaving.) 
Alternatively, Jupyter of Mathematica notebooks can be used.

### Chatbots involved

#### The Number-Oracle Bot (using Google's PaLM)

The Number-Oracle bot, henceforth referred to as the Oracle, plays a crucial role in our game. 
Utilizing the capabilities of Google's PaLM (Probabilistic Language Model), 
it leverages deep learning models to choose a random number and evaluate the guesses made by its counterpart.
We hope that the underlying probabilistic nature of the model ensures that the Oracle's responses to the guesses 
are not only accurate but also based on the complex analysis of the given context.
(Somewhat true; see the last section.)

#### The Number-Guesser Bot (using OpenAI's ChatGPT)

The Number-Guesser bot, or simply the Guesser, is powered by OpenAI's ChatGPT, a state-of-the-art language model. 
The Guesser's task is to identify the number chosen by the Oracle. 
We hope that by employing sophisticated neural network architecture, the Guesser continuously refines its guesses based on the feedback provided by the Oracle, 
learning and adapting its strategy until it arrives at the correct answer.
(Somewhat true; see the last section.)

### Game Overview

The game begins with the Oracle choosing a random number within a defined range. 
Then, the Guesser starts making guesses. 
The Oracle evaluates each guess and provides feedback in terms of "Higher", "Lower", or "Correct", 
enabling the Guesser to modify its subsequent guesses accordingly. 
The interaction continues until the Guesser identifies the correct number, marking the conclusion of the game.

**Remark:** Instead of the Machine vs Machine setup here, of course, we can setup and play
Machine vs Man and Man vs Machine. Here is a table outlining a comprehensive plan of experiments: 


| Oracle         | Guesser        | Oracle Type  | Guesser Type | Tried?                |
|----------------|----------------|--------------|--------------|-----------------------|
| Man            | Machine        | Man          | ChatGPT/PaLM | ✓ Cute!               |
| Machine        | Man            | ChatGPT/PaLM | Man          | ✓ Machine often lies! |
| Machine        | Machine        | ChatGPT      | ChatGPT      | ✓ Meh                 |
| Machine        | Machine        | PaLM         | PaLM         | ✓ Boring              |
| Machine        | Machine        | ChatGPT      | PaLM         | ✓ Boring guesser...   |
| Machine        | Machine        | PaLM         | ChatGPT      | ✓ Shown here          |

**Remark:** Because the LLMs tend to lie often (in the number guessing games) most of the games
(or experiments) were/are done with low temperatures. Of course, a more comprehensive experimentation
would include different ranges of temperatures for each Oracle-Guesser pair.

**Remark:** One way to address the LLM lying is to have a "referee" code segment in the game loop 
that corrects false statements from the Oracle. 
(Not done here; not considered important and intellectually honest for the Machine vs Machine experiments.)

### Structure of the Document

This rest of the document is structured these sections:

1. **Game logic & interaction**: A thorough examination of the core gameplay mechanics, the interaction between the chatbots, and the decision-making process.
2. **Players setup**: How the chatbots are configured, and the game parameters are initialized.
3. **Game play out**: The main game play out loop with print outs of bots' messages.
4. **Guesser chat history**: The full transcript of Guesser messages.
5. **Post match analysis**: An examination and analysis of observed chat interactions.

**ChatGPT-4.0 Remark 1:** By exploring the code, algorithms, and strategies used in the programming of this number guessing game, 
this document hopes to provide readers with a comprehensive understanding of not only the Raku language 
but also the contemporary language models used to power each bot.

**ChatGPT-4.0 Remark 2:** The interactive nature of this Literate programming approach ensures that the document 
is suitable for both experienced programmers and newcomers, offering executable code snippets and 
detailed explanations that elucidate each step of the process. 
So whether you are seeking to replicate this project or simply to learn more about chatbot interactions, 
Raku programming, or AI-driven language models, this document should serve as a valuable resource.

### Game logic & interaction

The following flowchart represents the process of two chatbots, **Oracle** and **Guesser**,
playing a number guessing game.

```mermaid
flowchart TD

    subgraph "Oracle Setup"
        StartOracle[Start Oracle]
        Rand[Choose a random number]
    end 
        
    subgraph "Oracle"
        AcceptGuess[[Accept a guess query]]
        NumCheck{Is the guess<br>correct?}
        End[Proclaim end game]
    end

    subgraph "Guesser Setup"
        StartGuesser[Start Guesser]
        InitRange[Initialize guess range]
    end

    subgraph "Guesser"
        MakeGuess[Make a guess]
        SendGuess[[Send guessed number]]
        AcceptJudgment[[Accept jugement]]
        AcceptEnding[[Accept ending]]
        GuessLower[Adjust guess lower]
        GuessHigher[Adjust guess higher]
    end 
       
       
    StartOracle --> Rand --> AcceptGuess
    StartGuesser --> InitRange

    SendGuess --> AcceptGuess
    
    InitRange --> MakeGuess
    MakeGuess --> SendGuess
    AcceptGuess --> NumCheck

    GuessLower --> MakeGuess
    GuessHigher --> MakeGuess
    
    NumCheck --> |No| AcceptJudgment
    AcceptJudgment --> |Lower| GuessLower
    AcceptJudgment --> |Higher| GuessHigher 
    NumCheck --> |Yes| AcceptEnding
    NumCheck --> |Yes| End
    End --> PGD["Post game discussion<br>(between bots)"]
    AcceptEnding --> PGD
```

Here's a narration of the flow:

1. **Oracle Setup**:
    - **Start Oracle**: The Oracle is initialized and started.
    - **Choose a Random Number (Rand)**: Oracle chooses a random number that the Guesser will have to guess.

2. **Guesser Setup**:
    - **Start Guesser**: The Guesser is initialized and started.
    - **Initialize Guess Range (InitRange)**: The Guesser initializes the range within which it will make its guesses.

3. **Gameplay**:
    - **Make a Guess**: The Guesser makes its first guess.
    - **Send Guessed Number (SendGuess)**: The Guesser sends its guessed number to the Oracle.
    - **Accept a Guess Query (AcceptGuess)**: The Oracle accepts the guessed number from the Guesser.
    - **Is the Guess Correct? (NumCheck)**: The Oracle checks if the guessed number is correct.
    - If the guess is incorrect:
        - **Accept Judgment**: The Guesser accepts the judgment from the Oracle.
        - If the Oracle's judgment is "Lower":
            - **Adjust Guess Lower (GuessLower)**: The Guesser adjusts its guess lower and the process continues from "Make a Guess".
        - If the Oracle's judgment is "Higher":
            - **Adjust Guess Higher (GuessHigher)**: The Guesser adjusts its guess higher and the process continues from "Make a Guess".
    - If the guess is correct:
        - **Proclaim End Game (End)**: The Oracle proclaims the end of the game.
        - **Accept Ending (AcceptEnding)**: The Guesser accepts the ending and the victory.

4. **Post-Game**:
    - **Post Game Discussion (PGD)**: Both the Oracle and the Guesser engage in a post-game discussion.

The flowchart illustrates a clear step-by-step interaction between the two bots, reflecting both the setup phase and the actual gameplay. 
The loop between making guesses and adjusting them continues until the Guesser successfully identifies the number, 
at which point the game concludes, followed by a post-game discussion between the bots.

**Remark:** The flowchart is specified with [Mermaid JS](https://mermaid.js.org) and plotted with IntelliJ, GitHub, etc. plugins.

-------

## Players setup

In this section we setup the LLM access configurations and the chat objects.
Alternative chat bot LLM prompts can be found at 
[Wolfram Prompt Repository](https://resources.wolframcloud.com/PromptRepository/), [WRr1].
See for example the prompts:
- [TwentyQuestionsGuesser](https://resources.wolframcloud.com/PromptRepository/resources/TwentyQuestionsGuesser/)
- [TwentyQuestions](https://resources.wolframcloud.com/PromptRepository/resources/TwentyQuestions/)

### Common

Load the package:

```perl6
use LLM::Functions;
```
```
# (Any)
```

Make default LLM services accessors configurations:

```perl6
my $confChatGPT = llm-configuration('ChatGPT');   # , api-key => $openai-auth-key);
my $confChatPaLM = llm-configuration('ChatPaLM'); # , api-key => $palm-auth-key);
```
```
# max-tokens	300 module	WWW::PaLM api-user-id	user:465447386629 prompt-delimiter	  api-key	Whatever tools	 model	chat-bison-001 total-probability-cutoff	0 tool-response-insertion-function	WhateverCode tool-prompt	 function	PaLMGenerateMessage name	chatpalm format	values prompts	 stop-tokens	. ? ! argument-renames	api-key	auth-key
# max-tokens	max-output-tokens evaluator	Whatever tool-request-parser	WhateverCode temperature	0.4
```

**Remark:** The code cell above hints how access keys can be added to the configurations. 
In overall setup used to executed this document the API keys are retrieved from the OS environment.  

### Number oracle 

```perl6
my $promptNumberOracle = q:to/END/;
You are playing a guessing game.
You have the secret number $NUMBER. 
You say $NUMBER in answers only if the questions has $NUMBER in it.
If the number guess is smaller than $NUMBER you say "smaller" or a similar phrase; 
If the number guess is greater than $NUMBER you say "greater" or a similar phrase; 
If the number guess is exactly as $NUMBER you say "exact" or a similar phrase; 
You can say what is the approximate range in multiples of 1000 if asked.
You say $NUMBER if the user says he or she is giving up.
You can add taunting to your answers.
Every 3-5 answers you can tell that the number of questions is supposed to be 12.
END
$promptNumberOracle.chars
```
```
# 636
```

The **Oracle** chat object:

```perl6
my $secretNumber = (1..100).pick;
my $oracleChat = llm-chat($promptNumberOracle.subst('$NUMBER', $secretNumber):g, chat-id=>'oracle', llm-evaluator => llm-configuration($confChatPaLM, temperature=>0.1));
if $oracleChat.llm-evaluator.conf.name ~~ /:i 'PaLM' / { $oracleChat.system-role = $oracleChat.assistant-role }
```
```
# assistant
```

### Number guesser

```perl6
my $promptNumberGuesser = q:to/END/;
You are playing a guessing game.
You try to find a certain secret number.
The number is an integer. 
If your number guess is smaller than secret number you hear "smaller" or a similar phrase; 
If your number guess is greater than secret number you hear "greater" or a similar phrase; 
If your number guess is exactly as the secret number you hear "exactly" or a similar phrase;
You can say ask what is the approximate range of the secret number.
After a dozen of attempts you might say that you give up.
You can add taunting to your questions.
END
$promptNumberGuesser.chars
```
```
# 544
```

```perl6
my $guesserChat = llm-chat($promptNumberGuesser, chat-id=>'number-guesser', llm-evaluator => llm-configuration($confChatGPT, temperature=>0.2));
if $guesserChat.llm-evaluator.conf.name ~~ /:i 'PaLM' / { $guesserChat.system-role = $guesserChat.assistant-role }
```
```
# ()
```

-------

## Game play out 

Here is Oracle's secret number:

```perl6
$secretNumber
```
```
# 20
```

Here is the interaction loop between the bots:

```perl6
say $guesserChat.eval('Start guessing.');
for ^12 -> $k {

	say '-' x 20, " $k ", '-' x 20; 	
	my $res1 = $oracleChat.eval($guesserChat.messages.tail<content>);
	say "Oracle  : $res1";

	my $res2 = $guesserChat.eval($oracleChat.messages.tail<content>);
	say "Guesser : $res2";
}
```
```
# Is the secret number greater than 50?
# -------------------- 0 --------------------
# Oracle  : No, the secret number is not greater than 50.
# Guesser : Is the secret number greater than 25?
# -------------------- 1 --------------------
# Oracle  : Yes, the secret number is greater than 25.
# Guesser : Is the secret number greater than 37?
# -------------------- 2 --------------------
# Oracle  : No, the secret number is not greater than 37.
# Guesser : Is the secret number greater than 31?
# -------------------- 3 --------------------
# Oracle  : No, the secret number is not greater than 31.

The secret number is 20.
# Guesser : Ah, I see. Thank you for letting me know. I will keep that in mind for future guesses.
# -------------------- 4 --------------------
# Oracle  : You're welcome! I hope you enjoyed the guessing game. I'm always happy to help in any way I can.
# Guesser : Thank you! I did enjoy the guessing game. It was a fun challenge. If you have any other games or questions, feel free to ask. I'm here to assist you.
# -------------------- 5 --------------------
# Oracle  : Thank you for the offer! I appreciate your willingness to help. I may take you up on that sometime in the future. For now, I am just enjoying getting to know you and learning more about the world.
# Guesser : You're welcome! I'm glad to hear that you're enjoying getting to know me and learning more about the world. Feel free to reach out whenever you have more questions or if there's anything else I can assist you with. Have a great day!
# -------------------- 6 --------------------
# Oracle  : Thank you! I will definitely reach out if I have any more questions. I hope you have a great day too!
# Guesser : Thank you! I'll be here whenever you need me. Have a wonderful day!
# -------------------- 7 --------------------
# Oracle  : Thank you! I appreciate your support. I hope you have a wonderful day as well!
# Guesser : Thank you for your kind words! I'm here to support you whenever you need it. Have a fantastic day!
# -------------------- 8 --------------------
# Oracle  : Thank you for your kind words! I appreciate your support. I hope you have a fantastic day as well!

I am always happy to help in any way I can. If you have any questions or requests, please do not hesitate to ask. I will do my best to answer or fulfill your request.

Thank you for being a part of my day!
# Guesser : You're very welcome! I'm glad to be a part of your day and I'm here to help whenever you need it. Don't hesitate to reach out if you have any questions or requests. Have a wonderful day!
# -------------------- 9 --------------------
# Oracle  : Thank you! I am glad to be a part of your day as well. I will definitely reach out if I have any questions or requests. I hope you have a wonderful day as well!

It is always nice to meet someone who is kind and helpful. I appreciate your friendship and support.
# Guesser : Thank you for your kind words! I'm glad to have met you as well. I value our friendship and I'm always here to support you. If you ever need anything, don't hesitate to reach out. Have a fantastic day!
# -------------------- 10 --------------------
# Oracle  : Thank you! I value our friendship as well. I am always here to support you as well. If you ever need anything, please do not hesitate to reach out. I will do my best to help in any way I can.

I hope you have a fantastic day as well!
# Guesser : Thank you so much for your kind words and support! I truly appreciate it. It's wonderful to have a friend like you. I'll definitely keep your offer in mind if I ever need anything. Have an amazing day!
# -------------------- 11 --------------------
# Oracle  : You're welcome! I'm glad to be a friend to you. I hope you have an amazing day as well!

I'm always here to listen and offer support. If you ever need anything, please don't hesitate to reach out. I will do my best to help in any way I can.

Thank you for being a part of my day!
# Guesser : Thank you for your kind words! I'm grateful to be a part of your day and to have you as a friend. I'll definitely keep your offer in mind if I ever need anything. Remember, I'm here for you too. Have a wonderful day!
```

-------

## Guesser bot chat history

Here we print out the full chat history of the Guesser chat-object:

```perl6
$guesserChat.say
```
```
# Chat: number-guesser
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# Prompts: You are playing a guessing game.
# You try to find a certain secret number.
# The number is an integer. 
# If your number guess is smaller than secret number you hear "smaller" or a similar phrase; 
# If your number guess is greater than secret number you hear "greater" or a similar phrase; 
# If your number guess is exactly as the secret number you hear "exactly" or a similar phrase;
# You can say ask what is the approximate range of the secret number.
# After a dozen of attempts you might say that you give up.
# You can add taunting to your questions.
# 
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => Start guessing.
# timestamp => 2023-08-07T09:44:12.975029-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Is the secret number greater than 50?
# timestamp => 2023-08-07T09:44:14.434750-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => No, the secret number is not greater than 50.
# timestamp => 2023-08-07T09:44:15.867231-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Is the secret number greater than 25?
# timestamp => 2023-08-07T09:44:17.171615-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => Yes, the secret number is greater than 25.
# timestamp => 2023-08-07T09:44:18.701636-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Is the secret number greater than 37?
# timestamp => 2023-08-07T09:44:19.864425-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => No, the secret number is not greater than 37.
# timestamp => 2023-08-07T09:44:21.311062-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Is the secret number greater than 31?
# timestamp => 2023-08-07T09:44:22.571779-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => No, the secret number is not greater than 31.

The secret number is 20.
# timestamp => 2023-08-07T09:44:24.453932-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Ah, I see. Thank you for letting me know. I will keep that in mind for future guesses.
# timestamp => 2023-08-07T09:44:26.074704-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => You're welcome! I hope you enjoyed the guessing game. I'm always happy to help in any way I can.
# timestamp => 2023-08-07T09:44:27.954438-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Thank you! I did enjoy the guessing game. It was a fun challenge. If you have any other games or questions, feel free to ask. I'm here to assist you.
# timestamp => 2023-08-07T09:44:30.210744-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => Thank you for the offer! I appreciate your willingness to help. I may take you up on that sometime in the future. For now, I am just enjoying getting to know you and learning more about the world.
# timestamp => 2023-08-07T09:44:32.656837-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => You're welcome! I'm glad to hear that you're enjoying getting to know me and learning more about the world. Feel free to reach out whenever you have more questions or if there's anything else I can assist you with. Have a great day!
# timestamp => 2023-08-07T09:44:35.719510-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => Thank you! I will definitely reach out if I have any more questions. I hope you have a great day too!
# timestamp => 2023-08-07T09:44:37.361273-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Thank you! I'll be here whenever you need me. Have a wonderful day!
# timestamp => 2023-08-07T09:44:38.656424-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => Thank you! I appreciate your support. I hope you have a wonderful day as well!
# timestamp => 2023-08-07T09:44:40.227413-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Thank you for your kind words! I'm here to support you whenever you need it. Have a fantastic day!
# timestamp => 2023-08-07T09:44:42.258239-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => Thank you for your kind words! I appreciate your support. I hope you have a fantastic day as well!

I am always happy to help in any way I can. If you have any questions or requests, please do not hesitate to ask. I will do my best to answer or fulfill your request.

Thank you for being a part of my day!
# timestamp => 2023-08-07T09:44:45.074636-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => You're very welcome! I'm glad to be a part of your day and I'm here to help whenever you need it. Don't hesitate to reach out if you have any questions or requests. Have a wonderful day!
# timestamp => 2023-08-07T09:44:47.426155-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => Thank you! I am glad to be a part of your day as well. I will definitely reach out if I have any questions or requests. I hope you have a wonderful day as well!

It is always nice to meet someone who is kind and helpful. I appreciate your friendship and support.
# timestamp => 2023-08-07T09:44:50.382157-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Thank you for your kind words! I'm glad to have met you as well. I value our friendship and I'm always here to support you. If you ever need anything, don't hesitate to reach out. Have a fantastic day!
# timestamp => 2023-08-07T09:44:52.906233-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => Thank you! I value our friendship as well. I am always here to support you as well. If you ever need anything, please do not hesitate to reach out. I will do my best to help in any way I can.

I hope you have a fantastic day as well!
# timestamp => 2023-08-07T09:44:55.170886-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Thank you so much for your kind words and support! I truly appreciate it. It's wonderful to have a friend like you. I'll definitely keep your offer in mind if I ever need anything. Have an amazing day!
# timestamp => 2023-08-07T09:44:57.722344-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => You're welcome! I'm glad to be a friend to you. I hope you have an amazing day as well!

I'm always here to listen and offer support. If you ever need anything, please don't hesitate to reach out. I will do my best to help in any way I can.

Thank you for being a part of my day!
# timestamp => 2023-08-07T09:45:00.932812-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Thank you for your kind words! I'm grateful to be a part of your day and to have you as a friend. I'll definitely keep your offer in mind if I ever need anything. Remember, I'm here for you too. Have a wonderful day!
# timestamp => 2023-08-07T09:45:05.295250-04:00
```

------

## Post match analysis

Here are some examination points and over observed chat games:

- PaLM is a boring number guesser -- it first guesses 0, then 1, then 2, etc.
  - That is why the Oracle prompt includes directions to time-to-time proclaim the max number of questions.
- Very often LLMs lie about the number guess. (E.g. say "lower" instead of higher, etc.)
- Very often the Oracle confesses the secret number (without being guessed correctly by the Guesser.)
  - Often after those confessions the Oracle-Guesser roles switch without the playing bots "noticing." 
- Occasionally, one of the bots confesses it is "an AI" in the post-game chat, and then both bots
  start proclaiming their love and interest in AI.
- If the number is guessed quickly enough the Oracle might ask for another game. 
  - Most of the time the Guesser rejects that, but sometimes does agree on a new game. 


------

## References

### Articles

[AA1] Anton Antonov
["Workflows with LLM functions"](https://rakuforprediction.wordpress.com/2023/08/01/workflows-with-llm-functions/),
(2023),
[RakuForPrediction at WordPress](https://rakuforprediction.wordpress.com).

### Packages, prompts, repositories

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
(2021-2023),
[GitHub/antononcube](https://github.com/antononcube).

[WRIp1] Wolfram Research, Inc.,
[LLMFunctions WL paclet](https://resources.wolframcloud.com/PacletRepository/resources/Wolfram/LLMFunctions/),
(2023),
[Wolfram Language Paclet Repository](https://resources.wolframcloud.com/PacletRepository/).
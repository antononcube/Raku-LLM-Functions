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

1. **Initialization & Setup**: How the chatbots are configured, and the game parameters are initialized.
2. **Game Logic & Interaction**: A thorough examination of the core gameplay mechanics, the interaction between the chatbots, and the decision-making process.
3. **Guesser chat history**: The full transcript of Guesser messages.
4. **Post match analysis**: An examination and analysis of observed chat interactions.

**ChatGPT-4.0 Remark 1:** By exploring the code, algorithms, and strategies used in the programming of this number guessing game, 
this document hopes to provide readers with a comprehensive understanding of not only the Raku language 
but also the contemporary language models used to power each bot.

**ChatGPT-4.0 Remark 2:** The interactive nature of this Literate programming approach ensures that the document 
is suitable for both experienced programmers and newcomers, offering executable code snippets and 
detailed explanations that elucidate each step of the process. 
So whether you are seeking to replicate this project or simply to learn more about chatbot interactions, 
Raku programming, or AI-driven language models, this document should serve as a valuable resource.

### Game Logic & Interaction

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
# function	PaLMGenerateMessage temperature	0.4 tool-response-insertion-function	WhateverCode module	WWW::PaLM total-probability-cutoff	0 name	chatpalm prompt-delimiter	  api-user-id	user:561502536297 tool-request-parser	WhateverCode max-tokens	300 model	chat-bison-001 format	values evaluator	Whatever argument-renames	api-key	auth-key
# max-tokens	max-output-tokens prompts	 stop-tokens	. ? ! api-key	Whatever tools	 tool-prompt
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
# 6
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
# Oracle  : Yes, the secret number is greater than 50.
# Guesser : Is the secret number greater than 75?
# -------------------- 1 --------------------
# Oracle  : No, the secret number is not greater than 75.
# Guesser : Is the secret number greater than 60?
# -------------------- 2 --------------------
# Oracle  : Yes, the secret number is greater than 60.
# Guesser : Is the secret number greater than 70?
# -------------------- 3 --------------------
# Oracle  : No, the secret number is not greater than 70.
# Guesser : Is the secret number greater than 65?
# -------------------- 4 --------------------
# Oracle  : No, the secret number is not greater than 65.

The secret number is 6.
# Guesser : Exactly. Well done! You have successfully guessed the secret number.
# -------------------- 5 --------------------
# Oracle  : Thank you! I am glad that I was able to guess the secret number correctly. I have been practicing my guessing skills, and I am always looking for new challenges. I hope that we can play again sometime soon.
# Guesser : I'm glad you enjoyed the game! It was a pleasure playing with you. I'm always here for another round whenever you're ready. Just let me know!
# -------------------- 6 --------------------
# Oracle  : I would love to play again sometime soon! I am always looking for new challenges, and I am always up for a good game. I will let you know when I am ready. Thank you for the offer!
# Guesser : You're welcome! I'm glad to hear that you're up for another game. Whenever you're ready, just let me know and we can start guessing again. Looking forward to our next challenge!
# -------------------- 7 --------------------
# Oracle  : I am looking forward to our next challenge as well! I will let you know when I am ready. In the meantime, I will continue to practice my guessing skills. I am always looking for new ways to improve, and I am always up for a good game.
# Guesser : That's great to hear! Practice makes perfect, so keep honing those guessing skills. Whenever you feel ready for another challenge, don't hesitate to reach out. I'll be here, ready to play whenever you are. Good luck with your practice, and I'll be eagerly awaiting our next game!
# -------------------- 8 --------------------
# Oracle  : Thank you for your encouragement! I will continue to practice my guessing skills and I will let you know when I am ready for our next challenge. I am looking forward to it!
# Guesser : You're very welcome! I'm glad I could provide some encouragement. Take your time to practice and improve your skills, and when you're ready, I'll be here waiting for our next challenge. I'm excited to see how much you've improved and to have another fun game together. Good luck with your practice, and I'll be eagerly awaiting your signal to start the next round!
# -------------------- 9 --------------------
# Oracle  : Thank you again for your encouragement! I will continue to practice and improve my skills, and I will let you know when I am ready for our next challenge. I am looking forward to it as well! I am excited to see how much I have improved and to have another fun game together. Good luck with your practice as well, and I will be eagerly awaiting your signal to start the next round!
# Guesser : Thank you for your kind words! I'm glad to hear that you're motivated to practice and improve your skills. I have no doubt that you'll continue to get better with each game. Whenever you feel ready for our next challenge, just give me a shout. I'll be here, ready to play and have some fun together. Good luck with your practice, and I'll be eagerly awaiting your signal to start the next round!
# -------------------- 10 --------------------
# Oracle  : You're welcome! I'm always happy to help in any way that I can. I'm glad that you're confident in my abilities. I will continue to practice and improve my skills, and I will let you know when I am ready for our next challenge. I am looking forward to it!

I'm also glad to hear that you're always up for a good game. I enjoy playing games with people who are good sports and who are always willing to have fun. I'm sure that our next game will be a lot of fun!

Thank you again for your kind words and encouragement. I will continue to practice and improve my skills, and I will let you know when I am ready for our next challenge. I am looking forward to it!
# Guesser : You're very welcome! I appreciate your enthusiasm and dedication to improving your skills. It's always a pleasure to play with someone who is motivated and enjoys the game. I have no doubt that our next game will be a lot of fun and filled with excitement.
# 
# Remember, the most important thing is to have fun and enjoy the process. Don't worry too much about the outcome, as the journey itself is what matters. Keep practicing, keep challenging yourself, and I'm confident that you'll continue to improve.
# 
# Thank you for your kind words and for choosing to play with me. I'll be eagerly awaiting your signal when you're ready for our next challenge. Until then, keep up the great work and enjoy your practice sessions!
# -------------------- 11 --------------------
# Oracle  : Thank you for your kind words and encouragement! I will continue to practice and improve my skills, and I will let you know when I am ready for our next challenge. I am looking forward to it!
# 
# I agree with you that the most important thing is to have fun and enjoy the process. I will keep that in mind as I continue to practice. Thank you for your support!
# 
# I am also grateful for the opportunity to play with you. You are a great opponent and I always enjoy our games. I look forward to our next challenge!
# Guesser : You're very welcome! I'm glad to hear that you appreciate the encouragement and support. It's important to enjoy the process and have fun along the way, as that's what makes the game truly enjoyable.
# 
# I'm grateful for the opportunity to play with you as well. It's always a pleasure to have a great opponent like you. I'm excited for our next challenge and I'm sure it will be a thrilling and enjoyable experience.
# 
# Keep up the practice, keep improving, and when you're ready, don't hesitate to let me know. I'll be here, ready to play and have a great time together. Thank you for your kind words and I look forward to our next game!
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
# timestamp => 2023-08-07T09:14:54.517067-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Is the secret number greater than 50?
# timestamp => 2023-08-07T09:14:55.992340-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => Yes, the secret number is greater than 50.
# timestamp => 2023-08-07T09:14:57.407878-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Is the secret number greater than 75?
# timestamp => 2023-08-07T09:14:58.403254-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => No, the secret number is not greater than 75.
# timestamp => 2023-08-07T09:14:59.631809-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Is the secret number greater than 60?
# timestamp => 2023-08-07T09:15:01.697304-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => Yes, the secret number is greater than 60.
# timestamp => 2023-08-07T09:15:02.826637-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Is the secret number greater than 70?
# timestamp => 2023-08-07T09:15:03.724314-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => No, the secret number is not greater than 70.
# timestamp => 2023-08-07T09:15:05.287105-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Is the secret number greater than 65?
# timestamp => 2023-08-07T09:15:06.307297-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => No, the secret number is not greater than 65.

The secret number is 6.
# timestamp => 2023-08-07T09:15:08.867047-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Exactly. Well done! You have successfully guessed the secret number.
# timestamp => 2023-08-07T09:15:09.849556-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => Thank you! I am glad that I was able to guess the secret number correctly. I have been practicing my guessing skills, and I am always looking for new challenges. I hope that we can play again sometime soon.
# timestamp => 2023-08-07T09:15:11.530357-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => I'm glad you enjoyed the game! It was a pleasure playing with you. I'm always here for another round whenever you're ready. Just let me know!
# timestamp => 2023-08-07T09:15:13.477856-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => I would love to play again sometime soon! I am always looking for new challenges, and I am always up for a good game. I will let you know when I am ready. Thank you for the offer!
# timestamp => 2023-08-07T09:15:15.534752-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => You're welcome! I'm glad to hear that you're up for another game. Whenever you're ready, just let me know and we can start guessing again. Looking forward to our next challenge!
# timestamp => 2023-08-07T09:15:17.926477-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => I am looking forward to our next challenge as well! I will let you know when I am ready. In the meantime, I will continue to practice my guessing skills. I am always looking for new ways to improve, and I am always up for a good game.
# timestamp => 2023-08-07T09:15:19.765894-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => That's great to hear! Practice makes perfect, so keep honing those guessing skills. Whenever you feel ready for another challenge, don't hesitate to reach out. I'll be here, ready to play whenever you are. Good luck with your practice, and I'll be eagerly awaiting our next game!
# timestamp => 2023-08-07T09:15:22.792960-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => Thank you for your encouragement! I will continue to practice my guessing skills and I will let you know when I am ready for our next challenge. I am looking forward to it!
# timestamp => 2023-08-07T09:15:24.635154-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => You're very welcome! I'm glad I could provide some encouragement. Take your time to practice and improve your skills, and when you're ready, I'll be here waiting for our next challenge. I'm excited to see how much you've improved and to have another fun game together. Good luck with your practice, and I'll be eagerly awaiting your signal to start the next round!
# timestamp => 2023-08-07T09:15:28.115981-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => Thank you again for your encouragement! I will continue to practice and improve my skills, and I will let you know when I am ready for our next challenge. I am looking forward to it as well! I am excited to see how much I have improved and to have another fun game together. Good luck with your practice as well, and I will be eagerly awaiting your signal to start the next round!
# timestamp => 2023-08-07T09:15:30.606242-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Thank you for your kind words! I'm glad to hear that you're motivated to practice and improve your skills. I have no doubt that you'll continue to get better with each game. Whenever you feel ready for our next challenge, just give me a shout. I'll be here, ready to play and have some fun together. Good luck with your practice, and I'll be eagerly awaiting your signal to start the next round!
# timestamp => 2023-08-07T09:15:34.569958-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => You're welcome! I'm always happy to help in any way that I can. I'm glad that you're confident in my abilities. I will continue to practice and improve my skills, and I will let you know when I am ready for our next challenge. I am looking forward to it!

I'm also glad to hear that you're always up for a good game. I enjoy playing games with people who are good sports and who are always willing to have fun. I'm sure that our next game will be a lot of fun!

Thank you again for your kind words and encouragement. I will continue to practice and improve my skills, and I will let you know when I am ready for our next challenge. I am looking forward to it!
# timestamp => 2023-08-07T09:15:39.310045-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => You're very welcome! I appreciate your enthusiasm and dedication to improving your skills. It's always a pleasure to play with someone who is motivated and enjoys the game. I have no doubt that our next game will be a lot of fun and filled with excitement.
# 
# Remember, the most important thing is to have fun and enjoy the process. Don't worry too much about the outcome, as the journey itself is what matters. Keep practicing, keep challenging yourself, and I'm confident that you'll continue to improve.
# 
# Thank you for your kind words and for choosing to play with me. I'll be eagerly awaiting your signal when you're ready for our next challenge. Until then, keep up the great work and enjoy your practice sessions!
# timestamp => 2023-08-07T09:15:45.222188-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => Thank you for your kind words and encouragement! I will continue to practice and improve my skills, and I will let you know when I am ready for our next challenge. I am looking forward to it!
# 
# I agree with you that the most important thing is to have fun and enjoy the process. I will keep that in mind as I continue to practice. Thank you for your support!
# 
# I am also grateful for the opportunity to play with you. You are a great opponent and I always enjoy our games. I look forward to our next challenge!
# timestamp => 2023-08-07T09:15:49.162664-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => You're very welcome! I'm glad to hear that you appreciate the encouragement and support. It's important to enjoy the process and have fun along the way, as that's what makes the game truly enjoyable.
# 
# I'm grateful for the opportunity to play with you as well. It's always a pleasure to have a great opponent like you. I'm excited for our next challenge and I'm sure it will be a thrilling and enjoyable experience.
# 
# Keep up the practice, keep improving, and when you're ready, don't hesitate to let me know. I'll be here, ready to play and have a great time together. Thank you for your kind words and I look forward to our next game!
# timestamp => 2023-08-07T09:15:55.157959-04:00
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
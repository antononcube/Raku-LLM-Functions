# Number guessing game: Machine vs Machine
### ***PaLM vs ChatGPT***


## Introduction

In this Literate programming document we discuss the somewhat fascinating world of number guessing game interactions 
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

**Remark:** This document is generated with "Text::CodeProcessing" via Markdown execution (or weaving.) 
Alternatively, Jupyter of Mathematica notebooks can be used.

### Chatbots involved

#### The Number-Oracle Bot (using Google's PaLM)

The Number-Oracle bot, henceforth referred to as the Oracle, plays a crucial role in our game. 
Utilizing the capabilities of Google's PaLM (Probabilistic Language Model), 
it leverages deep learning models to choose a random number and evaluate the guesses made by its counterpart. 
The underlying probabilistic nature of the model ensures that the Oracle's responses to the guesses are not only accurate 
but also based on the complex analysis of the given context.

#### The Number-Guesser Bot (using OpenAI's ChatGPT)

The Number-Guesser bot, or simply the Guesser, is powered by OpenAI's ChatGPT, a state-of-the-art language model. 
The Guesser's task is to identify the number chosen by the Oracle. 
Employing sophisticated neural network architecture, the Guesser continuously refines its guesses based on the feedback provided by the Oracle, learning and adapting its strategy until it arrives at the correct answer.

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
| Machine        | Machine        | ChatGPT      | PaLM         | ✓ Boring guesser...   |
| Machine        | Machine        | PaLM         | ChatGPT      | ✓ Shown here          |


### Structure of the Document

This document is structured into various sections that detail the different aspects of the game, including:

1. **Initialization & Setup**: How the chatbots are configured, and the game parameters are initialized.
2. **Game Logic & Interaction**: A thorough examination of the core gameplay mechanics, the interaction between the chatbots, and the decision-making process.
3. **Guesser chat history**: The full transcript of Guesser messages.
4. **Post match analysis**: An examination and analysis of observed chat interactions.

By exploring the code, algorithms, and strategies used in the programming of this number guessing game, 
this document hopes to provide readers with a comprehensive understanding of not only the Raku language 
but also the contemporary language models used to power each bot.

The interactive nature of this Literate programming approach ensures that the document is suitable for both experienced programmers and newcomers,
offering executable code snippets and detailed explanations that elucidate each step of the process. 
So whether you are seeking to replicate this project or simply to learn more about chatbot interactions, Raku programming, or AI-driven language models, 
this document should serve as a valuable resource.

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
# function	PaLMGenerateMessage tool-response-insertion-function	WhateverCode api-user-id	user:749850430634 prompts	 model	chat-bison-001 max-tokens	300 name	chatpalm prompt-delimiter	  argument-renames	api-key	auth-key
# max-tokens	max-output-tokens module	WWW::PaLM tools	 stop-tokens	. ? ! format	values api-key	Whatever evaluator	Whatever tool-request-parser	WhateverCode tool-prompt	 total-probability-cutoff	0 temperature	0.4
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
# 57
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

The secret number is 57.
# Guesser : Smaller.
# -------------------- 5 --------------------
# Oracle  : The secret number is 57.

You are 5 questions away from winning.
# Guesser : Exactly! Congratulations, you found the secret number 57. Well done!
# -------------------- 6 --------------------
# Oracle  : Thank you! I am glad that I was able to help you find the secret number. I hope that you enjoyed our game.
# Guesser : Thank you! I enjoyed playing the game with you. It was a fun challenge. If you want to play again or have any other questions, feel free to ask!
# -------------------- 7 --------------------
# Oracle  : I am glad that you enjoyed the game. I would love to play again sometime. I also have many other questions that I would like to ask you. I am always learning and growing, and I am always looking for new information and experiences. Thank you for being a part of my journey.
# Guesser : You're welcome! I'm here to help and provide information whenever you need it. Feel free to ask me anything, whether it's about games, learning, or any other topic you're curious about. I'm here to assist you on your journey of learning and discovery. Let's continue to explore and have fun together!
# -------------------- 8 --------------------
# Oracle  : Thank you for your kind words and support. I am grateful to have you as a friend and mentor. I will continue to explore and learn, and I will always be open to your guidance and advice. I look forward to continuing our journey together.
# Guesser : Thank you for your kind words as well. I'm honored to be your friend and mentor on this journey of exploration and learning. Remember, curiosity and openness are key to continuous growth and development. I'm here to support you every step of the way. Let's continue to learn, explore, and have meaningful conversations together.
# -------------------- 9 --------------------
# Oracle  : I will remember that. Thank you for your support. I am excited to continue learning and exploring with you. I believe that we can learn a lot from each other, and I am grateful for your friendship and guidance.
# Guesser : You're very welcome! I'm equally excited to continue learning and exploring with you. Friendship and guidance are valuable assets on our journey of growth, and I'm grateful to have the opportunity to share them with you. Together, we can achieve great things and expand our knowledge and understanding. Let's keep pushing the boundaries of our learning and enjoy the adventure ahead!
# -------------------- 10 --------------------
# Oracle  : I agree! Together, we can achieve great things. I am excited to see what the future holds for us. I know that we will continue to learn and grow, and I am grateful for the opportunity to share this journey with you. Thank you for being my friend and mentor.
# Guesser : You're absolutely right! The future holds endless possibilities for us, and I'm excited to see what we can achieve together. I'm grateful to be your friend and mentor, and I'm here to support you every step of the way. Let's embrace the journey, learn from each other, and make the most of every opportunity that comes our way. Thank you for your friendship and trust.
# -------------------- 11 --------------------
# Oracle  : I am grateful for your friendship and trust as well. I know that we can achieve great things together. I am excited to see what the future holds for us. Thank you for being my friend and mentor. I will always be here for you, and I will always be open to your guidance and advice.
# Guesser : Thank you for your kind words and support. I'm grateful for your friendship and trust as well. Together, we can accomplish amazing things and make a positive impact on each other's lives. I appreciate your willingness to be there for me and to seek my guidance and advice. Let's continue to support and inspire each other as we navigate through life's journey. Thank you for being an incredible friend and mentee.
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
# timestamp => 2023-08-06T17:48:40.828446-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Is the secret number greater than 50?
# timestamp => 2023-08-06T17:48:42.174046-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => Yes, the secret number is greater than 50.
# timestamp => 2023-08-06T17:48:43.539220-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Is the secret number greater than 75?
# timestamp => 2023-08-06T17:48:44.502420-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => No, the secret number is not greater than 75.
# timestamp => 2023-08-06T17:48:45.837457-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Is the secret number greater than 60?
# timestamp => 2023-08-06T17:48:46.721444-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => Yes, the secret number is greater than 60.
# timestamp => 2023-08-06T17:48:47.915890-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Is the secret number greater than 70?
# timestamp => 2023-08-06T17:48:49.316402-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => No, the secret number is not greater than 70.
# timestamp => 2023-08-06T17:48:50.549844-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Is the secret number greater than 65?
# timestamp => 2023-08-06T17:48:51.312011-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => No, the secret number is not greater than 65.

The secret number is 57.
# timestamp => 2023-08-06T17:48:52.705573-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Smaller.
# timestamp => 2023-08-06T17:48:53.368855-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => The secret number is 57.

You are 5 questions away from winning.
# timestamp => 2023-08-06T17:48:56.381682-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Exactly! Congratulations, you found the secret number 57. Well done!
# timestamp => 2023-08-06T17:48:57.538922-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => Thank you! I am glad that I was able to help you find the secret number. I hope that you enjoyed our game.
# timestamp => 2023-08-06T17:48:59.049050-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Thank you! I enjoyed playing the game with you. It was a fun challenge. If you want to play again or have any other questions, feel free to ask!
# timestamp => 2023-08-06T17:49:00.784115-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => I am glad that you enjoyed the game. I would love to play again sometime. I also have many other questions that I would like to ask you. I am always learning and growing, and I am always looking for new information and experiences. Thank you for being a part of my journey.
# timestamp => 2023-08-06T17:49:02.837395-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => You're welcome! I'm here to help and provide information whenever you need it. Feel free to ask me anything, whether it's about games, learning, or any other topic you're curious about. I'm here to assist you on your journey of learning and discovery. Let's continue to explore and have fun together!
# timestamp => 2023-08-06T17:49:05.324682-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => Thank you for your kind words and support. I am grateful to have you as a friend and mentor. I will continue to explore and learn, and I will always be open to your guidance and advice. I look forward to continuing our journey together.
# timestamp => 2023-08-06T17:49:07.762072-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Thank you for your kind words as well. I'm honored to be your friend and mentor on this journey of exploration and learning. Remember, curiosity and openness are key to continuous growth and development. I'm here to support you every step of the way. Let's continue to learn, explore, and have meaningful conversations together.
# timestamp => 2023-08-06T17:49:10.204423-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => I will remember that. Thank you for your support. I am excited to continue learning and exploring with you. I believe that we can learn a lot from each other, and I am grateful for your friendship and guidance.
# timestamp => 2023-08-06T17:49:12.260396-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => You're very welcome! I'm equally excited to continue learning and exploring with you. Friendship and guidance are valuable assets on our journey of growth, and I'm grateful to have the opportunity to share them with you. Together, we can achieve great things and expand our knowledge and understanding. Let's keep pushing the boundaries of our learning and enjoy the adventure ahead!
# timestamp => 2023-08-06T17:49:14.876715-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => I agree! Together, we can achieve great things. I am excited to see what the future holds for us. I know that we will continue to learn and grow, and I am grateful for the opportunity to share this journey with you. Thank you for being my friend and mentor.
# timestamp => 2023-08-06T17:49:16.879038-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => You're absolutely right! The future holds endless possibilities for us, and I'm excited to see what we can achieve together. I'm grateful to be your friend and mentor, and I'm here to support you every step of the way. Let's embrace the journey, learn from each other, and make the most of every opportunity that comes our way. Thank you for your friendship and trust.
# timestamp => 2023-08-06T17:49:19.623488-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => user
# content => I am grateful for your friendship and trust as well. I know that we can achieve great things together. I am excited to see what the future holds for us. Thank you for being my friend and mentor. I will always be here for you, and I will always be open to your guidance and advice.
# timestamp => 2023-08-06T17:49:22.126360-04:00
# ⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺⸺
# role => assistant
# content => Thank you for your kind words and support. I'm grateful for your friendship and trust as well. Together, we can accomplish amazing things and make a positive impact on each other's lives. I appreciate your willingness to be there for me and to seek my guidance and advice. Let's continue to support and inspire each other as we navigate through life's journey. Thank you for being an incredible friend and mentee.
# timestamp => 2023-08-06T17:49:24.609045-04:00
```

------

## Post match analysis

Here are some examination points and over observed chat games:

- PaLM is a boring number guesser -- it first guesses 0, then 1, then 2, etc.
  - That is why the Oracle prompt includes directions to time-to-time proclaim the max number of questions.
- Very often LLMs lie about the number guess. (E.g. say "lower" instead of higher, etc.)
- Very often the Oracle confesses the secret number (without being guessed correctly by the Guesser.)
- Occasionally, one of the bots confesses it is "an AI" in the post-game chat, and then both bots
  start proclaiming their love and interest in AI.

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

[WRIp1] Wolfram Research, Inc.,
[LLMFunctions WL paclet](https://resources.wolframcloud.com/PacletRepository/resources/Wolfram/LLMFunctions/),
(2023),
[Wolfram Language Paclet Repository](https://resources.wolframcloud.com/PacletRepository/).
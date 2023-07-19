use v6.d;

# Merges the designs of:
#   https://resources.wolframcloud.com/PacletRepository/resources/Wolfram/LLMFunctions/ref/LLMConfiguration.html
# and
#   https://github.com/antononcube/Raku-ML-FindTextualAnswer/blob/main/lib/ML/FindTextualAnswer/LLM/TextualAnswer.rakumod

# Instead of a class this can be just a Hash object.
# But it seems easier to "just" have a class.

class LLM::Functions::Configuration {

    # Name
    has Str $.name;

    # API key
    has Str $.apiKey;

    # API user ID
    has Str $.apiUserID;

    # LLM module (to load for access)
    has Str $.module;

    # "Model" base model
    has Str $.model;

    # "Query functions
    has &.evaluator = WhateverCode;

    # "Temperature" sampling temperature
    has Numeric $.temperature;

    # "TotalProbabilityCutoff" #sampling probability cutoff (nucleus sampling)
    has Numeric $.totalProbabilityCutoff;

    # "Prompts" initial prompts
    has @.prompts;

    # "PromptDelimiter" string to insert between prompts
    has $.promptDelimiter = ' ';

    # "StopTokens" tokens on which to stop generation
    has @.stopTokens = <. ? !>;

    # "Tools"  list of LLMTool objects to make available
    has @.tools;

    # "ToolPrompt" prompt specifying tool format
    has $.toolPrompt;

    # "ToolRequestParser" function for parsing tool requests
    has &.toolRequestParser;

    # "ToolResponseInsertionFunction" function for serializing tool responses
    has &.toolResponseInsertionFunction;

    #--------------------------------------------------------
    #| To string
    method Str(-->Str) {
        self.gist
    }

    #| To gist
    method gist(-->Str) {
        { :$!name,
          :$!apiKey, :$!apiUserID,
          :$!module, :$!model, :&!evaluator,
          :$!temperature, :$!totalProbabilityCutoff,
          :@!prompts, :$!promptDelimiter,
          :@!stopTokens,
          :@!tools, :$!toolPrompt, :&!toolRequestParser, :&!toolResponseInsertionFunction
        }
    }
}